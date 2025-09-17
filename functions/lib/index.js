"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkAvailability = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
// Inicializar Firebase Admin
admin.initializeApp();
/**
 * Cloud Function callable para verificar disponibilidade de CNPJ
 * Permite validação sem depender de permissões do cliente no Firestore
 */
exports.checkAvailability = functions.https.onCall(async (data, context) => {
    // Validar autenticação (obrigatória)
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Usuário deve estar autenticado para verificar disponibilidade');
    }
    const { cnpj } = data;
    // Validar parâmetros
    if (!cnpj || typeof cnpj !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'CNPJ é obrigatório e deve ser uma string');
    }
    // Normalizar CNPJ (apenas dígitos)
    const cnpjClean = cnpj.replace(/[^\d]/g, '');
    // Validar formato do CNPJ
    if (cnpjClean.length !== 14) {
        throw new functions.https.HttpsError('invalid-argument', 'CNPJ deve conter exatamente 14 dígitos');
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
            cnpj: cnpjClean.substring(0, 4) + '***',
            exists,
            uid: context.auth.uid
        });
        return {
            cnpjExists: exists
        };
    }
    catch (error) {
        functions.logger.error('Error checking CNPJ availability', {
            cnpj: cnpjClean.substring(0, 4) + '***',
            error: error instanceof Error ? error.message : String(error),
            uid: context.auth.uid
        });
        throw new functions.https.HttpsError('internal', 'Erro interno ao verificar disponibilidade do CNPJ');
    }
});
//# sourceMappingURL=index.js.map