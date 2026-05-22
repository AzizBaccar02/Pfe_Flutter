import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../conf/app_colors.dart';

class PhoneTextField extends StatefulWidget {
  final TextEditingController controller;
  final bool isDarkMode;
  final String? labelText;
  final String hintText;
  final String initialIsoCode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onChangedFullPhone;
  final String? Function(String?)? validator;

  const PhoneTextField({
    super.key,
    required this.controller,
    required this.isDarkMode,
    this.labelText,
    this.hintText = 'XX XXX XXX',
    this.initialIsoCode = 'TN',
    this.onChanged,
    this.onChangedFullPhone,
    this.validator,
  });

  @override
  State<PhoneTextField> createState() => _PhoneTextFieldState();
}

class _PhoneTextFieldState extends State<PhoneTextField> {
  late PhoneNumber _initialNumber;

  @override
  void initState() {
    super.initState();
    _initialNumber = PhoneNumber(isoCode: widget.initialIsoCode);
  }

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.accent;
    const accentDeep = AppColors.accentDeep;

    final fillColor =
        widget.isDarkMode ? const Color(0xFF151515) : const Color(0xFFF7F7F7);

    final borderColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final hintColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.42)
        : Colors.black.withOpacity(0.42);

    final neutralIconColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: InternationalPhoneNumberInput(
            initialValue: _initialNumber,
            textFieldController: widget.controller,
            selectorConfig: const SelectorConfig(
              selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
              useEmoji: true,
              trailingSpace: false,
            ),
            ignoreBlank: false,
            autoValidateMode: AutovalidateMode.disabled,
            formatInput: true,
            keyboardType: const TextInputType.numberWithOptions(
              signed: false,
              decimal: false,
            ),
            inputDecoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 18,
              ),
            ),
            selectorTextStyle: TextStyle(
              color: neutralIconColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textStyle: TextStyle(
              color: textColor,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: accentDeep,
            searchBoxDecoration: InputDecoration(
              hintText: 'Search country',
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: accent.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: accent.withValues(alpha: 0.7),
                ),
              ),
            ),
            onInputChanged: (PhoneNumber number) {
              widget.onChanged?.call(widget.controller.text);
              widget.onChangedFullPhone?.call(number.phoneNumber ?? '');
            },
            validator: widget.validator,
          ),
        ),
      ],
    );
  }
}