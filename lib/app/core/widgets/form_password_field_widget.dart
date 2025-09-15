import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';

/// Widget de campo de senha com toggle de visibilidade
class FormPasswordFieldWidget extends StatefulWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function()? onTap;
  final bool readOnly;
  final bool showError;
  
  const FormPasswordFieldWidget({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.maxLength,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onTap,
    this.readOnly = false,
    this.showError = false,
  });

  @override
  State<FormPasswordFieldWidget> createState() => _FormPasswordFieldWidgetState();
}

class _FormPasswordFieldWidgetState extends State<FormPasswordFieldWidget> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: TextStyle(
              fontSize: AppSizes.fontSize12,
              fontWeight: FontWeight.bold,
              color: AppColors.textHint(context),
            ),
          ),
          SizedBox(height: AppSizes.spacing4),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          keyboardType: TextInputType.visiblePassword,
          obscureText: _obscureText,
          validator: widget.validator,
          onChanged: widget.onChanged,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          maxLines: 1,
          enabled: widget.enabled,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          style: TextStyle(
            fontSize: AppSizes.fontSize14,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: AppSizes.fontSize14,
              color: AppColors.textHint(context),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSizes.spacing12,
              vertical: AppSizes.spacing12,
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.white : Colors.grey[100],
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textHint(context),
                size: AppSizes.iconSizeSmall,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
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
                color: widget.showError ? AppColors.error : AppColors.border(context),
                width: AppSizes.borderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
              borderSide: BorderSide(
                color: widget.showError ? AppColors.error : AppColors.primary(context),
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