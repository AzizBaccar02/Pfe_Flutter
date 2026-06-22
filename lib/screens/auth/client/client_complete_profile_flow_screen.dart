import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../conf/user_profile_provider.dart';
import '../../../models/client_profile_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/app_realtime_coordinator.dart';
import '../../../services/profile_service.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/phone_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../../offers/client/client_main_screen.dart';
import '../widgets/profile_photo_picker.dart';
import '../widgets/profile_section_card.dart';
import '../widgets/tunisia_city_dropdown.dart';

class ClientCompleteProfileFlowScreen extends StatefulWidget {
  const ClientCompleteProfileFlowScreen({super.key});

  @override
  State<ClientCompleteProfileFlowScreen> createState() =>
      _ClientCompleteProfileFlowScreenState();
}

class _ClientCompleteProfileFlowScreenState
    extends State<ClientCompleteProfileFlowScreen> {
  final GlobalKey<FormState> _basicInfoKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _contactInfoKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  int _currentStep = 0;
  String? selectedCity;
  XFile? selectedProfileImage;

  bool _isInitializing = true;
  bool _isSubmitting = false;
  String? _screenError;
  String? _remoteProfileImageUrl;
  bool _didInitLocalImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitLocalImage) return;
    _didInitLocalImage = true;

    final savedPath = context.read<UserProfileProvider>().localProfileImagePath;
    if (savedPath != null && savedPath.isNotEmpty) {
      selectedProfileImage = XFile(savedPath);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final ClientProfileModel data = await ProfileService.getClientProfile();

      if (!mounted) return;

      final profileProvider = context.read<UserProfileProvider>();
      final localPath = profileProvider.localProfileImagePath;
      final remoteUrl = ProfileService.resolveMediaUrl(data.photoUrl);

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        profileProvider.setRemoteProfileImageUrl(remoteUrl);
      }

      setState(() {
        firstNameController.text = data.firstName;
        lastNameController.text = data.lastName;
        phoneController.text = data.phone;
        addressController.text = data.address;
        postalCodeController.text = data.postalCode;
        selectedCity = data.city.isEmpty ? null : data.city;
        _remoteProfileImageUrl = remoteUrl;
        if (localPath != null && localPath.isNotEmpty) {
          selectedProfileImage = XFile(localPath);
        }
        _screenError = null;
      });
    } on ProfileException catch (e) {
      if (!mounted) return;
      setState(() {
        _screenError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _screenError = 'Unable to load your profile information.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    }
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your first name';
    }
    if (value.trim().length < 2) {
      return 'First name must be at least 2 characters';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your last name';
    }
    if (value.trim().length < 2) {
      return 'Last name must be at least 2 characters';
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

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _basicInfoKey.currentState?.validate() ?? false;
    }

    if (_currentStep == 1) {
      return _contactInfoKey.currentState?.validate() ?? false;
    }

    if (_currentStep == 2) {
      if (selectedCity == null || selectedCity!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please choose your city.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _goNext() async {
    if (_currentStep == 3) {
      await _handleFinish();
      return;
    }

    if (!_validateCurrentStep()) return;

    setState(() {
      _isSubmitting = true;
      _screenError = null;
    });

    try {
      if (_currentStep == 0) {
        await ProfileService.updateClientBasicInfo(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
        );
      } else if (_currentStep == 1) {
        await ProfileService.updateClientContact(
          phone: phoneController.text.trim(),
          photoPath: selectedProfileImage?.path,
        );
      } else if (_currentStep == 2) {
        await ProfileService.updateClientLocation(
          city: selectedCity!,
          address: addressController.text.trim(),
          postalCode: postalCodeController.text.trim(),
        );
      }

      AppRealtimeCoordinator.instance.notifyRefresh(debugLabel: 'client_profile_step');

      if (!mounted) return;

      setState(() {
        _currentStep++;
      });
    } on ProfileException catch (e) {
      if (!mounted) return;
      setState(() {
        _screenError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _screenError = 'Unable to save this step. Please try again.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _goBack() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  Future<void> _handleFinish() async {
    await AuthService.markCompleteProfilePromptSeen();
    AppRealtimeCoordinator.instance.notifyRefresh(debugLabel: 'client_profile_done');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile completed successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientEntryScreen(),
      ),
      (route) => false,
    );
  }

  Widget _buildStepIndicator(bool isDarkMode) {
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final inactiveColor = isDarkMode
        ? Colors.white.withOpacity(0.14)
        : Colors.black.withOpacity(0.08);

    const labels = ['Basic', 'Contact', 'Location', 'Finish'];

    return Row(
      children: List.generate(labels.length, (index) {
        final isActive = index <= _currentStep;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? primaryTextColor : inactiveColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[index],
                  style: TextStyle(
                    color: isActive
                        ? primaryTextColor
                        : primaryTextColor.withOpacity(0.45),
                    fontSize: 11.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBasicStep(bool isDarkMode) {
    final iconColor = isDarkMode
        ? Colors.white.withOpacity(0.7)
        : Colors.black.withOpacity(0.7);

    return Form(
      key: _basicInfoKey,
      child: ProfileSectionCard(
        isDarkMode: isDarkMode,
        title: 'Basic Information',
        child: Column(
          children: [
            CustomTextField(
              labelText: 'First Name *',
              hintText: 'Enter your first name',
              controller: firstNameController,
              validator: _validateFirstName,
              isDarkMode: isDarkMode,
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              labelText: 'Last Name *',
              hintText: 'Enter your last name',
              controller: lastNameController,
              validator: _validateLastName,
              isDarkMode: isDarkMode,
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                color: iconColor,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactStep(bool isDarkMode) {
    return Form(
      key: _contactInfoKey,
      child: Column(
        children: [
          ProfilePhotoPicker(
            key: ValueKey(
              '${selectedProfileImage?.path ?? ''}|${_remoteProfileImageUrl ?? ''}',
            ),
            isDarkMode: isDarkMode,
            initialImage: selectedProfileImage,
            remoteImageUrl: selectedProfileImage == null
                ? _remoteProfileImageUrl
                : null,
            onImageChanged: (image) {
              setState(() {
                selectedProfileImage = image;
                if (image != null) {
                  _remoteProfileImageUrl = null;
                }
              });
              if (image == null) {
                context.read<UserProfileProvider>().clearProfileImage();
              } else {
                context
                    .read<UserProfileProvider>()
                    .setLocalProfileImagePath(image.path);
              }
            },
          ),
          const SizedBox(height: 18),
          ProfileSectionCard(
            isDarkMode: isDarkMode,
            title: 'Contact Information',
            child: PhoneTextField(
              labelText: 'Phone Number *',
              controller: phoneController,
              validator: _validatePhone,
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(bool isDarkMode) {
    final iconColor = isDarkMode
        ? Colors.white.withOpacity(0.7)
        : Colors.black.withOpacity(0.7);

    return ProfileSectionCard(
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
            labelText: 'Street address',
            hintText: 'Enter street address',
            controller: addressController,
            isDarkMode: isDarkMode,
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedLocation01,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            labelText: 'Postal code',
            hintText: 'Enter postal code',
            controller: postalCodeController,
            keyboardType: TextInputType.number,
            isDarkMode: isDarkMode,
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedMapsSquare02,
              color: iconColor,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishStep(bool isDarkMode) {
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.60);
    final cardColor =
        isDarkMode ? const Color(0xFF141414) : const Color(0xFFF4F4F4);

    Widget summaryRow({
      required dynamic icon,
      required String label,
      required String value,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: primaryTextColor.withOpacity(0.78),
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (selectedProfileImage != null)
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: FileImage(File(selectedProfileImage!.path)),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                color: primaryTextColor.withOpacity(0.78),
                size: 28,
              ),
            ),
          ),
        const SizedBox(height: 20),
        summaryRow(
          icon: HugeIcons.strokeRoundedUser,
          label: 'First name',
          value: firstNameController.text.trim(),
        ),
        const SizedBox(height: 12),
        summaryRow(
          icon: HugeIcons.strokeRoundedUser,
          label: 'Last name',
          value: lastNameController.text.trim(),
        ),
        const SizedBox(height: 12),
        summaryRow(
          icon: HugeIcons.strokeRoundedCall02,
          label: 'Phone',
          value: phoneController.text.trim(),
        ),
        const SizedBox(height: 12),
        summaryRow(
          icon: HugeIcons.strokeRoundedLocation01,
          label: 'City',
          value: selectedCity ?? '-',
        ),
        const SizedBox(height: 12),
        summaryRow(
          icon: HugeIcons.strokeRoundedLocation01,
          label: 'Street address',
          value: addressController.text.trim().isEmpty
              ? '-'
              : addressController.text.trim(),
        ),
        const SizedBox(height: 12),
        summaryRow(
          icon: HugeIcons.strokeRoundedMapsSquare02,
          label: 'Postal code',
          value: postalCodeController.text.trim().isEmpty
              ? '-'
              : postalCodeController.text.trim(),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(bool isDarkMode) {
    switch (_currentStep) {
      case 0:
        return _buildBasicStep(isDarkMode);
      case 1:
        return _buildContactStep(isDarkMode);
      case 2:
        return _buildLocationStep(isDarkMode);
      default:
        return _buildFinishStep(isDarkMode);
    }
  }

  String _stepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Tell us your name';
      case 1:
        return 'Add your contact details';
      case 2:
        return 'Choose your city';
      default:
        return 'Review your profile';
    }
  }

  String _stepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Start with your basic identity information.';
      case 1:
        return 'Add your phone number and a profile photo.';
      case 2:
        return 'Select the localisation linked to your account.';
      default:
        return 'Make sure everything looks right before finishing.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.60);

    if (_isInitializing) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryTextColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(isDarkMode: isDarkMode, onPressed: _goBack),
        title: Text(
          'Complete Profile',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              _buildStepIndicator(isDarkMode),
              const SizedBox(height: 26),
              Text(
                _stepTitle(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _stepSubtitle(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (_screenError != null) ...[
                const SizedBox(height: 14),
                Text(
                  _screenError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildCurrentStep(isDarkMode),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                text: _isSubmitting
                    ? 'Saving...'
                    : _currentStep == 3
                        ? 'Finish'
                        : 'Continue',
                onPressed: _isSubmitting ? () {} : _goNext,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    postalCodeController.dispose();
    super.dispose();
  }
}