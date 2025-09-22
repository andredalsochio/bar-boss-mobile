/// Helpers para normalização de dados de entrada
/// Utilizados para garantir consistência nos dados antes de validações e persistência
class NormalizationHelpers {
  /// Normaliza email removendo espaços e convertendo para lowercase
  /// 
  /// Exemplo:
  /// ```dart
  /// normalizeEmail('  USER@EXAMPLE.COM  ') // retorna 'user@example.com'
  /// ```
  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Normaliza CNPJ removendo todos os caracteres não numéricos
  /// 
  /// Exemplo:
  /// ```dart
  /// normalizeCnpj('12.345.678/0001-90') // retorna '12345678000190'
  /// ```
  static String normalizeCnpj(String cnpj) {
    return cnpj.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Valida CNPJ usando algoritmo de dígitos verificadores
  /// 
  /// Recebe CNPJ já normalizado (apenas dígitos)
  /// Retorna true se o CNPJ for válido
  /// 
  /// Exemplo:
  /// ```dart
  /// isValidCnpj('12345678000190') // retorna true/false
  /// ```
  static bool isValidCnpj(String cnpj) {
    // Verifica se tem exatamente 14 dígitos
    if (cnpj.length != 14) return false;
    
    // Verifica se todos os dígitos são iguais (CNPJs inválidos)
    if (RegExp(r'^(\d)\1*$').hasMatch(cnpj)) return false;
    
    // Converte string para lista de inteiros
    List<int> numbers = cnpj.split('').map(int.parse).toList();
    
    // Calcula primeiro dígito verificador
    int sum = 0;
    int weight = 5;
    
    for (int i = 0; i < 12; i++) {
      sum += numbers[i] * weight;
      weight = weight == 2 ? 9 : weight - 1;
    }
    
    int digit1 = sum % 11 < 2 ? 0 : 11 - (sum % 11);
    
    // Verifica primeiro dígito
    if (numbers[12] != digit1) return false;
    
    // Calcula segundo dígito verificador
    sum = 0;
    weight = 6;
    
    for (int i = 0; i < 13; i++) {
      sum += numbers[i] * weight;
      weight = weight == 2 ? 9 : weight - 1;
    }
    
    int digit2 = sum % 11 < 2 ? 0 : 11 - (sum % 11);
    
    // Verifica segundo dígito
    return numbers[13] == digit2;
  }

  /// Normaliza telefone removendo caracteres não numéricos
  /// 
  /// Exemplo:
  /// ```dart
  /// normalizePhone('(11) 99999-9999') // retorna '11999999999'
  /// ```
  static String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Normaliza nomes convertendo para caixa alta e removendo acentos
  /// 
  /// Exemplo:
  /// ```dart
  /// normalizeName('João da Silva') // retorna 'JOAO DA SILVA'
  /// normalizeName('Café & Cia') // retorna 'CAFE & CIA'
  /// ```
  static String normalizeName(String name) {
    // Remove espaços extras no início e fim
    String normalized = name.trim();
    
    // Converte para caixa alta
    normalized = normalized.toUpperCase();
    
    // Remove acentos e caracteres especiais
    const Map<String, String> accentMap = {
      'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
      'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E',
      'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
      'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
      'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U',
      'Ç': 'C', 'Ñ': 'N',
      'à': 'A', 'á': 'A', 'â': 'A', 'ã': 'A', 'ä': 'A', 'å': 'A',
      'è': 'E', 'é': 'E', 'ê': 'E', 'ë': 'E',
      'ì': 'I', 'í': 'I', 'î': 'I', 'ï': 'I',
      'ò': 'O', 'ó': 'O', 'ô': 'O', 'õ': 'O', 'ö': 'O',
      'ù': 'U', 'ú': 'U', 'û': 'U', 'ü': 'U',
      'ç': 'C', 'ñ': 'N'
    };
    
    // Substitui cada caractere acentuado
    accentMap.forEach((accented, unaccented) {
      normalized = normalized.replaceAll(accented, unaccented);
    });
    
    return normalized;
  }
}