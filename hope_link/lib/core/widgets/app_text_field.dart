import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hope_link/core/extensions/num_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final AutovalidateMode autovalidateMode;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? errorText;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final String? title;
  final double? borderRadius;
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.focusNode,
    this.inputFormatters,
    this.textInputAction,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.readOnly = false,
    this.onTap,
    this.errorText,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.title,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty)
          Text(
            title!,
            style: AppTextStyle.size(14).regular.withColor(AppColorToken.grey),
          ),
        if (title != null && title!.isNotEmpty) 8.verticalSpace,
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          enabled: enabled,
          focusNode: focusNode,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          autovalidateMode: autovalidateMode,
          readOnly: readOnly,
          onTap: onTap,

          textCapitalization: textCapitalization,
          onTapOutside: (event) =>
              FocusManager.instance.primaryFocus?.unfocus(),
          style: AppTextStyle.size(14).regular.withColor(AppColorToken.black),
          decoration: InputDecoration(
            hintText: hintText,
            labelText: labelText,
            errorText: errorText,
            hintStyle: AppTextStyle.size(
              14,
            ).regular.withColor(AppColorToken.grey),
            labelStyle: AppTextStyle.size(
              14,
            ).regular.withColor(AppColorToken.grey),
            errorStyle: AppTextStyle.size(
              12,
            ).regular.withColor(AppColorToken.error),
            prefixIcon: prefix,
            suffixIcon: suffixIcon ?? suffix,
            counterText: '',
            filled: true,
            fillColor: AppColorToken.white.color,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 0),
              borderSide: BorderSide(
                color: AppColorToken.grey.color,
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 0),
              borderSide: BorderSide(
                color: AppColorToken.grey.color,
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 0),
              borderSide: BorderSide(
                color: AppColorToken.primary.color,
                width: 0.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 0),
              borderSide: BorderSide(
                color: AppColorToken.error.color,
                width: 0.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 0),
              borderSide: BorderSide(
                color: AppColorToken.error.color,
                width: 0.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 0),
              borderSide: BorderSide(
                color: AppColorToken.lightGrey.color,
                width: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String? hintText;
  final String? labelText;
  final String Function(T) itemLabel;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final Widget? prefix;
  final AutovalidateMode autovalidateMode;

  const CustomDropdownField({
    super.key,
    this.value,
    required this.items,
    this.hintText,
    this.labelText,
    required this.itemLabel,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefix,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                style: AppTextStyle.size(
                  14,
                ).regular.withColor(AppColorToken.black),
              ),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
      autovalidateMode: autovalidateMode,
      style: AppTextStyle.size(14).regular.withColor(AppColorToken.black),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: AppTextStyle.size(14).regular.withColor(AppColorToken.grey),
        labelStyle: AppTextStyle.size(14).regular.withColor(AppColorToken.grey),
        prefixIcon: prefix,
        filled: true,
        fillColor: AppColorToken.white.color,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: AppColorToken.grey.color, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: AppColorToken.grey.color, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(
            color: AppColorToken.primary.color,
            width: 0.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: AppColorToken.error.color, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: AppColorToken.error.color, width: 0.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(
            color: AppColorToken.lightGrey.color,
            width: 0.5,
          ),
        ),
      ),
    );
  }
}
