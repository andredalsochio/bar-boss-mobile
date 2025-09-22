import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';

/// Classe que contém os formatadores utilizados no aplicativo
class Formatters {
  /// Formatador de CNPJ (XX.XXX.XXX/XXXX-XX)
  static final MaskTextInputFormatter cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  
  /// Formatador de CEP (XXXXX-XXX)
  static final MaskTextInputFormatter cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );
  
  /// Formatador de telefone ((XX) XXXXX-XXXX)
  static final MaskTextInputFormatter phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  
  /// Formatador de data (DD/MM/YYYY)
  static final MaskTextInputFormatter dateFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  
  /// Formata uma data para exibição (DD/MM/YYYY)
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }
  
  /// Formata uma data para exibição com dia da semana (SEG 05)
  static String formatDateWithWeekday(DateTime date) {
    final weekdays = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB'];
    final weekday = weekdays[date.weekday % 7];
    return '$weekday ${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Formata uma data para exibição com mês e ano (Junho/24)
  static String formatMonthYear(DateTime date) {
    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    final month = months[date.month - 1];
    final year = date.year.toString().substring(2);
    return '$month/$year';
  }
  
  /// Formata um valor monetário (R$ 0,00)
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }
}