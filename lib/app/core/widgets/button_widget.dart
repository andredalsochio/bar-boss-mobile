import 'package:flutter/material.dart';
import 'package:bar_boss_mobile/app/core/constants/app_colors.dart';
import 'package:bar_boss_mobile/app/core/constants/app_sizes.dart';

/// Widget de botão padrão do aplicativo
class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? width;
  final IconData? icon;
  
  const ButtonWidget({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.width,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? (isOutlined ? Colors.transparent : AppColors.primary(context));
    final txtColor = textColor ?? (isOutlined ? AppColors.primary(context) : AppColors.buttonText(context));
    final double btnHeight = height ?? 48.0;
    final double? btnWidth = isFullWidth ? double.infinity : width;
    
    return SizedBox(
      height: btnHeight,
      width: btnWidth,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: txtColor,
          elevation: isOutlined ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius4),
            side: isOutlined
                ? BorderSide(color: AppColors.primary(context), width: AppSizes.borderWidth)
                : BorderSide.none,
          ),
          padding: AppSizes.paddingHorizontal16,
          disabledBackgroundColor: AppColors.buttonDisabled(context),
          disabledForegroundColor: AppColors.buttonText(context),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonText(context)),
                ),
              )
            : _buildButtonContent(),
      ),
    );
  }
  
  Widget _buildButtonContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSizes.iconSize16),
          SizedBox(width: AppSizes.spacing8),
          Text(
            text,
            style: TextStyle(
              fontSize: AppSizes.fontSize16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    
    return Text(
      text,
      style: TextStyle(
        fontSize: AppSizes.fontSize16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}