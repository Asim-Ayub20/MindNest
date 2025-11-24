import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/app_theme.dart';
import '../../widgets/location_selector.dart';

class PatientProfileTab extends StatefulWidget {
  const PatientProfileTab({super.key});

  @override
  State<PatientProfileTab> createState() => _PatientProfileTabState();
}

class _PatientProfileTabState extends State<PatientProfileTab> {
  // Profile data
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers for editing
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyFirstNameController = TextEditingController();
  final _emergencyLastNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // Selected values
  String? _selectedGender;
  String? _selectedLanguage;
  String? _selectedCountry;
  String? _selectedCity;
  DateTime? _dateOfBirth;
  File? _profileImage;

  // Form key
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
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

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Load profile data (for future use if needed)
      await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      // Load patient-specific data
      final patientResponse = await Supabase.instance.client
          .from('patients')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _patientData = patientResponse;
        _isLoading = false;
        _populateFormFields();
      });
    } catch (error) {
      debugPrint('Error loading profile data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFormFields() {
    if (_patientData != null) {
      _firstNameController.text = _patientData!['first_name'] ?? '';
      _lastNameController.text = _patientData!['last_name'] ?? '';
      _phoneController.text = _patientData!['phone'] ?? '';
      _emergencyFirstNameController.text =
          _patientData!['emergency_first_name'] ?? '';
      _emergencyLastNameController.text =
          _patientData!['emergency_last_name'] ?? '';
      _emergencyPhoneController.text = _patientData!['emergency_phone'] ?? '';

      _selectedGender = _patientData!['gender'];
      _selectedLanguage = _patientData!['preferred_lang'];
      _selectedCountry = _patientData!['country'];
      _selectedCity = _patientData!['city'];

      if (_patientData!['dob'] != null) {
        _dateOfBirth = DateTime.parse(_patientData!['dob']);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload profile image if selected
      String? profilePicUrl;
      if (_profileImage != null) {
        profilePicUrl = await _uploadProfileImage(user.id);
      }

      // Update patient data
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final emergencyName =
          '${_emergencyFirstNameController.text.trim()} ${_emergencyLastNameController.text.trim()}';
      final location = '$_selectedCountry, $_selectedCity';

      await Supabase.instance.client
          .from('patients')
          .update({
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'full_name': fullName,
            'dob': _dateOfBirth?.toIso8601String().split('T')[0],
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
            if (profilePicUrl != null) 'profile_pic_url': profilePicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Update profiles table
      await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': fullName,
            'phone_number': _phoneController.text.trim(),
            'date_of_birth': _dateOfBirth?.toIso8601String().split('T')[0],
            if (profilePicUrl != null) 'avatar_url': profilePicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      _showMessage('Profile updated successfully!', isError: false);
      await _loadProfileData(); // Reload data
      setState(() {
        _isEditing = false;
        _profileImage = null;
      });
    } catch (error) {
      _showMessage('Error updating profile: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    // Clear any existing snackbars to prevent stacking
    ScaffoldMessenger.of(context).clearSnackBars();

    // Auto-dismiss after 4 seconds
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  Future<void> handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $error'),
            duration: const Duration(seconds: 4),
            dismissDirection: DismissDirection.horizontal,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                if (!_isEditing)
                  IconButton(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _isEditing ? _buildEditingView() : _buildProfileView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    final user = Supabase.instance.client.auth.currentUser;
    final userName =
        _patientData?['full_name'] ??
        user?.userMetadata?['full_name'] ??
        'User';
    final userEmail = user?.email ?? '';
    final profilePicUrl = _patientData?['profile_pic_url'];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
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
                Row(
                  children: [
                    // Profile Picture
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(38),
                        child: profilePicUrl != null
                            ? Image.network(
                                profilePicUrl,
                                fit: BoxFit.cover,
                                cacheWidth:
                                    160, // Cache at 2x resolution (80 * 2)
                                cacheHeight: 160,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: AppTheme.primaryGreen,
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                              )
                            : Container(
                                color: AppTheme.primaryGreen,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Patient',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Personal Information
          _buildInfoSection('Personal Information', [
            _buildInfoItem(
              'First Name',
              _patientData?['first_name'] ?? 'Not provided',
            ),
            _buildInfoItem(
              'Last Name',
              _patientData?['last_name'] ?? 'Not provided',
            ),
            _buildInfoItem('Date of Birth', _formatDate(_patientData?['dob'])),
            _buildInfoItem('Gender', _patientData?['gender'] ?? 'Not provided'),
            _buildInfoItem('Phone', _patientData?['phone'] ?? 'Not provided'),
          ]),

          const SizedBox(height: 16),

          // Location Information
          _buildInfoSection('Location', [
            _buildInfoItem(
              'Country',
              _patientData?['country'] ?? 'Not provided',
            ),
            _buildInfoItem('City', _patientData?['city'] ?? 'Not provided'),
          ]),

          const SizedBox(height: 16),

          // Preferences
          _buildInfoSection('Preferences', [
            _buildInfoItem(
              'Preferred Language',
              _patientData?['preferred_lang'] ?? 'Not provided',
            ),
          ]),

          const SizedBox(height: 16),

          // Emergency Contact
          _buildInfoSection('Emergency Contact', [
            _buildInfoItem(
              'First Name',
              _patientData?['emergency_first_name'] ?? 'Not provided',
            ),
            _buildInfoItem(
              'Last Name',
              _patientData?['emergency_last_name'] ?? 'Not provided',
            ),
            _buildInfoItem(
              'Phone',
              _patientData?['emergency_phone'] ?? 'Not provided',
            ),
          ]),

          const SizedBox(height: 24),

          // Logout Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.2),
              ),
            ),
            child: InkWell(
              onTap: () => handleLogout(context),
              borderRadius: BorderRadius.circular(12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: AppTheme.errorColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditingView() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(57),
                      child: _profileImage != null
                          ? Image.file(_profileImage!, fit: BoxFit.cover)
                          : _patientData?['profile_pic_url'] != null
                          ? Image.network(
                              _patientData!['profile_pic_url'],
                              fit: BoxFit.cover,
                              cacheWidth:
                                  240, // Cache at 2x resolution (120 * 2)
                              cacheHeight: 240,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppTheme.primaryGreen,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                  ),
                            )
                          : Container(
                              color: AppTheme.primaryGreen,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        onPressed: _pickProfileImage,
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Personal Information
            _buildEditSection('Personal Information', [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'First name is required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Last name is required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: const ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map(
                      (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
                validator: (value) =>
                    value == null ? 'Please select gender' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.lightText),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppTheme.secondaryText,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _dateOfBirth != null
                            ? _formatDate(
                                _dateOfBirth!.toIso8601String().split('T')[0],
                              )
                            : 'Select Date of Birth',
                        style: TextStyle(
                          color: _dateOfBirth != null
                              ? AppTheme.primaryText
                              : AppTheme.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Phone number is required'
                    : null,
              ),
            ]),

            const SizedBox(height: 24),

            // Location
            _buildEditSection('Location', [
              LocationSelector(
                initialCountry: _selectedCountry,
                initialCity: _selectedCity,
                onLocationChanged: (country, city) => setState(() {
                  _selectedCountry = country;
                  _selectedCity = city;
                }),
              ),
            ]),

            const SizedBox(height: 24),

            // Preferences
            _buildEditSection('Preferences', [
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguage,
                decoration: const InputDecoration(
                  labelText: 'Preferred Language',
                  border: OutlineInputBorder(),
                ),
                items: const ['English', 'Urdu', 'Roman Urdu']
                    .map(
                      (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedLanguage = value),
                validator: (value) =>
                    value == null ? 'Please select language' : null,
              ),
            ]),

            const SizedBox(height: 24),

            // Emergency Contact
            _buildEditSection('Emergency Contact', [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emergencyFirstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Contact First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Emergency contact first name is required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emergencyLastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Contact Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Emergency contact last name is required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Emergency contact phone is required'
                    : null,
              ),
            ]),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _profileImage = null;
                        _populateFormFields(); // Reset form
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.secondaryText),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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

  Widget _buildEditSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not provided';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Not provided';
    }
  }
}
