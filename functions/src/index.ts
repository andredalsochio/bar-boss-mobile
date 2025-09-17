import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Inicializar Firebase Admin
admin.initializeApp();

/**
 * Cloud Function callable para verificar disponibilidade de CNPJ
 * Permite validação sem depender de permissões do cliente no Firestore
 */
export const checkAvailability = functions.https.onCall(async (data: any, context: any) => {
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
    const db = admin.firestore();
    
    // Verificar se CNPJ existe no registro
    const cnpjRegistryDoc = await db
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