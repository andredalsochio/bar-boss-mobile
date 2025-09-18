import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Inicializar Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Configurações regionais para melhor performance
const runtimeOpts: functions.RuntimeOptions = {
  timeoutSeconds: 60,
  memory: '256MB',
};

/**
 * Cloud Function callable para verificar disponibilidade de CNPJ
 * Permite validação sem depender de permissões do cliente no Firestore
 */
export const checkAvailability = functions
  .region('us-central1')
  .runWith(runtimeOpts)
  .https.onCall(async (data: any, context: any) => {
  // Validar autenticação (obrigatória)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Usuário deve estar autenticado para verificar disponibilidade'
    );
  }

  const { cnpj } = data;

  // Validar parâmetros
  if (!cnpj || typeof cnpj !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'CNPJ é obrigatório e deve ser uma string'
    );
  }

  // Normalizar CNPJ (apenas dígitos)
  const cnpjClean = cnpj.replace(/[^\d]/g, '');

  // Validar formato do CNPJ
  if (cnpjClean.length !== 14) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'CNPJ deve conter exatamente 14 dígitos'
    );
  }

  try {
    // Verificar se CNPJ existe no registro usando Admin SDK
    const cnpjRegistryDoc = await admin.firestore()
      .collection('cnpj_registry')
      .doc(cnpjClean)
      .get();

    const exists = cnpjRegistryDoc.exists;

    functions.logger.info('CNPJ availability check', {
      cnpj: cnpjClean.substring(0, 4) + '***', // Log parcial por segurança
      exists,
      uid: context.auth.uid
    });

    return {
      cnpjExists: exists
    };

  } catch (error) {
    functions.logger.error('Error checking CNPJ availability', {
      cnpj: cnpjClean.substring(0, 4) + '***',
      error: error instanceof Error ? error.message : String(error),
      uid: context.auth.uid
    });

    throw new functions.https.HttpsError(
      'internal',
      'Erro interno ao verificar disponibilidade do CNPJ'
    );
  }
});

/**
 * Cloud Function callable para validação híbrida de email e CNPJ
 * Estratégia híbrida: cliente + servidor para máxima segurança
 */
