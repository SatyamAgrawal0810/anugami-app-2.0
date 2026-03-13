import 'dart:io';
import 'package:anu_app/api/services/profile_service.dart';
import 'package:anu_app/core/models/profile_model.dart';
import 'package:anu_app/presentation/pages/shared/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/utils/app_notifications.dart';
import 'package:anu_app/config/theme.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileModel profile;

  const EditProfilePage({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _fullNameController;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;

  // Image related properties
  File? _selectedImageFile;
  bool _imageChanged = false;
  String? _currentImageUrl;

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChanges = false;

  final List<String> _genderOptions = ['male', 'female', 'other'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _selectedGender = widget.profile.gender;
    _selectedDateOfBirth = widget.profile.dateOfBirth != null
        ? DateTime.tryParse(widget.profile.dateOfBirth!)
        : null;
    _currentImageUrl = widget.profile.profilePicture;

    // Listen for changes to detect if form was modified
    _fullNameController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor, // Header background
              onPrimary: Colors.white, // Header text
              onSurface: Colors.black, // Calendar text
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _imageChanged = true;
          _hasChanges = true;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImageFile != null || _currentImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImageFile = null;
                      _currentImageUrl = null;
                      _imageChanged = true;
                      _hasChanges = true;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create a map of fields to update
      final updateData = <String, dynamic>{};

      // Only include fields that have changed
      if (_fullNameController.text.trim() != widget.profile.fullName) {
        updateData['full_name'] = _fullNameController.text.trim();
      }

      // Handle gender - only send if changed
      final originalGender = widget.profile.gender;
      if (_selectedGender != originalGender) {
        updateData['gender'] = _selectedGender;
      }

      // Handle date of birth - only send if changed
      final originalDob = widget.profile.dateOfBirth;
      final newDob = _selectedDateOfBirth != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!)
          : null;

      if (newDob != originalDob) {
        updateData['date_of_birth'] = newDob;
      }

      // Handle image if it was changed
      if (_imageChanged) {
        if (_selectedImageFile != null) {
          // If we have a new image file, we'll need to upload it
          print("Will upload new image: ${_selectedImageFile!.path}");
          updateData['profile_picture'] = _selectedImageFile;
        } else {
          // If image was removed, send null or empty to remove current image
          updateData['profile_picture'] = null;
        }
      }

      // If no changes were made, just return
      if (updateData.isEmpty) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to save'),
            backgroundColor: Colors.grey,
          ),
        );

        return;
      }

      print("Sending update with data: $updateData");
      final result =
          await _profileService.updateUserProfileWithImage(updateData);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Update successful
        if (!mounted) return;

        AppNotifications.showSuccess(context, 'Success message');

        context.pop(true); // Return true to indicate update successful
      } else {
        // Update failed
        print("Profile update failed: ${result['message']}");
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to update profile';
        });
      }
    } catch (e) {
      print("Exception during profile update: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Profile',
        showBackButton: true,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture with edit functionality
                Center(
                  child: Stack(
                    children: [
                      // The avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _selectedImageFile != null
                            ? FileImage(_selectedImageFile!)
                            : (_currentImageUrl != null
                                ? NetworkImage(_currentImageUrl!)
                                : null),
                        child: (_selectedImageFile == null &&
                                _currentImageUrl == null)
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),

                      // Edit button
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: _showImagePickerOptions,
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Display a message about tapping to change photo
                Center(
                  child: TextButton(
                    onPressed: _showImagePickerOptions,
                    child: const Text(
                      "Tap to change profile picture",
                      style: TextStyle(
                        color: Color(0xFFFEAF4E),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Display error message if any
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),

                // Full Name
                _buildFormLabel('Full Name', true),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _buildInputDecoration('Enter your full name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Date of Birth
                _buildFormLabel('Date of Birth', false),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDateOfBirth == null
                              ? 'Select date of birth'
                              : DateFormat('dd MMM yyyy')
                                  .format(_selectedDateOfBirth!),
                          style: TextStyle(
                            color: _selectedDateOfBirth == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Gender
                _buildFormLabel('Gender', false),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        hint: const Text('Select gender'),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue;
                            _hasChanges = true;
                          });
                        },
                        items: _genderOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value[0].toUpperCase() +
                                  value.substring(1), // Capitalize first letter
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _hasChanges && !_isLoading
                          ? AppTheme.primaryGradient
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade300,
                                Colors.grey.shade300,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed:
                          _hasChanges && !_isLoading ? _updateProfile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: LogoLoader(),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFEAF4E)),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}
