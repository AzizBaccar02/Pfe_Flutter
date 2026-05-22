import 'package:flutter/material.dart';

import '../conf/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? hint;
  final String? labelText;
  final String? label;
  final bool isDarkMode;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.isDarkMode,
    this.hintText,
    this.hint,
    this.labelText,
    this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.accent;
    const accentDeep = AppColors.accentDeep;

    final resolvedHint = hintText ?? hint ?? '';
    final resolvedLabel = labelText ?? label;

    final fillColor =
        isDarkMode ? const Color(0xFF151515) : const Color(0xFFF7F7F7);

    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    final focusedBorderColor = accent.withValues(alpha: 0.70);

    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode
        ? Colors.white.withOpacity(0.42)
        : Colors.black.withOpacity(0.42);

    final iconColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    Widget? buildPrefixIcon(Widget? icon) {
      if (icon == null) return null;

      return Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          heightFactor: 1,
          child: IconTheme(
            data: IconThemeData(
              color: iconColor,
              size: 18,
            ),
            child: icon,
          ),
        ),
      );
    }

    Widget? buildSuffixIcon(Widget? icon) {
      if (icon == null) return null;

      return Padding(
        padding: const EdgeInsets.only(left: 10, right: 14),
        child: Align(
          alignment: Alignment.centerRight,
          widthFactor: 1,
          heightFactor: 1,
          child: IconTheme(
            data: IconThemeData(
              color: iconColor,
              size: 18,
            ),
            child: icon,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resolvedLabel != null) ...[
          Text(
            resolvedLabel,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          maxLines: obscureText ? 1 : maxLines,
          style: TextStyle(
            color: textColor,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: accentDeep,
          decoration: InputDecoration(
            hintText: resolvedHint,
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: fillColor,
            prefixIcon: buildPrefixIcon(prefixIcon),
            suffixIcon: buildSuffixIcon(suffixIcon),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 46,
              minHeight: 46,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 46,
              minHeight: 46,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: borderColor,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: focusedBorderColor,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}