export const validateRegistrationData = functions
  .region('us-central1')
  .runWith(runtimeOpts)
  .https.onCall(async (data: any, context: any) => {
  // Validar autenticação (obrigatória)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Usuário deve estar autenticado para validar dados'
    );
  }

  const { email, cnpj, flowType } = data;

  // Validar parâmetros obrigatórios
  if (!flowType || !['CLASSIC', 'SOCIAL'].includes(flowType)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'flowType deve ser CLASSIC ou SOCIAL'
    );
  }

  if (!cnpj || typeof cnpj !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'CNPJ é obrigatório e deve ser uma string'
    );
  }

  // Para fluxo clássico, email é obrigatório
  if (flowType === 'CLASSIC' && (!email || typeof email !== 'string')) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email é obrigatório para fluxo clássico'
    );
  }

  // Normalizar dados
  const cnpjClean = cnpj.replace(/[^\d]/g, '');
  const emailNormalized = email ? email.trim().toLowerCase() : null;

  // Validar formato do CNPJ
  if (cnpjClean.length !== 14) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'CNPJ deve conter exatamente 14 dígitos'
    );
  }

  try {
    const auth = admin.auth();
    
    let emailExists = false;
    let cnpjExists = false;

    // Validar email (apenas para fluxo clássico)
    if (flowType === 'CLASSIC' && emailNormalized) {
      try {
        // Usar Firebase Admin Auth para verificar se email existe
        await auth.getUserByEmail(emailNormalized);
        emailExists = true;
        functions.logger.info('Email exists in Firebase Auth', {
          email: emailNormalized.substring(0, 3) + '***',
          uid: context.auth.uid
        });
      } catch (error: any) {
        if (error.code === 'auth/user-not-found') {
          emailExists = false;
          functions.logger.info('Email not found in Firebase Auth', {
            email: emailNormalized.substring(0, 3) + '***',
            uid: context.auth.uid
          });
        } else {
          // Erro inesperado, logar e continuar
          functions.logger.warn('Error checking email in Firebase Auth', {
            email: emailNormalized.substring(0, 3) + '***',
            error: error.message,
            uid: context.auth.uid
          });
          emailExists = false; // Fail-safe: assumir que não existe
        }
      }
    }

    // Validar CNPJ usando Admin SDK (bypass das Firestore Rules)
    try {
      functions.logger.info('Checking CNPJ in registry', {
        cnpj: cnpjClean.substring(0, 4) + '***',
        uid: context.auth.uid,
        flowType
      });

      const cnpjRegistryDoc = await admin.firestore()
        .collection('cnpj_registry')
        .doc(cnpjClean)
        .get();

      cnpjExists = cnpjRegistryDoc.exists;

      functions.logger.info('CNPJ check completed', {
        cnpj: cnpjClean.substring(0, 4) + '***',
        exists: cnpjExists,
        uid: context.auth.uid,
        flowType
      });
    } catch (cnpjError: any) {
      functions.logger.error('Error checking CNPJ', {
        cnpj: cnpjClean.substring(0, 4) + '***',
        error: cnpjError.message,
        code: cnpjError.code,
        uid: context.auth.uid,
        flowType
      });
      // Em caso de erro, assumir que CNPJ não existe (fail-safe)
      cnpjExists = false;
    }

    // Log da operação
    functions.logger.info('Hybrid validation completed', {
      flowType,
      email: emailNormalized ? emailNormalized.substring(0, 3) + '***' : 'N/A',
      cnpj: cnpjClean.substring(0, 4) + '***',
      emailExists,
      cnpjExists,
      uid: context.auth.uid
    });

    return {
      emailExists,
      cnpjExists,
      flowType
    };

  } catch (error) {
    functions.logger.error('Error in hybrid validation', {
      flowType,
      email: emailNormalized ? emailNormalized.substring(0, 3) + '***' : 'N/A',
      cnpj: cnpjClean.substring(0, 4) + '***',
      error: error instanceof Error ? error.message : String(error),
      uid: context.auth.uid
    });

    throw new functions.https.HttpsError(
      'internal',
      'Erro interno na validação híbrida'
    );
  }
});

/**
 * Cloud Function callable para validação segura de email
 * Alternativa ao fetchSignInMethodsForEmail que foi depreciado
 */
export const checkEmailAvailability = functions
  .region('us-central1')
  .runWith(runtimeOpts)
  .https.onCall(async (data: any, context: any) => {
  // Validar autenticação (obrigatória)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Usuário deve estar autenticado para verificar email'
    );
  }

  const { email } = data;

  // Validar parâmetros
  if (!email || typeof email !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email é obrigatório e deve ser uma string'
    );
  }

  // Normalizar email
  const emailNormalized = email.trim().toLowerCase();

  // Validar formato básico do email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(emailNormalized)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Formato de email inválido'
    );
  }

  try {
    const auth = admin.auth();
    
    // Usar Firebase Admin Auth para verificar se email existe
    try {
      await auth.getUserByEmail(emailNormalized);
      
      functions.logger.info('Email availability check - exists', {
        email: emailNormalized.substring(0, 3) + '***',
        uid: context.auth.uid
      });

      return {
        emailExists: true
      };
    } catch (error: any) {
      if (error.code === 'auth/user-not-found') {
        functions.logger.info('Email availability check - not found', {
          email: emailNormalized.substring(0, 3) + '***',
          uid: context.auth.uid
        });

        return {
          emailExists: false
        };
      } else {
        // Erro inesperado
        throw error;
      }
    }

  } catch (error) {
    functions.logger.error('Error checking email availability', {
      email: emailNormalized.substring(0, 3) + '***',
      error: error instanceof Error ? error.message : String(error),
      uid: context.auth.uid
    });

    throw new functions.https.HttpsError(
      'internal',
      'Erro interno ao verificar disponibilidade do email'
    );
  }
});