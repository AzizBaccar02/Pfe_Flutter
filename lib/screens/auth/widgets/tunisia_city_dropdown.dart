import 'package:flutter/material.dart';

class TunisiaCityDropdown extends StatelessWidget {
  final bool isDarkMode;
  final String? value;
  final ValueChanged<String?> onChanged;

  const TunisiaCityDropdown({
    super.key,
    required this.isDarkMode,
    required this.value,
    required this.onChanged,
  });

  static const List<String> cities = [
    'Tunis',
    'Ariana',
    'Ben Arous',
    'Manouba',
    'Nabeul',
    'Zaghouan',
    'Bizerte',
    'Beja',
    'Jendouba',
    'Kef',
    'Siliana',
    'Sousse',
    'Monastir',
    'Mahdia',
    'Sfax',
    'Kairouan',
    'Kasserine',
    'Sidi Bouzid',
    'Gabes',
    'Medenine',
    'Tataouine',
    'Gafsa',
    'Tozeur',
    'Kebili',
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.5);

    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      iconEnabledColor: textColor,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: 'Select city',
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      items: cities
          .map(
            (city) => DropdownMenuItem(
              value: city,
              child: Text(city),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a city';
        }
        return null;
      },
    );
  }
}