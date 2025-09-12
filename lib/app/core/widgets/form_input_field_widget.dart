import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';

/// Widget de campo de formulário padrão do aplicativo
class FormInputFieldWidget extends StatelessWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function()? onTap;
  final bool readOnly;
  final bool showError;
  
  const FormInputFieldWidget({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
    this.focusNode,
    this.textInputAction,
    this.onTap,
    this.readOnly = false,
    this.showError = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[  
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontSize12,
              fontWeight: FontWeight.bold,
              color: AppColors.textHint(context),
            ),
          ),
          SizedBox(height: AppSizes.spacing4),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          enabled: enabled,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onTap: onTap,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: AppSizes.fontSize14,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                fontSize: AppSizes.fontSize14,
                color: AppColors.textHint(context),
              ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSizes.spacing12,
              vertical: AppSizes.spacing12,
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
              borderSide: BorderSide(
                color: AppColors.border(context),
                width: AppSizes.borderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
                borderSide: BorderSide(
                  color: showError ? AppColors.error : AppColors.border(context),
                  width: AppSizes.borderWidth,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
                 borderSide: BorderSide(
                   color: showError ? AppColors.error : AppColors.primary(context),
                   width: AppSizes.borderWidth,
                 ),
               ),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: AppSizes.borderWidth,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: AppSizes.borderWidth,
                ),
              ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: AppSizes.borderWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }
}