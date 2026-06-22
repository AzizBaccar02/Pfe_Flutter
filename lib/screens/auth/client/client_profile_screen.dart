import 'package:flutter/material.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../conf/theme_provider.dart';
import '../../../conf/user_profile_provider.dart';
import '../../../models/client_profile_model.dart';
import '../../../services/app_realtime_coordinator.dart';
import '../../../services/profile_service.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/phone_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_photo_picker.dart';
import '../widgets/profile_section_card.dart';
import '../widgets/tunisia_city_dropdown.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  XFile? selectedProfileImage;
  String? selectedCity;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _screenError;
  String? _remoteProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _screenError = null;
    });

    try {
      final ClientProfileModel profile =
          await ProfileService.getClientProfile();

      if (!mounted) return;

      final profileProvider = context.read<UserProfileProvider>();
      final localPath = profileProvider.localProfileImagePath;
      final remoteUrl = ProfileService.resolveMediaUrl(profile.photoUrl);

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        profileProvider.setRemoteProfileImageUrl(remoteUrl);
      } else if ((localPath ?? '').isEmpty) {
        profileProvider.clearProfileImage();
      }

      setState(() {
        phoneController.text = profile.phone;
        addressController.text = profile.address;
        postalCodeController.text = profile.postalCode;
        selectedCity = profile.city.trim().isEmpty ? null : profile.city;
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
        _isLoading = false;
      });
    }
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

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your address';
    }

    return null;
  }

  String? _validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the postal code';
    }

    return null;
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final isFormValid = _formKey.currentState?.validate() ?? false;
    final isCityValid = selectedCity != null && selectedCity!.trim().isNotEmpty;

    if (!isFormValid || !isCityValid) {
      if (!isCityValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please choose your city.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return;
    }

    setState(() {
      _isSaving = true;
      _screenError = null;
    });

    try {
      await ProfileService.updateClientContact(
        phone: phoneController.text.trim(),
        photoPath: selectedProfileImage?.path,
      );

      await ProfileService.updateClientLocation(
        city: selectedCity!,
        address: addressController.text.trim(),
        postalCode: postalCodeController.text.trim(),
      );

      final refreshedProfile = await ProfileService.getClientProfile();

      if (!mounted) return;

      final profileProvider = context.read<UserProfileProvider>();
      final remoteUrl =
          ProfileService.resolveMediaUrl(refreshedProfile.photoUrl);

      if (selectedProfileImage != null) {
        profileProvider.setLocalProfileImagePath(selectedProfileImage!.path);
      } else if (remoteUrl != null && remoteUrl.isNotEmpty) {
        profileProvider.setRemoteProfileImageUrl(remoteUrl);
      } else {
        profileProvider.clearProfileImage();
      }

      setState(() {
        phoneController.text = refreshedProfile.phone;
        addressController.text = refreshedProfile.address;
        postalCodeController.text = refreshedProfile.postalCode;
        selectedCity = refreshedProfile.city.trim().isEmpty
            ? selectedCity
            : refreshedProfile.city;
        _remoteProfileImageUrl = remoteUrl;
      });

      AppRealtimeCoordinator.instance.notifyRefresh(debugLabel: 'client_profile');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client profile saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } on ProfileException catch (e) {
      if (!mounted) return;

      setState(() {
        _screenError = e.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      const message = 'Unable to save your profile. Please try again.';

      setState(() {
        _screenError = message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: CircularProgressIndicator(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.black.withValues(alpha: 0.62);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _screenError ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _loadProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: isDarkMode ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isDarkMode) {
    final iconColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.7);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            ProfileHeaderCard(
              isDarkMode: isDarkMode,
              title: 'Client Profile',
              subtitle:
                  'Manage your contact information and localisation details.',
              icon: HugeIcons.strokeRoundedUser,
            ),
            const SizedBox(height: 18),
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
            if (_screenError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _screenError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                    labelText: 'Address *',
                    hintText: 'Enter your address',
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedMapsLocation02,
                      color: iconColor,
                      size: 18,
                    ),
                    controller: addressController,
                    validator: _validateAddress,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    labelText: 'Postal Code *',
                    hintText: 'Enter your postal code',
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedMailbox01,
                      color: iconColor,
                      size: 18,
                    ),
                    controller: postalCodeController,
                    validator: _validatePostalCode,
                    keyboardType: TextInputType.number,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: _isSaving ? 'Saving...' : 'Save Profile',
              onPressed: _isSaving ? () {} : _handleSave,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
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
        leading: AppBackButton(isDarkMode: isDarkMode),
        title: Text(
          'Client Profile',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(isDarkMode)
            : _screenError != null &&
                    phoneController.text.trim().isEmpty &&
                    addressController.text.trim().isEmpty &&
                    postalCodeController.text.trim().isEmpty
                ? _buildErrorState(isDarkMode)
                : _buildForm(isDarkMode),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    addressController.dispose();
    postalCodeController.dispose();
    super.dispose();
  }
}