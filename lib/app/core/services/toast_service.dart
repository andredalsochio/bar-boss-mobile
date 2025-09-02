import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Serviço centralizado para exibição de mensagens toast
/// Utiliza o package toastification para feedback visual moderno
class ToastService {
  static ToastService? _instance;
  static ToastService get instance => _instance ??= ToastService._();
  
  ToastService._();

  /// Exibe toast de sucesso
  void showSuccess({
    required String message,
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? const Duration(seconds: 4),
      showProgressBar: true,
      dragToClose: true,
      applyBlurEffect: true,
    );
  }

  /// Exibe toast de erro
  void showError({
    required String message,
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? const Duration(seconds: 5),
      showProgressBar: true,
      dragToClose: true,
      applyBlurEffect: true,
    );
  }

  /// Exibe toast de aviso
  void showWarning({
    required String message,
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      type: ToastificationType.warning,
      style: ToastificationStyle.fillColored,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? const Duration(seconds: 4),
      showProgressBar: true,
      dragToClose: true,
      applyBlurEffect: true,
    );
  }

  /// Exibe toast informativo
  void showInfo({
    required String message,
    String? title,
    Duration? duration,
  }) {
    toastification.show(
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      title: title != null ? Text(title) : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration ?? const Duration(seconds: 4),
      showProgressBar: true,
      dragToClose: true,
      applyBlurEffect: true,
    );
  }

  /// Remove todos os toasts ativos
  void dismissAll() {
    toastification.dismissAll();
  }
}