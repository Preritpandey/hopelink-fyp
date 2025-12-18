import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final double? width;
  final double radius;
  final Widget? icon;
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.title,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.backgroundColor,
    this.textColor,
    this.height = 46,
    this.width,
    this.radius = 4,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && !loading && onPressed != null;
    final bgColor = backgroundColor ?? AppColorToken.primary.color;
    final fgColor = textColor ?? AppColorToken.white.color;

    return SizedBox(
      height: height,
      width: width ?? double.infinity,

      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? bgColor : AppColorToken.grey.color,
          foregroundColor: fgColor,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          elevation: 0,
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(
                    title,
                    style: AppTextStyle.size(
                      14,
                    ).semiBold.copyWith(color: fgColor),
                  ),
                ],
              ),
      ),
    );
  }
}

class AppOutlinedButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final Color? borderColor;
  final Color? textColor;
  final double height;
  final double? width;
  final double radius;
  final Widget? icon;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const AppOutlinedButton({
    super.key,
    required this.title,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.borderColor,
    this.textColor,
    this.height = 46,
    this.width,
    this.radius = 4,
    this.icon,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && !loading && onPressed != null;
    final color = borderColor ?? AppColorToken.grey.color;
    final txtColor = textColor ?? AppColorToken.primary.color;

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.transparent,
          side: BorderSide(
            color: isEnabled ? color : AppColorToken.grey.color,
            width: 1,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isEnabled ? txtColor : AppColorToken.grey.color,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(
                    title,
                    style: AppTextStyle.size(14).semiBold.copyWith(
                      color: isEnabled ? txtColor : AppColorToken.grey.color,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class AppTextButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final Color? textColor;
  final Widget? icon;
  final EdgeInsets? padding;

  const AppTextButton({
    super.key,
    required this.title,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.textColor,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && !loading && onPressed != null;
    final color = textColor ?? AppColorToken.primary.color;

    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isEnabled ? color : AppColorToken.grey.color,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 4)],
                Text(
                  title,
                  style: AppTextStyle.size(14).medium.copyWith(
                    color: isEnabled ? color : AppColorToken.grey.color,
                  ),
                ),
              ],
            ),
    );
  }
}
