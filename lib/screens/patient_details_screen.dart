import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../utils/page_transitions.dart';
import '../utils/ui_helpers.dart';
import '../widgets/custom_input_fields.dart';
import '../widgets/location_selector.dart';
import 'patient_dashboard_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({super.key});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyFirstNameController =
      TextEditingController();
  final TextEditingController _emergencyLastNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  // Form values
  DateTime? _dateOfBirth;
  String _selectedGender = '';
  String _selectedLanguage = 'English';
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
  final List<String> _languageOptions = ['English', 'Urdu', 'Roman Urdu'];

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
    _emergencyFirstNameController.dispose();
    _emergencyLastNameController.dispose();
    _emergencyPhoneController.dispose();
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

      // Try to load existing patient data
      final existingData = await Supabase.instance.client
          .from('patients')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (existingData != null && mounted) {
        setState(() {
          _firstNameController.text = existingData['first_name'] ?? '';
          _lastNameController.text = existingData['last_name'] ?? '';
          _phoneController.text = existingData['phone'] ?? '';
          _selectedGender = existingData['gender'] ?? '';
          _selectedLanguage = existingData['preferred_lang'] ?? 'English';
          _selectedCountry = existingData['country'];
          _selectedCity = existingData['city'];
          _emergencyFirstNameController.text =
              existingData['emergency_first_name'] ?? '';
          _emergencyLastNameController.text =
              existingData['emergency_last_name'] ?? '';
          _emergencyPhoneController.text =
              existingData['emergency_phone'] ?? '';

          // Parse date of birth
          if (existingData['dob'] != null) {
            try {
              _dateOfBirth = DateTime.parse(existingData['dob']);
            } catch (e) {
              debugPrint('Error parsing date: $e');
            }
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
                        'Complete Your Profile',
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
                        'Tell us a bit about yourself to get started',
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
                      _buildSectionTitle('Personal Details'),
                      const SizedBox(height: 24),
                      _buildPersonalDetailsSection(),
                      const SizedBox(height: 32),

                      // Contact Information Section
                      _buildSectionTitle('Contact Information'),
                      const SizedBox(height: 24),
                      _buildContactSection(),
                      const SizedBox(height: 32),

                      // Preferences Section
                      _buildSectionTitle('Preferences'),
                      const SizedBox(height: 24),
                      _buildPreferencesSection(),
                      const SizedBox(height: 32),

                      // Emergency Contact Section
                      _buildSectionTitle('Emergency Contact'),
                      const SizedBox(height: 24),
                      _buildEmergencyContactSection(),
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

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 1,
          color: const Color(0xFFE5E7EB),
        ),
      ],
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
          'Upload Profile Photo',
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
        _buildDateField(),
        const SizedBox(height: 20),
        _buildGenderDropdown(),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        PhoneInputField(
          controller: _phoneController,
          label: 'Phone Number',
          hintText: 'Enter your phone number',
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

  Widget _buildPreferencesSection() {
    return _buildLanguageDropdown();
  }

  Widget _buildEmergencyContactSection() {
    return Column(
      children: [
        NameInputField(
          controller: _emergencyFirstNameController,
          label: 'Emergency Contact First Name',
          hintText: 'Enter first name',
        ),
        const SizedBox(height: 20),
        NameInputField(
          controller: _emergencyLastNameController,
          label: 'Emergency Contact Last Name',
          hintText: 'Enter last name',
        ),
        const SizedBox(height: 20),
        PhoneInputField(
          controller: _emergencyPhoneController,
          label: 'Emergency Contact Phone',
          hintText: 'Enter phone number',
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dateOfBirth != null
                        ? DateFormat('MMMM d, yyyy').format(_dateOfBirth!)
                        : 'Select your date of birth',
                    style: TextStyle(
                      fontSize: 15,
                      color: _dateOfBirth != null
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_dateOfBirth == null)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Date of birth is required',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
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
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender.isEmpty ? null : _selectedGender,
          decoration: InputDecoration(
            hintText: 'Select your gender',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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

  Widget _buildLanguageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred Language',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedLanguage,
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
              vertical: 14,
            ),
          ),
          items: _languageOptions.map((language) {
            return DropdownMenuItem<String>(
              value: language,
              child: Text(language),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLanguage = value ?? 'English';
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF10B981)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _dateOfBirth == null ||
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

      // Create patients table entry
      debugPrint('Creating patient record for user: ${user.id}');
      await _createPatientRecord(user.id, profilePicUrl);
      debugPrint('Patient record created successfully');

      // Show success message
      if (mounted) {
        _showMessage('Profile saved successfully!', isError: false);
      }

      // Wait a moment to show the success message
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to patient dashboard
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CustomPageTransitions.fadeTransition<void>(
            const PatientDashboardScreen(),
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

    final fileName = 'profile_$userId.jpg';
    final bytes = await _profileImage!.readAsBytes();

    await Supabase.instance.client.storage
        .from('patient-profiles')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    return Supabase.instance.client.storage
        .from('patient-profiles')
        .getPublicUrl(fileName);
  }

  Future<void> _createPatientRecord(
    String userId,
    String? profilePicUrl,
  ) async {
    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
    final emergencyName =
        '${_emergencyFirstNameController.text.trim()} ${_emergencyLastNameController.text.trim()}';
    final location = '$_selectedCountry, $_selectedCity';

    debugPrint('Inserting patient record with data: $fullName');

    // Insert into patients table
    final patientData = {
      'id': userId,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'full_name': fullName,
      'dob': _dateOfBirth!.toIso8601String().split('T')[0], // Format as date
      'gender': _selectedGender,
      'phone': _phoneController.text.trim(),
      'country': _selectedCountry,
      'city': _selectedCity,
      'location': location,
      'preferred_lang': _selectedLanguage,
      'emergency_first_name': _emergencyFirstNameController.text.trim(),
      'emergency_last_name': _emergencyLastNameController.text.trim(),
      'emergency_name': emergencyName,
      'emergency_phone': _emergencyPhoneController.text.trim(),
      'profile_pic_url': profilePicUrl,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await Supabase.instance.client.from('patients').upsert(patientData);
    debugPrint('Successfully inserted into patients table');

    // Update the profiles table with additional info
    final profileData = {
      'full_name': fullName,
      'phone_number': _phoneController.text.trim(),
      'date_of_birth': _dateOfBirth!.toIso8601String().split('T')[0],
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
