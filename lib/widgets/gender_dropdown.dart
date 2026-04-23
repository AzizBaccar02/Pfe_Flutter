import 'package:flutter/material.dart';

class GenderDropdown extends StatelessWidget {
  final String label;
  final String? selectedGender;
  final ValueChanged<String?> onChanged;
  final bool isDarkMode;

  const GenderDropdown({
    super.key,
    required this.label,
    this.selectedGender,
    required this.onChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedGender,
              hint: Text(
                'Select gender',
                style: TextStyle(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.5),
                ),
              ),
              dropdownColor: isDarkMode ? Colors.grey[900] : Colors.grey[200],
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.7),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}