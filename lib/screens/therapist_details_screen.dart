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
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Professional Profile'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome message
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.psychology,
                              size: 48,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Complete Your Professional Profile',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Help patients find the right therapist by sharing your professional background and expertise.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Profile Picture Section
                      _buildProfilePictureSection(),
                      const SizedBox(height: 24),

                      // Personal Details Section
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 16),
                      _buildPersonalDetailsSection(),
                      const SizedBox(height: 24),

                      // Professional Details Section
                      _buildSectionTitle('Professional Information'),
                      const SizedBox(height: 16),
                      _buildProfessionalDetailsSection(),
                      const SizedBox(height: 24),

                      // Specialization Section
                      _buildSectionTitle('Specializations'),
                      const SizedBox(height: 16),
                      _buildSpecializationSection(),
                      const SizedBox(height: 24),

                      // Experience Section
                      _buildSectionTitle('Experience & Qualifications'),
                      const SizedBox(height: 16),
                      _buildExperienceSection(),
                      const SizedBox(height: 24),

                      // About Section
                      _buildSectionTitle('About You'),
                      const SizedBox(height: 16),
                      _buildAboutSection(),
                      const SizedBox(height: 24),

                      // Practice Details Section
                      _buildSectionTitle('Practice Details'),
                      const SizedBox(height: 16),
                      _buildPracticeDetailsSection(),
                      const SizedBox(height: 40),

                      // Submit Button
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF3F4F6),
                border: Border.all(color: const Color(0xFF10B981), width: 3),
              ),
              child: _profileImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.file(
                        _profileImage!,
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                      ),
                    )
                  : const Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Color(0xFF10B981),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _profileImage != null
                ? 'Tap to change photo'
                : 'Add Professional Photo (Optional)',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
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
          _buildGenderDropdown(),
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
      ),
    );
  }

  Widget _buildProfessionalDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'License/Certification ID *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
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
                    vertical: 12,
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
            validator: (value) =>
                InputValidators.validateExperienceYears(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Specializations',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
                    fontSize: 12,
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
                  borderRadius: BorderRadius.circular(8),
                ),
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
      ),
    );
  }

  Widget _buildExperienceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Qualifications *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
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
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bio/About *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
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
      ),
    );
  }

  Widget _buildPracticeDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          NumberInputField(
            controller: _consultationFeeController,
            label: 'Consultation Fee',
            hintText: 'e.g., 2000',
            maxLength: 6,
            suffixText: 'PKR',
            validator: (value) =>
                InputValidators.validateConsultationFee(value),
          ),
          const SizedBox(height: 20),
          _buildAvailabilityDropdown(),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender.isEmpty ? null : _selectedGender,
          decoration: InputDecoration(
            hintText: 'Select your gender',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Gender is required';
            }
            return null;
          },
          items: _genderOptions.map((gender) {
            return DropdownMenuItem<String>(value: gender, child: Text(gender));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value ?? '';
            });
          },
        ),
      ],
    );
  }

  Widget _buildAvailabilityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Availability',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedAvailability,
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: _availabilityOptions.map((availability) {
            return DropdownMenuItem<String>(
              value: availability,
              child: Text(availability),
            );
          }).toList(),
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
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Save & Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      if (_selectedSpecializations.isEmpty) {
        _showMessage('Please select at least one specialization');
      } else if (_selectedCountry == null || _selectedCity == null) {
        _showMessage('Please select both country and city');
      } else {
        _showMessage('Please fill in all required fields');
      }
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

      // Create therapists table entry
      debugPrint('Creating therapist record for user: ${user.id}');
      await _createTherapistRecord(user.id, profilePicUrl);
      debugPrint('Therapist record created successfully');

      // Show success message
      if (mounted) {
        _showMessage('Profile saved successfully!', isError: false);
      }

      // Wait a moment to show the success message
      await Future.delayed(Duration(milliseconds: 500));

      // Navigate to therapist dashboard screen
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

    await Supabase.instance.client.from('therapists').upsert({
      'id': userId,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'full_name': fullName,
      'gender': _selectedGender,
      'phone': _phoneController.text.trim(),
      'country': _selectedCountry,
      'city': _selectedCity,
      'location': location,
      'specialization': _selectedSpecializations,
      'qualifications': _qualificationsController.text.trim(),
      'license_id': _licenseIdController.text.trim(),
      'experience_years': int.parse(_experienceYearsController.text.trim()),
      'bio': _bioController.text.trim(),
      'consultation_fee': int.parse(_consultationFeeController.text.trim()),
      'availability': {'schedule': _selectedAvailability},
      'profile_pic_url': profilePicUrl,
    });

    // Update the profiles table with additional info
    await Supabase.instance.client
        .from('profiles')
        .update({
          'full_name': fullName,
          'phone_number': _phoneController.text.trim(),
          'avatar_url': profilePicUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);

    // Mark onboarding as complete - matching patient flow exactly
    try {
      // Check if onboarding record exists
      final existingOnboarding = await Supabase.instance.client
          .from('user_onboarding')
          .select('id, onboarding_type, user_id')
          .eq('user_id', userId)
          .maybeSingle();

      debugPrint('Existing onboarding record: $existingOnboarding');

      if (existingOnboarding != null) {
        // Update existing record
        await Supabase.instance.client
            .from('user_onboarding')
            .update({
              'current_step': 'completed',
              'progress_percentage': 100,
              'onboarding_1_completed': true,
              'onboarding_2_completed': true,
              'onboarding_3_completed': true,
              'onboarding_4_completed': true,
              'completed_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        // Insert new record if it doesn't exist (fallback)
        await Supabase.instance.client.from('user_onboarding').insert({
          'user_id': userId,
          'onboarding_type': 'therapist',
          'current_step': 'completed',
          'progress_percentage': 100,
          'user_type_selected': true,
          'account_created': true,
          'onboarding_1_completed': true,
          'onboarding_2_completed': true,
          'onboarding_3_completed': true,
          'onboarding_4_completed': true,
          'completed_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (onboardingError) {
      debugPrint('Error with onboarding record: $onboardingError');
      // Try to create the record as a fallback
      try {
        await Supabase.instance.client.from('user_onboarding').insert({
          'user_id': userId,
          'onboarding_type': 'therapist',
          'current_step': 'completed',
          'progress_percentage': 100,
          'user_type_selected': true,
          'account_created': true,
          'onboarding_1_completed': true,
          'onboarding_2_completed': true,
          'onboarding_3_completed': true,
          'onboarding_4_completed': true,
          'completed_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (insertError) {
        debugPrint('Failed to insert onboarding record: $insertError');
        throw Exception('Could not create onboarding record: $insertError');
      }
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    UIHelpers.showMessage(context, message, isError: isError);
  }
}
