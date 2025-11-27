import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/page_transitions.dart';
import '../utils/ui_helpers.dart';
import '../utils/input_validators.dart';
import '../widgets/custom_input_fields.dart';
import '../widgets/location_selector.dart';
import '../widgets/section_title.dart';
import '../widgets/custom_dropdown.dart';
import 'therapist_dashboard_screen.dart';

class TherapistDetailsScreen extends StatefulWidget {
  const TherapistDetailsScreen({super.key});

  @override
  State<TherapistDetailsScreen> createState() => _TherapistDetailsScreenState();
}

class _TherapistDetailsScreenState extends State<TherapistDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qualificationsController =
      TextEditingController();
  final TextEditingController _licenseIdController = TextEditingController();
  final TextEditingController _experienceYearsController =
      TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _consultationFeeController =
      TextEditingController();

  // Form values
  String _selectedGender = '';
  final List<String> _selectedSpecializations = [];
  String _selectedAvailability = 'Weekdays (9 AM - 5 PM)';
  File? _profileImage;
  String? _selectedCountry;
  String? _selectedCity;

  // UI state
  bool _isSubmitting = false;
  bool _isLoading = true;

  // Dropdown options
  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  final List<String> _specializationOptions = [
    'Anxiety Disorders',
    'Depression',
    'Child Therapy',
    'Cognitive Behavioral Therapy (CBT)',
    'Marriage & Family Therapy',
    'Trauma Therapy',
    'Addiction Counseling',
    'Grief Counseling',
    'Behavioral Therapy',
    'Psychoanalysis',
    'Group Therapy',
    'Art Therapy',
    'Other',
  ];

  final List<String> _availabilityOptions = [
    'Weekdays (9 AM - 5 PM)',
    'Weekends (10 AM - 4 PM)',
    'Evenings (5 PM - 9 PM)',
    'Flexible Hours',
    'By Appointment Only',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _qualificationsController.dispose();
    _licenseIdController.dispose();
    _experienceYearsController.dispose();
    _bioController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Try to load existing therapist data
      final existingData = await Supabase.instance.client
          .from('therapists')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (existingData != null && mounted) {
        setState(() {
          _firstNameController.text = existingData['first_name'] ?? '';
          _lastNameController.text = existingData['last_name'] ?? '';
          _phoneController.text = existingData['phone'] ?? '';
          _selectedGender = existingData['gender'] ?? '';
          _selectedCountry = existingData['country'];
          _selectedCity = existingData['city'];
          _qualificationsController.text = existingData['qualifications'] ?? '';
          _licenseIdController.text = existingData['license_id'] ?? '';
          _experienceYearsController.text =
              existingData['experience_years']?.toString() ?? '';
          _bioController.text = existingData['bio'] ?? '';
          _consultationFeeController.text =
              existingData['consultation_fee']?.toString() ?? '';

          // Parse specializations array
          if (existingData['specialization'] != null) {
            final List<dynamic> specializations =
                existingData['specialization'];
            _selectedSpecializations.clear();
            _selectedSpecializations.addAll(specializations.cast<String>());
          }

          // Parse availability
          if (existingData['availability'] != null &&
              existingData['availability']['schedule'] != null) {
            _selectedAvailability = existingData['availability']['schedule'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading existing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      const SizedBox(height: 16),
                      const Text(
                        'Professional Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share your expertise and background',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Profile Picture Section
                      Center(child: _buildProfilePictureSection()),
                      const SizedBox(height: 48),

                      // Personal Details Section
                      const SectionTitle(title: 'Personal Information'),
                      const SizedBox(height: 24),
                      _buildPersonalDetailsSection(),
                      const SizedBox(height: 32),

                      // Professional Details Section
                      const SectionTitle(title: 'Professional Information'),
                      const SizedBox(height: 24),
                      _buildProfessionalDetailsSection(),
                      const SizedBox(height: 32),

                      // Specialization Section
                      const SectionTitle(title: 'Specializations'),
                      const SizedBox(height: 24),
                      _buildSpecializationSection(),
                      const SizedBox(height: 32),

                      // Experience Section
                      const SectionTitle(title: 'Experience & Qualifications'),
                      const SizedBox(height: 24),
                      _buildExperienceSection(),
                      const SizedBox(height: 32),

                      // About Section
                      const SectionTitle(title: 'About You'),
                      const SizedBox(height: 24),
                      _buildAboutSection(),
                      const SizedBox(height: 32),

                      // Practice Details Section
                      const SectionTitle(title: 'Practice Details'),
                      const SizedBox(height: 24),
                      _buildPracticeDetailsSection(),
                      const SizedBox(height: 48),

                      // Submit Button
                      _buildSubmitButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF3F4F6),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: _profileImage != null
                      ? DecorationImage(
                          image: FileImage(_profileImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profileImage == null
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF9CA3AF),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Upload Professional Photo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NameInputField(
          controller: _firstNameController,
          label: 'First Name',
          hintText: 'Enter your first name',
        ),
        const SizedBox(height: 20),
        NameInputField(
          controller: _lastNameController,
          label: 'Last Name',
          hintText: 'Enter your last name',
        ),
        const SizedBox(height: 20),
        CustomDropdown<String>(
          label: 'Gender',
          value: _selectedGender.isEmpty ? null : _selectedGender,
          items: _genderOptions,
          itemLabelBuilder: (item) => item,
          hintText: 'Select your gender',
          onChanged: (value) {
            setState(() {
              _selectedGender = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Gender is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        PhoneInputField(
          controller: _phoneController,
          label: 'Phone Number',
          hintText: 'Enter your contact number',
        ),
        const SizedBox(height: 20),
        LocationSelector(
          initialCountry: _selectedCountry,
          initialCity: _selectedCity,
          onLocationChanged: (country, city) {
            setState(() {
              _selectedCountry = country;
              _selectedCity = city;
            });
          },
          validator: (value) {
            if (_selectedCountry == null || _selectedCity == null) {
              return 'Please select both country and city';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfessionalDetailsSection() {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'License/Certification ID *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _licenseIdController,
              validator: (value) => InputValidators.validateLicenseId(value),
              inputFormatters: [
                InputFormatters.licenseFormatter,
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: InputDecoration(
                hintText: 'Enter your professional license number',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        NumberInputField(
          controller: _experienceYearsController,
          label: 'Years of Experience',
          hintText: 'e.g., 5',
          maxLength: 2,
          suffixText: 'years',
          validator: (value) => InputValidators.validateExperienceYears(value),
        ),
      ],
    );
  }

  Widget _buildSpecializationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Specializations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _specializationOptions.map((specialization) {
            final isSelected = _selectedSpecializations.contains(
              specialization,
            );
            return FilterChip(
              label: Text(
                specialization,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedSpecializations.add(specialization);
                  } else {
                    _selectedSpecializations.remove(specialization);
                  }
                });
              },
              selectedColor: const Color(0xFF10B981),
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : const Color(0xFFE5E7EB),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            );
          }).toList(),
        ),
        if (_selectedSpecializations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one specialization',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qualifications *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _qualificationsController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Qualifications are required';
            }
            if (value.trim().length < 10) {
              return 'Please provide more detailed qualifications (at least 10 characters)';
            }
            return null;
          },
          maxLines: 3,
          inputFormatters: [LengthLimitingTextInputFormatter(300)],
          decoration: InputDecoration(
            hintText:
                'e.g., Ph.D. in Clinical Psychology, University of XYZ, 2015',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bio/About *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioController,
              validator: (value) => InputValidators.validateBio(value),
              maxLines: 5,
              onChanged: (value) {
                setState(() {
                  // Update character count
                });
              },
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              decoration: InputDecoration(
                hintText:
                    'Tell patients about yourself, your approach to therapy...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_bioController.text.length}/500',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeDetailsSection() {
    return Column(
      children: [
        NumberInputField(
          controller: _consultationFeeController,
          label: 'Consultation Fee',
          hintText: 'e.g., 2000',
          maxLength: 6,
          suffixText: 'PKR',
          validator: (value) => InputValidators.validateConsultationFee(value),
        ),
        const SizedBox(height: 20),
        CustomDropdown<String>(
          label: 'Availability',
          value: _selectedAvailability,
          items: _availabilityOptions,
          itemLabelBuilder: (item) => item,
          hintText: 'Select availability',
          onChanged: (value) {
            setState(() {
              _selectedAvailability = value ?? 'Weekdays (9 AM - 5 PM)';
            });
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Save & Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      _showMessage('Error selecting image: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSpecializations.isEmpty ||
        _selectedCountry == null ||
        _selectedCity == null) {
      _showMessage('Please fill in all required fields');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showMessage('User not authenticated');
        return;
      }

      // Upload profile image if selected
      String? profilePicUrl;
      if (_profileImage != null) {
        try {
          profilePicUrl = await _uploadProfileImage(user.id);
        } catch (e) {
          debugPrint('Error uploading image: $e');
          // Continue without image if upload fails
        }
      }

      // Create therapist record
      await _createTherapistRecord(user.id, profilePicUrl);

      // Show success message
      if (mounted) {
        _showMessage('Profile saved successfully!', isError: false);
      }

      // Wait a moment
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to therapist dashboard
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CustomPageTransitions.fadeTransition<void>(
            const TherapistDashboardScreen(),
          ),
          (route) => false,
        );
      }
    } catch (error) {
      _showMessage('Error saving profile: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<String> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return '';

    final fileName = 'therapist_profile_$userId.jpg';
    final bytes = await _profileImage!.readAsBytes();

    await Supabase.instance.client.storage
        .from('therapist-profiles')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    return Supabase.instance.client.storage
        .from('therapist-profiles')
        .getPublicUrl(fileName);
  }

  Future<void> _createTherapistRecord(
    String userId,
    String? profilePicUrl,
  ) async {
    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
    final location = '$_selectedCountry, $_selectedCity';

    // Insert into therapists table
    final therapistData = {
      'id': userId,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'full_name': fullName,
      'gender': _selectedGender,
      'phone': _phoneController.text.trim(),
      'country': _selectedCountry,
      'city': _selectedCity,
      'location': location,
      'qualifications': _qualificationsController.text.trim(),
      'specialization': _selectedSpecializations,
      'experience_years': int.tryParse(_experienceYearsController.text.trim()),
      'license_id': _licenseIdController.text.trim(),
      'bio': _bioController.text.trim(),
      'consultation_fee': int.tryParse(_consultationFeeController.text.trim()),
      'availability': {'schedule': _selectedAvailability},
      'profile_pic_url': profilePicUrl,
      'is_verified': true, // Mark as verified when profile is complete
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    debugPrint('[SAVE DEBUG] Saving therapist data: $therapistData');

    await Supabase.instance.client.from('therapists').upsert(therapistData);

    debugPrint(
      '[SAVE DEBUG] Therapist profile saved successfully with is_verified: true',
    );

    // Update the profiles table
    final profileData = {
      'full_name': fullName,
      'phone_number': _phoneController.text.trim(),
      'avatar_url': profilePicUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await Supabase.instance.client
        .from('profiles')
        .update(profileData)
        .eq('id', userId);
  }

  void _showMessage(String message, {bool isError = true}) {
    UIHelpers.showMessage(context, message, isError: isError);
  }
}
