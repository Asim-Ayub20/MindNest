class Therapist {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? gender;
  final String? phone;
  final String? country;
  final String? city;
  final String? location;
  final List<String> specializations;
  final String qualifications;
  final String licenseId;
  final int experienceYears;
  final String? bio;
  final int consultationFee;
  final Map<String, dynamic>? availability;
  final String? profilePicUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Therapist({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.gender,
    this.phone,
    this.country,
    this.city,
    this.location,
    required this.specializations,
    required this.qualifications,
    required this.licenseId,
    required this.experienceYears,
    this.bio,
    required this.consultationFee,
    this.availability,
    this.profilePicUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Therapist.fromJson(Map<String, dynamic> json) {
    return Therapist(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      gender: json['gender'],
      phone: json['phone'],
      country: json['country'],
      city: json['city'],
      location: json['location'],
      specializations: json['specialization'] != null
          ? List<String>.from(json['specialization'])
          : [],
      qualifications: json['qualifications'] ?? '',
      licenseId: json['license_id'] ?? '',
      experienceYears: json['experience_years'] ?? 0,
      bio: json['bio'],
      consultationFee: json['consultation_fee'] ?? 0,
      availability: json['availability'],
      profilePicUrl: json['profile_pic_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'gender': gender,
      'phone': phone,
      'country': country,
      'city': city,
      'location': location,
      'specialization': specializations,
      'qualifications': qualifications,
      'license_id': licenseId,
      'experience_years': experienceYears,
      'bio': bio,
      'consultation_fee': consultationFee,
      'availability': availability,
      'profile_pic_url': profilePicUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for display
  String get displayName =>
      fullName.isNotEmpty ? fullName : '$firstName $lastName';

  String get displayLocation => location ?? '';

  String get primarySpecialization =>
      specializations.isNotEmpty ? specializations.first : 'General';

  String get experienceText => '$experienceYears+ years';

  String get feeText =>
      consultationFee > 0 ? 'Rs. $consultationFee' : 'Contact for fees';

  bool get hasProfilePic => profilePicUrl != null && profilePicUrl!.isNotEmpty;

  // Search and filter helper methods
  bool matchesSearchQuery(String query) {
    if (query.isEmpty) return true;

    final searchLower = query.toLowerCase();
    return fullName.toLowerCase().contains(searchLower) ||
        firstName.toLowerCase().contains(searchLower) ||
        lastName.toLowerCase().contains(searchLower) ||
        specializations.any(
          (spec) => spec.toLowerCase().contains(searchLower),
        ) ||
        bio?.toLowerCase().contains(searchLower) == true ||
        qualifications.toLowerCase().contains(searchLower) ||
        location?.toLowerCase().contains(searchLower) == true;
  }

  bool matchesSpecializations(List<String> selectedSpecializations) {
    if (selectedSpecializations.isEmpty) return true;
    return specializations.any(
      (spec) => selectedSpecializations.contains(spec),
    );
  }

  bool matchesLocation(String? selectedLocation) {
    if (selectedLocation == null || selectedLocation.isEmpty) return true;
    return location?.toLowerCase().contains(selectedLocation.toLowerCase()) ==
            true ||
        country?.toLowerCase().contains(selectedLocation.toLowerCase()) ==
            true ||
        city?.toLowerCase().contains(selectedLocation.toLowerCase()) == true;
  }

  bool matchesFeeRange(int? minFee, int? maxFee) {
    if (minFee == null && maxFee == null) return true;
    if (minFee != null && consultationFee < minFee) return false;
    if (maxFee != null && consultationFee > maxFee) return false;
    return true;
  }

  bool matchesExperienceRange(int? minExperience, int? maxExperience) {
    if (minExperience == null && maxExperience == null) return true;
    if (minExperience != null && experienceYears < minExperience) return false;
    if (maxExperience != null && experienceYears > maxExperience) return false;
    return true;
  }

  bool matchesRating(double? minRating) {
    // Since rating doesn't exist in current schema, always return true
    // TODO: Implement when rating system is added
    return true;
  }

  @override
  String toString() {
    return 'Therapist(id: $id, name: $displayName, specializations: $specializations)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Therapist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
