import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_input_fields.dart';
import '../../widgets/location_selector.dart';
import '../../utils/page_transitions.dart';
import '../login_screen.dart';

class TherapistProfileTab extends StatefulWidget {
  const TherapistProfileTab({super.key});

  @override
  State<TherapistProfileTab> createState() => _TherapistProfileTabState();
}

class _TherapistProfileTabState extends State<TherapistProfileTab> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _therapistData;
  File? _newProfileImage;

  // Form controllers
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

  String _selectedGender = '';
  final List<String> _selectedSpecializations = [];
  String? _selectedCountry;
  String? _selectedCity;
  String _selectedAvailability = 'Weekdays (9 AM - 5 PM)';

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
    _loadTherapistData();
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

  Future<void> _loadTherapistData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await Supabase.instance.client
          .from('therapists')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _therapistData = data;
          _populateFormFields(data);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading therapist data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _populateFormFields(Map<String, dynamic> data) {
    _firstNameController.text = data['first_name'] ?? '';
    _lastNameController.text = data['last_name'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _selectedGender = data['gender'] ?? '';
    _selectedCountry = data['country'];
    _selectedCity = data['city'];
    _qualificationsController.text = data['qualifications'] ?? '';
    _licenseIdController.text = data['license_id'] ?? '';
    _experienceYearsController.text =
        data['experience_years']?.toString() ?? '';
    _bioController.text = data['bio'] ?? '';
    _consultationFeeController.text =
        data['consultation_fee']?.toString() ?? '';

    if (data['specialization'] != null) {
      final List<dynamic> specializations = data['specialization'];
      _selectedSpecializations.clear();
      _selectedSpecializations.addAll(specializations.cast<String>());
    }

    if (data['availability'] != null &&
        data['availability']['schedule'] != null) {
      _selectedAvailability = data['availability']['schedule'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (!_isLoading && _therapistData != null)
            TextButton(
              onPressed: _isEditing ? _saveProfile : _toggleEdit,
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _therapistData == null
          ? _buildNoDataState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildPersonalInfoSection(),
                  const SizedBox(height: 20),
                  _buildProfessionalInfoSection(),
                  const SizedBox(height: 20),
                  _buildSpecializationsSection(),
                  const SizedBox(height: 20),
                  _buildExperienceSection(),
                  const SizedBox(height: 20),
                  _buildAboutSection(),
                  const SizedBox(height: 20),
                  _buildPracticeInfoSection(),
                  const SizedBox(height: 24),
                  _buildAccountActions(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: AppTheme.secondaryText),
          SizedBox(height: 16),
          Text(
            'Profile data not found',
            style: TextStyle(fontSize: 18, color: AppTheme.secondaryText),
          ),
          SizedBox(height: 8),
          Text(
            'Please complete your profile setup',
            style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final firstName = _therapistData?['first_name'] ?? '';
    final lastName = _therapistData?['last_name'] ?? '';
    final specializations =
        (_therapistData?['specialization'] as List<dynamic>?)?.cast<String>() ??
        [];
    final primarySpecialization = specializations.isNotEmpty
        ? specializations.first
        : 'Mental Health Professional';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: _newProfileImage != null
                    ? FileImage(_newProfileImage!)
                    : _therapistData?['profile_pic_url'] != null
                    ? NetworkImage(_therapistData!['profile_pic_url'])
                    : null,
                child:
                    _newProfileImage == null &&
                        _therapistData?['profile_pic_url'] == null
                    ? const Icon(Icons.person, color: Colors.white, size: 50)
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppTheme.primaryGreen,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dr. $firstName $lastName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            primarySpecialization,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip(
                '${_therapistData?['experience_years'] ?? 0} Years',
                'Experience',
              ),
              _buildStatChip(
                '\$${_therapistData?['consultation_fee'] ?? 0}',
                'Fee',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection('Personal Information', [
      if (_isEditing) ...[
        NameInputField(
          controller: _firstNameController,
          label: 'First Name',
          hintText: 'Enter your first name',
        ),
        const SizedBox(height: 16),
        NameInputField(
          controller: _lastNameController,
          label: 'Last Name',
          hintText: 'Enter your last name',
        ),
        const SizedBox(height: 16),
        _buildGenderDropdown(),
        const SizedBox(height: 16),
        PhoneInputField(
          controller: _phoneController,
          label: 'Phone Number',
          hintText: 'Enter your contact number',
        ),
        const SizedBox(height: 16),
        LocationSelector(
          initialCountry: _selectedCountry,
          initialCity: _selectedCity,
          onLocationChanged: (country, city) {
            setState(() {
              _selectedCountry = country;
              _selectedCity = city;
            });
          },
        ),
      ] else ...[
        _buildInfoRow(
          'Name',
          '${_therapistData?['first_name']} ${_therapistData?['last_name']}',
        ),
        _buildInfoRow('Gender', _therapistData?['gender'] ?? 'Not specified'),
        _buildInfoRow('Phone', _therapistData?['phone'] ?? 'Not specified'),
        _buildInfoRow(
          'Location',
          _therapistData?['country'] != null && _therapistData?['city'] != null
              ? '${_therapistData?['city']}, ${_therapistData?['country']}'
              : 'Not specified',
        ),
      ],
    ]);
  }

  Widget _buildProfessionalInfoSection() {
    return _buildSection('Professional Information', [
      if (_isEditing) ...[
        _buildTextField(
          controller: _licenseIdController,
          label: 'License ID',
          hintText: 'Enter your license number',
        ),
        const SizedBox(height: 16),
        NumberInputField(
          controller: _experienceYearsController,
          label: 'Years of Experience',
          hintText: 'e.g., 5',
          maxLength: 2,
          suffixText: 'years',
        ),
      ] else ...[
        _buildInfoRow(
          'License ID',
          _therapistData?['license_id'] ?? 'Not specified',
        ),
        _buildInfoRow(
          'Experience',
          '${_therapistData?['experience_years'] ?? 0} years',
        ),
      ],
    ]);
  }

  Widget _buildSpecializationsSection() {
    final specializations =
        (_therapistData?['specialization'] as List<dynamic>?)?.cast<String>() ??
        [];

    return _buildSection('Specializations', [
      if (_isEditing) ...[
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
                  color: isSelected ? Colors.white : AppTheme.primaryText,
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
              selectedColor: AppTheme.primaryGreen,
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
      ] else ...[
        if (specializations.isEmpty)
          const Text(
            'No specializations specified',
            style: TextStyle(color: AppTheme.secondaryText),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specializations
                .map(
                  (spec) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      spec,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    ]);
  }

  Widget _buildExperienceSection() {
    return _buildSection('Qualifications', [
      if (_isEditing)
        _buildTextField(
          controller: _qualificationsController,
          label: 'Qualifications',
          hintText: 'Enter your qualifications',
          maxLines: 3,
        )
      else
        Text(
          _therapistData?['qualifications'] ?? 'Not specified',
          style: const TextStyle(fontSize: 14, color: AppTheme.primaryText),
        ),
    ]);
  }

  Widget _buildAboutSection() {
    return _buildSection('About', [
      if (_isEditing)
        _buildTextField(
          controller: _bioController,
          label: 'Bio',
          hintText: 'Tell patients about yourself',
          maxLines: 4,
        )
      else
        Text(
          _therapistData?['bio'] ?? 'No bio provided',
          style: const TextStyle(fontSize: 14, color: AppTheme.primaryText),
        ),
    ]);
  }

  Widget _buildPracticeInfoSection() {
    return _buildSection('Practice Information', [
      if (_isEditing) ...[
        NumberInputField(
          controller: _consultationFeeController,
          label: 'Consultation Fee',
          hintText: 'e.g., 100',
          suffixText: 'USD',
        ),
        const SizedBox(height: 16),
        _buildAvailabilityDropdown(),
      ] else ...[
        _buildInfoRow(
          'Consultation Fee',
          '\$${_therapistData?['consultation_fee'] ?? 0}',
        ),
        _buildInfoRow(
          'Availability',
          _therapistData?['availability']?['schedule'] ?? 'Not specified',
        ),
      ],
    ]);
  }

  Widget _buildSection(String title, List<Widget> children) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppTheme.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppTheme.secondaryText),
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
                color: AppTheme.primaryGreen,
                width: 2,
              ),
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
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender.isEmpty ? null : _selectedGender,
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
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
          ),
          hint: const Text('Select gender'),
          items: _genderOptions
              .map(
                (gender) =>
                    DropdownMenuItem(value: gender, child: Text(gender)),
              )
              .toList(),
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
            color: AppTheme.primaryText,
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
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
          ),
          items: _availabilityOptions
              .map(
                (availability) => DropdownMenuItem(
                  value: availability,
                  child: Text(availability),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedAvailability = value ?? _selectedAvailability;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
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
            'Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out'),
            onTap: _signOut,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing && _therapistData != null) {
        _populateFormFields(_therapistData!);
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String? profilePicUrl;

      // Upload new profile image if selected
      if (_newProfileImage != null) {
        final fileName =
            '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('therapist-profiles')
            .upload(fileName, _newProfileImage!);

        profilePicUrl = Supabase.instance.client.storage
            .from('therapist-profiles')
            .getPublicUrl(fileName);
      }

      final updateData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'full_name':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'country': _selectedCountry,
        'city': _selectedCity,
        'location': _selectedCountry != null && _selectedCity != null
            ? '$_selectedCity, $_selectedCountry'
            : null,
        'qualifications': _qualificationsController.text.trim(),
        'license_id': _licenseIdController.text.trim(),
        'experience_years':
            int.tryParse(_experienceYearsController.text.trim()) ?? 0,
        'bio': _bioController.text.trim(),
        'consultation_fee':
            int.tryParse(_consultationFeeController.text.trim()) ?? 0,
        'specialization': _selectedSpecializations,
        'availability': {'schedule': _selectedAvailability},
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (profilePicUrl != null) {
        updateData['profile_pic_url'] = profilePicUrl;
      }

      await Supabase.instance.client
          .from('therapists')
          .update(updateData)
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 4),
            dismissDirection: DismissDirection.horizontal,
          ),
        );

        setState(() {
          _isEditing = false;
          _newProfileImage = null;
        });

        await _loadTherapistData();
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            dismissDirection: DismissDirection.horizontal,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _newProfileImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CustomPageTransitions.slideFromRight<void>(const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
