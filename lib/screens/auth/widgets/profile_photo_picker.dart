import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoPicker extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<XFile?> onImageChanged;
  final XFile? initialImage;

  const ProfilePhotoPicker({
    super.key,
    required this.isDarkMode,
    required this.onImageChanged,
    this.initialImage,
  });

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = image;
    });

    widget.onImageChanged(image);
  }

  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = image;
    });

    widget.onImageChanged(image);
  }

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
    });

    widget.onImageChanged(null);
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          widget.isDarkMode ? const Color(0xFF111111) : Colors.white,
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
                    color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Profile photo',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _OptionTile(
                  isDarkMode: widget.isDarkMode,
                  icon: HugeIcons.strokeRoundedImage01,
                  title: 'Choose from gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromGallery();
                  },
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  isDarkMode: widget.isDarkMode,
                  icon: HugeIcons.strokeRoundedCamera01,
                  title: 'Take a photo',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromCamera();
                  },
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(height: 12),
                  _OptionTile(
                    isDarkMode: widget.isDarkMode,
                    icon: HugeIcons.strokeRoundedDelete02,
                    title: 'Remove photo',
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _removePhoto();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final outerColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    final innerColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);

    return Column(
      children: [
        GestureDetector(
          onTap: _showOptions,
          child: Stack(
            children: [
              Container(
                height: 104,
                width: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: outerColor,
                ),
                child: Center(
                  child: Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: innerColor,
                    ),
                    child: ClipOval(
                      child: _selectedImage != null
                          ? Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedUser,
                                color: widget.isDarkMode
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.black.withOpacity(0.7),
                                size: 28,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isDarkMode
                        ? const Color(0xFFD9D9D9)
                        : const Color(0xFF202020),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCamera01,
                      color: widget.isDarkMode ? Colors.black : Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to add profile photo',
          style: TextStyle(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.68)
                : Colors.black.withOpacity(0.68),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final bool isDarkMode;
  final dynamic icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _OptionTile({
    required this.isDarkMode,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ??
        (isDarkMode
            ? Colors.white.withOpacity(0.75)
            : Colors.black.withOpacity(0.75));

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
              color: itemColor,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: itemColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}