import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { setGlobalOptions } from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

// Inicializar Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Configuração global para 2nd gen
setGlobalOptions({
  region: 'us-central1',
  maxInstances: 10,
});

// Função checkAvailability removida - redundante com validateRegistrationData

/**
 * Cloud Function callable para validação híbrida de email e CNPJ
 * Estratégia híbrida: cliente + servidor para máxima segurança
 */
export const validateRegistrationData = onCall(async (request) => {
  const { data, auth } = request;
  const { email, cnpj, flowType } = data;
  
  // Validar autenticação apenas para fluxo SOCIAL
  // Fluxo CLASSIC pode ser chamado sem autenticação (usuário ainda não existe)
  if (flowType === 'SOCIAL' && !auth) {
    throw new HttpsError(
      'unauthenticated',
      'Usuário deve estar autenticado para fluxo social'
    );
  }

  // Validar parâmetros obrigatórios
  if (!flowType || !['CLASSIC', 'SOCIAL'].includes(flowType)) {
    throw new HttpsError(
      'invalid-argument',
      'flowType deve ser CLASSIC ou SOCIAL'
    );
  }

  if (!cnpj || typeof cnpj !== 'string') {
    throw new HttpsError(
      'invalid-argument',
      'CNPJ é obrigatório e deve ser uma string'
    );
  }

  // Para fluxo clássico, email é obrigatório
  if (flowType === 'CLASSIC' && (!email || typeof email !== 'string')) {
    throw new HttpsError(
      'invalid-argument',
      'Email é obrigatório para fluxo clássico'
    );
  }

  // Normalizar dados
  const cnpjClean = cnpj.replace(/[^\d]/g, '');
  const emailNormalized = email ? email.trim().toLowerCase() : null;

  // Validar formato do CNPJ
  if (cnpjClean.length !== 14) {
    throw new HttpsError(
      'invalid-argument',
      'CNPJ deve conter exatamente 14 dígitos'
    );
  }

  try {
      const adminAuth = admin.auth();
      const uid = auth?.uid || 'unauthenticated';
    
    let emailExists = false;
    let cnpjExists = false;

    // Validar email (apenas para fluxo clássico)
    if (flowType === 'CLASSIC' && emailNormalized) {
      try {
        // Usar Firebase Admin Auth para verificar se email existe
        await adminAuth.getUserByEmail(emailNormalized);
        emailExists = true;
        console.log('Email exists in Firebase Auth', {
          email: emailNormalized.substring(0, 3) + '***',
          uid: uid
        });
      } catch (error: any) {
        if (error.code === 'auth/user-not-found') {
          emailExists = false;
          console.log('Email not found in Firebase Auth', {
            email: emailNormalized.substring(0, 3) + '***',
            uid: uid
          });
        } else {
          // Erro inesperado, logar e continuar
          console.warn('Error checking email in Firebase Auth', {
            email: emailNormalized.substring(0, 3) + '***',
            error: error.message,
            uid: uid
          });
          emailExists = false; // Fail-safe: assumir que não existe
        }
      }
    }

    // Validar CNPJ usando Admin SDK (bypass das Firestore Rules)
    try {
      console.log('Checking CNPJ in registry', {
        cnpj: cnpjClean.substring(0, 4) + '***',
        uid: uid,
        flowType
      });

      const cnpjRegistryDoc = await admin.firestore()
        .collection('cnpj_registry')
        .doc(cnpjClean)
        .get();

      cnpjExists = cnpjRegistryDoc.exists;

      console.log('CNPJ check completed', {
        cnpj: cnpjClean.substring(0, 4) + '***',
        exists: cnpjExists,
        uid: uid,
        flowType
      });
    } catch (cnpjError: any) {
      console.error('Error checking CNPJ', {
        cnpj: cnpjClean.substring(0, 4) + '***',
        error: cnpjError.message,
        code: cnpjError.code,
        uid: uid,
        flowType
      });
      // Em caso de erro, assumir que CNPJ não existe (fail-safe)
      cnpjExists = false;
    }

    // Log da operação
    console.log('Hybrid validation completed', {
      flowType,
      email: emailNormalized ? emailNormalized.substring(0, 3) + '***' : 'N/A',
      cnpj: cnpjClean.substring(0, 4) + '***',
      emailExists,
      cnpjExists,
      uid: uid
    });

    return {
      emailExists,
      cnpjExists,
      flowType
    };

  } catch (error) {
    const uid = auth?.uid || 'unauthenticated';
    console.error('Error in hybrid validation', {
      flowType,
      email: emailNormalized ? emailNormalized.substring(0, 3) + '***' : 'N/A',
      cnpj: cnpjClean.substring(0, 4) + '***',
      error: error instanceof Error ? error.message : String(error),
      uid: uid
    });

    throw new HttpsError(
      'internal',
      'Erro interno na validação híbrida'
    );
  }
});

/**
 * Cloud Function callable para validação segura de email
 * Alternativa ao fetchSignInMethodsForEmail que foi depreciado
 */
export const checkEmailAvailability = onCall(async (request) => {
  const { data, auth } = request;
  // Validar autenticação (obrigatória)
  if (!auth) {
    throw new HttpsError(
      'unauthenticated',
      'Usuário deve estar autenticado para verificar email'
    );
  }

  const { email } = data;

  // Validar parâmetros
  if (!email || typeof email !== 'string') {
    throw new HttpsError(
      'invalid-argument',
      'Email é obrigatório e deve ser uma string'
    );
  }

  // Normalizar email
  const emailNormalized = email.trim().toLowerCase();

  // Validar formato básico do email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(emailNormalized)) {
    throw new HttpsError(
      'invalid-argument',
      'Formato de email inválido'
    );
  }

  try {
    const adminAuthCheck = admin.auth();
    
    // Usar Firebase Admin Auth para verificar se email existe
    try {
      await adminAuthCheck.getUserByEmail(emailNormalized);
      
      console.log('Email availability check - exists', {
        email: emailNormalized.substring(0, 3) + '***',
        uid: request.auth?.uid
      });

      return {
        emailExists: true
      };
    } catch (error: any) {
      if (error.code === 'auth/user-not-found') {
        console.log('Email availability check - not found', {
          email: emailNormalized.substring(0, 3) + '***',
          uid: request.auth?.uid
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
    console.error('Error checking email availability', {
      email: emailNormalized.substring(0, 3) + '***',
      error: error instanceof Error ? error.message : String(error),
      uid: request.auth?.uid
    });

    throw new HttpsError(
      'internal',
      'Erro interno ao verificar disponibilidade do email'
    );
  }
});