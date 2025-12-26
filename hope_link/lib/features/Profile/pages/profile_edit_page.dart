import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hope_link/core/theme/app_colors.dart';
import 'package:hope_link/core/theme/app_text_styles.dart';
import 'package:hope_link/core/widgets/app_button.dart';
import 'package:hope_link/core/widgets/app_text_field.dart';
import 'package:hope_link/features/Profile/controllers/profile_controller.dart';
import 'package:hope_link/features/Profile/controllers/profile_image_controller.dart';
import 'package:hope_link/features/Profile/controllers/profile_cv_controller.dart';

class ProfileEditPage extends StatefulWidget {
  final String token;

  const ProfileEditPage({super.key, required this.token});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;

  final _genderOptions = ['male', 'female', 'other'];
  String _selectedGender = 'male';

  final _availableInterests = [
    'Education',
    'Healthcare',
    'Environment',
    'Animal Welfare',
    'Community Development',
    'Youth Empowerment',
    'Elderly Care',
    'Poverty Alleviation',
    'Disaster Relief',
    'Arts & Culture',
  ];
  final List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    final controller = Get.find<ProfileController>();
    final user = controller.user.value;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _countryController = TextEditingController(
      text: user?.location.country ?? '',
    );
    _cityController = TextEditingController(text: user?.location.city ?? '');
    _addressController = TextEditingController(
      text: user?.location.address ?? '',
    );

    if (user?.gender.isNotEmpty ?? false) {
      _selectedGender = user!.gender;
    }

    _selectedInterests.addAll(user?.interest ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    Get.put(ProfileImageController(widget.token));
    Get.put(ProfileCVController(widget.token));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
      
        backgroundColor: AppColorToken.primary.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Edit Profile',
          style: AppTextStyle.h4.bold.copyWith(color: Colors.white),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isLoading.value ? null : _saveProfile,
              child: Text(
                'Save',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileImageSection(),
            const SizedBox(height: 24),
            _buildBasicInfoSection(),
            const SizedBox(height: 16),
            _buildLocationSection(),
            const SizedBox(height: 16),
            _buildBioSection(),
            const SizedBox(height: 16),
            _buildInterestsSection(),
            const SizedBox(height: 16),
            _buildDocumentsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    final controller = Get.find<ProfileController>();
    final imageController = Get.find<ProfileImageController>();
    final user = controller.user.value;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColorToken.primary.color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      child: Column(
        children: [
          Stack(
            children: [
              Hero(
                tag: 'profile_image',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: user?.profileImage.isNotEmpty ?? false
                        ? NetworkImage(user!.profileImage)
                        : null,
                    child: user?.profileImage.isEmpty ?? true
                        ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Obx(
                  () => imageController.uploading.value
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColorToken.primary.color,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColorToken.primary.color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to change profile photo',
            style: AppTextStyle.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppColorToken.primary.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text('Basic Information', style: AppTextStyle.h4.bold),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Name is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildGenderDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: AppColorToken.primary.color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('Location', style: AppTextStyle.h4.bold),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Country',
            controller: _countryController,
            icon: Icons.flag_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'City',
            controller: _cityController,
            icon: Icons.location_city_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Address',
            controller: _addressController,
            icon: Icons.home_rounded,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: AppColorToken.primary.color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('Bio', style: AppTextStyle.h4.bold),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Tell us about yourself',
            controller: _bioController,
            icon: Icons.edit_rounded,
            maxLines: 4,
            hintText:
                'Share your story, motivation, or what drives you to help others...',
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                color: AppColorToken.primary.color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('Interests', style: AppTextStyle.h4.bold),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select causes you care about',
            style: AppTextStyle.bodySmall.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColorToken.primary.color
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColorToken.primary.color
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      Text(
                        interest,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final cvController = Get.find<ProfileCVController>();
    final controller = Get.find<ProfileController>();
    final user = controller.user.value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_rounded,
                color: AppColorToken.primary.color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('Documents', style: AppTextStyle.h4.bold),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => _buildDocumentUpload(
              label: 'CV / Resume',
              icon: Icons.description_rounded,
              hasDocument: user?.cv.isNotEmpty ?? false,
              isUploading: cvController.uploading.value,
              onTap: _pickCV,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText ?? label,
            prefixIcon: Icon(icon, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColorToken.primary.color,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: AppTextStyle.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.wc_rounded, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColorToken.primary.color,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: _genderOptions.map((gender) {
            return DropdownMenuItem(value: gender, child: Text(gender));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDocumentUpload({
    required String label,
    required IconData icon,
    required bool hasDocument,
    required bool isUploading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDocument
                ? AppColorToken.primary.color.withValues(alpha: 0.3)
                : Colors.grey[200]!,
            width: hasDocument ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasDocument
                    ? AppColorToken.primary.color.withValues(alpha: 0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: hasDocument
                    ? AppColorToken.primary.color
                    : Colors.grey[400],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyle.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUploading
                        ? 'Uploading...'
                        : hasDocument
                        ? 'Uploaded - Tap to change'
                        : 'Tap to upload',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: isUploading
                          ? AppColorToken.primary.color
                          : hasDocument
                          ? Colors.green[700]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isUploading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColorToken.primary.color,
                ),
              )
            else if (hasDocument)
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green[600],
                size: 24,
              )
            else
              Icon(
                Icons.upload_file_rounded,
                color: AppColorToken.primary.color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final imageController = Get.find<ProfileImageController>();
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      await imageController.upload(File(image.path));
    }
  }

  Future<void> _pickCV() async {
    final cvController = Get.find<ProfileCVController>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      await cvController.upload(File(result.files.single.path!));
      // Refresh profile to update CV status
      final controller = Get.find<ProfileController>();
      await controller.fetchProfile();
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<ProfileController>();

    final body = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'gender': _selectedGender,
      'bio': _bioController.text.trim(),
      'location': {
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
      },
      'interest': _selectedInterests,
    };

    await controller.updateProfile(body);
    Get.back();
  }
}
