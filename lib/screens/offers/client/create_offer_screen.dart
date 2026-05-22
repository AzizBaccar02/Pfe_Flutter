import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../conf/theme_provider.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../../../services/offer_service.dart';
import '../../subscription/widgets/usage_limit_dialog.dart';

class CreateOfferScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCreated;

  const CreateOfferScreen({
    super.key,
    this.onBack,
    this.onCreated,
  });

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Plumbing',
    'Electricity',
    'Cleaning',
    'Development',
    'Painting',
    'Delivery',
    'Carpentry',
    'Moving',
    'Air Conditioning',
    'Gardening',
  ];

  final List<String> _tunisiaGovernorates = const [
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

  final List<XFile> _pickedImages = [];

  String? selectedCategory;
  String? selectedCity;

  bool _isSubmitting = false;

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the offer title';
    }
    if (value.trim().length < 4) {
      return 'Title must be at least 4 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the description';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  String? _validateBudget(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the budget';
    }

    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (parsed <= 0) {
      return 'Budget must be greater than 0';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the address';
    }
    if (value.trim().length < 4) {
      return 'Address must be at least 4 characters';
    }
    return null;
  }

  String? _validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the postal code';
    }
    if (value.trim().length < 4) {
      return 'Postal code must be at least 4 characters';
    }
    return null;
  }

  String? _validateCategory() {
    if (selectedCategory == null || selectedCategory!.trim().isEmpty) {
      return 'Please select a category';
    }
    return null;
  }

  String? _validateCity() {
    if (selectedCity == null || selectedCity!.trim().isEmpty) {
      return 'Please select a city';
    }
    return null;
  }

  Future<void> _handleContinue() async {
    if (_isSubmitting) return;

    final categoryError = _validateCategory();
    final cityError = _validateCity();

    if (!_formKey.currentState!.validate() ||
        categoryError != null ||
        cityError != null) {
      setState(() {});
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await OfferService.createOffer(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        budget: double.parse(budgetController.text.trim()),
        category: selectedCategory!,
        city: selectedCity!,
        address: addressController.text.trim(),
        postalCode: postalCodeController.text.trim(),
        imagePaths: _pickedImages.map((image) => image.path).toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer created successfully'),
        ),
      );

      if (widget.onCreated != null) {
        widget.onCreated!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.pop(context, true);
      }
      
    } on OfferException catch (e) {
      if (!mounted) return;

      if (UsageLimitDialog.isUsageLimitMessage(e.message)) {
        await UsageLimitDialog.show(
          context,
          isAgent: false,
          message: e.message,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showImageSourceOptions() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Add image',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _imageSourceTile(
                  isDarkMode: isDarkMode,
                  icon: HugeIcons.strokeRoundedImage01,
                  title: 'From gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromGallery();
                  },
                ),
                const SizedBox(height: 12),
                _imageSourceTile(
                  isDarkMode: isDarkMode,
                  icon: HugeIcons.strokeRoundedCamera01,
                  title: 'Take photo',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromCamera();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imageSourceTile({
    required bool isDarkMode,
    required dynamic icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.7),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 85,
    );

    if (images.isEmpty) return;

    setState(() {
      _pickedImages.addAll(images);
    });
  }

  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _pickedImages.add(image);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  void _openCategoryBottomSheet(bool isDarkMode) {
    final TextEditingController searchController = TextEditingController();
    List<String> filteredCategories = List.from(_categories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterCategories(String query) {
              final trimmed = query.trim().toLowerCase();

              setModalState(() {
                filteredCategories = _categories
                    .where(
                      (category) => category.toLowerCase().contains(trimmed),
                    )
                    .toList();
              });
            }

            final query = searchController.text.trim();
            final exactExists = _categories.any(
              (category) => category.toLowerCase() == query.toLowerCase(),
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Select a category',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    onChanged: filterCategories,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search category',
                      hintStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black.withOpacity(0.5),
                      ),
                      prefixIcon: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.7),
                        size: 18,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (filteredCategories.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          final isSelected = selectedCategory == category;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = category;
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDarkMode
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.08))
                                    : (isDarkMode
                                        ? Colors.white.withOpacity(0.04)
                                        : Colors.black.withOpacity(0.03)),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDarkMode
                                          ? Colors.white
                                          : Colors.black)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedWork,
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.black.withOpacity(0.7),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (query.isNotEmpty && !exactExists) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        final newCategory = query.trim();

                        setState(() {
                          _categories.add(newCategory);
                          selectedCategory = newCategory;
                        });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Category "$newCategory" added'),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedAdd01,
                              color: isDarkMode ? Colors.white : Colors.black,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Add "$query"',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openCityBottomSheet(bool isDarkMode) {
    final TextEditingController searchController = TextEditingController();
    List<String> filteredCities = List.from(_tunisiaGovernorates);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterCities(String query) {
              final trimmed = query.trim().toLowerCase();

              setModalState(() {
                filteredCities = _tunisiaGovernorates
                    .where((city) => city.toLowerCase().contains(trimmed))
                    .toList();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Select a city',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    onChanged: filterCities,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search city',
                      hintStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black.withOpacity(0.5),
                      ),
                      prefixIcon: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.7),
                        size: 18,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        final isSelected = selectedCity == city;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCity = city;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDarkMode
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.08))
                                  : (isDarkMode
                                      ? Colors.white.withOpacity(0.04)
                                      : Colors.black.withOpacity(0.03)),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? (isDarkMode
                                        ? Colors.white
                                        : Colors.black)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              city,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionContainer({
    required bool isDarkMode,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _pickerField({
    required bool isDarkMode,
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
    required bool hasError,
    required dynamic icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: hasError ? Border.all(color: Colors.red) : null,
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.7),
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? placeholder,
                style: TextStyle(
                  color: value == null
                      ? (isDarkMode
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.5))
                      : (isDarkMode ? Colors.white : Colors.black),
                  fontSize: 14,
                ),
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageCard({
    required bool isDarkMode,
    required XFile image,
    required VoidCallback onRemove,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: FileImage(File(image.path)),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.7)
        : Colors.black.withOpacity(0.7);

    final categoryError = _validateCategory();
    final cityError = _validateCity();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDarkMode
                ? Colors.white.withOpacity(0.7)
                : Colors.black.withOpacity(0.7),
            size: 18,
          ),
        ),
        title: Text(
          'Create Offer',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 22,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add the main information, localisation and images for your service request.',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),

                // 1) IMAGES AT THE TOP
                _sectionContainer(
                  isDarkMode: isDarkMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Images',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Add one or more images for your offer.',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _showImageSourceOptions,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.10)
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedAdd01,
                                color: isDarkMode ? Colors.white : Colors.black,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Add image',
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_pickedImages.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedImages.length,
                            itemBuilder: (context, index) {
                              final image = _pickedImages[index];
                              return _imageCard(
                                isDarkMode: isDarkMode,
                                image: image,
                                onRemove: () => _removeImage(index),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 2) OFFER INFORMATION
                _sectionContainer(
                  isDarkMode: isDarkMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offer Information',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        labelText: 'Title *',
                        hintText: 'Example: Need a plumber urgently',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedWork,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 18,
                        ),
                        controller: titleController,
                        validator: _validateTitle,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        labelText: 'Description *',
                        hintText: 'Describe the service you need',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedNoteEdit,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 18,
                        ),
                        controller: descriptionController,
                        validator: _validateDescription,
                        maxLines: 5,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        labelText: 'Budget *',
                        hintText: 'Enter your budget',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedMoneyBag01,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 18,
                        ),
                        keyboardType: TextInputType.number,
                        controller: budgetController,
                        validator: _validateBudget,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Category *',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _pickerField(
                        isDarkMode: isDarkMode,
                        value: selectedCategory,
                        placeholder: 'Select a category',
                        onTap: () => _openCategoryBottomSheet(isDarkMode),
                        hasError: categoryError != null,
                        icon: HugeIcons.strokeRoundedWork,
                      ),
                      if (categoryError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          categoryError,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 3) LOCALISATION
                _sectionContainer(
                  isDarkMode: isDarkMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Localisation',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'City *',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _pickerField(
                        isDarkMode: isDarkMode,
                        value: selectedCity,
                        placeholder: 'Select a city',
                        onTap: () => _openCityBottomSheet(isDarkMode),
                        hasError: cityError != null,
                        icon: HugeIcons.strokeRoundedLocation01,
                      ),
                      if (cityError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          cityError,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      CustomTextField(
                        labelText: 'Address *',
                        hintText: 'Enter the address',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedMapsLocation02,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 18,
                        ),
                        controller: addressController,
                        validator: _validateAddress,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        labelText: 'Postal Code *',
                        hintText: 'Enter the postal code',
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedMailbox01,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 18,
                        ),
                        keyboardType: TextInputType.number,
                        controller: postalCodeController,
                        validator: _validatePostalCode,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),
                PrimaryButton(
                  text: _isSubmitting ? 'Creating...' : 'Continue',
                  onPressed: _isSubmitting
                      ? () {}
                      : () {
                          _handleContinue();
                        },
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
    titleController.dispose();
    descriptionController.dispose();
    budgetController.dispose();
    addressController.dispose();
    postalCodeController.dispose();
    super.dispose();
  }
}