import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../conf/theme_provider.dart';
import '../../../conf/user_profile_provider.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/phone_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_photo_picker.dart';
import '../widgets/profile_section_card.dart';
import '../widgets/tunisia_city_dropdown.dart';

class AgentProfileScreen extends StatefulWidget {
  const AgentProfileScreen({super.key});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  XFile? selectedProfileImage;
  String? selectedCity;
  bool _didInitImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitImage) return;
    _didInitImage = true;

    final savedPath = context.read<UserProfileProvider>().profileImagePath;
    if (savedPath != null && savedPath.isNotEmpty) {
      selectedProfileImage = XFile(savedPath);
    }
  }

  String? _requiredField(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  String? _validateHourlyRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your hourly rate';
    }
    final rate = double.tryParse(value.trim());
    if (rate == null || rate <= 0) {
      return 'Hourly rate must be greater than 0';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.trim().length < 8) {
      return 'Phone number is too short';
    }
    return null;
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Agent profile saved successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDarkMode
                ? Colors.white.withOpacity(0.7)
                : Colors.black.withOpacity(0.7),
            size: 18,
          ),
        ),
        title: Text(
          'Agent Profile',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                ProfileHeaderCard(
                  isDarkMode: isDarkMode,
                  title: 'Complete Your Agent Profile',
                  subtitle:
                      'Show your skills and experience to attract the right clients.',
                  icon: HugeIcons.strokeRoundedWork,
                ),
                const SizedBox(height: 18),
                ProfilePhotoPicker(
                  isDarkMode: isDarkMode,
                  initialImage: selectedProfileImage,
                  onImageChanged: (image) {
                    setState(() {
                      selectedProfileImage = image;
                    });
                    context
                        .read<UserProfileProvider>()
                        .setProfileImagePath(image?.path);
                  },
                ),
                const SizedBox(height: 18),
                ProfileSectionCard(
                  isDarkMode: isDarkMode,
                  title: 'Professional Information',
                  child: Column(
                    children: [
                      PhoneTextField(
                        labelText: 'Phone Number *',
                        controller: phoneController,
                        validator: _validatePhone,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'Bio *',
                        hint: 'Describe your experience and services',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedNoteEdit,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 18,
                        ),
                        controller: bioController,
                        validator: (value) =>
                            _requiredField(value, 'Please enter your bio'),
                        maxLines: 4,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'Skills *',
                        hint: 'Example: Plumbing, Electricity, Repair',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedTools,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 18,
                        ),
                        controller: skillsController,
                        validator: (value) =>
                            _requiredField(value, 'Please enter your skills'),
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'Hourly Rate *',
                        hint: 'Enter your hourly rate',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedMoneyBag01,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 18,
                        ),
                        controller: hourlyRateController,
                        validator: _validateHourlyRate,
                        keyboardType: TextInputType.number,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ProfileSectionCard(
                  isDarkMode: isDarkMode,
                  title: 'Localisation',
                  child: Column(
                    children: [
                      TunisiaCityDropdown(
                        isDarkMode: isDarkMode,
                        value: selectedCity,
                        onChanged: (value) {
                          setState(() {
                            selectedCity = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'Address *',
                        hint: 'Enter your address',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedMapsLocation02,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 18,
                        ),
                        controller: addressController,
                        validator: (value) =>
                            _requiredField(value, 'Please enter your address'),
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'Postal Code *',
                        hint: 'Enter your postal code',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedMailbox01,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 18,
                        ),
                        controller: postalCodeController,
                        validator: (value) => _requiredField(
                          value,
                          'Please enter your postal code',
                        ),
                        keyboardType: TextInputType.number,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Save Profile',
                  onPressed: _handleSave,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    bioController.dispose();
    skillsController.dispose();
    hourlyRateController.dispose();
    addressController.dispose();
    postalCodeController.dispose();
    super.dispose();
  }
}