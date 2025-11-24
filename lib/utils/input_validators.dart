import 'package:flutter/services.dart';

class InputValidators {
  // Name validation - only letters and spaces
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    // Remove extra spaces and check if empty
    final trimmedValue = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmedValue.isEmpty) {
      return '$fieldName is required';
    }

    // Check for minimum length
    if (trimmedValue.length < 2) {
      return '$fieldName must be at least 2 characters long';
    }

    // Check for maximum length
    if (trimmedValue.length > 50) {
      return '$fieldName must be less than 50 characters';
    }

    // Only allow letters, spaces, apostrophes, and hyphens
    final nameRegex = RegExp(r"^[a-zA-Z\s'\-]+$");
    if (!nameRegex.hasMatch(trimmedValue)) {
      return '$fieldName can only contain letters, spaces, apostrophes and hyphens';
    }

    // Check that it doesn't start or end with space
    if (value.startsWith(' ') || value.endsWith(' ')) {
      return '$fieldName cannot start or end with spaces';
    }

    return null;
  }

  // Phone number validation - only numbers and specific characters
  static String? validatePhoneNumber(
    String? value, {
    String fieldName = 'Phone number',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final trimmedValue = value.trim();

    // Remove all non-digit characters to check length
    final digitsOnly = trimmedValue.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Please enter a valid $fieldName (at least 10 digits)';
    }

    if (digitsOnly.length > 15) {
      return '$fieldName cannot exceed 15 digits';
    }

    // Allow digits, spaces, hyphens, parentheses, and plus sign
    final phoneRegex = RegExp(r'^[\d\s\-\(\)\+]+$');
    if (!phoneRegex.hasMatch(trimmedValue)) {
      return '$fieldName can only contain numbers, spaces, hyphens, parentheses, and plus sign';
    }

    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final trimmedValue = value.trim().toLowerCase();

    // Check for spaces
    if (trimmedValue.contains(' ')) {
      return 'Email address cannot contain spaces';
    }

    // Check minimum length
    if (trimmedValue.length < 5) {
      return 'Email address is too short';
    }

    // Check maximum length
    if (trimmedValue.length > 254) {
      return 'Email address is too long';
    }

    // Comprehensive email regex that validates:
    // - Local part: alphanumeric, dots, hyphens, underscores
    // - Domain: alphanumeric with dots
    // - TLD: at least 2 characters
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid email address';
    }

    // Check for consecutive dots
    if (trimmedValue.contains('..')) {
      return 'Email address cannot contain consecutive dots';
    }

    // Check that local part (before @) doesn't start or end with a dot
    final parts = trimmedValue.split('@');
    if (parts.length != 2) {
      return 'Please enter a valid email address';
    }

    final localPart = parts[0];
    final domainPart = parts[1];

    if (localPart.startsWith('.') || localPart.endsWith('.')) {
      return 'Email address cannot start or end with a dot';
    }

    // Check that domain has at least one dot
    if (!domainPart.contains('.')) {
      return 'Please enter a valid email domain';
    }

    // Check that domain doesn't start or end with a dot or hyphen
    if (domainPart.startsWith('.') ||
        domainPart.endsWith('.') ||
        domainPart.startsWith('-') ||
        domainPart.endsWith('-')) {
      return 'Please enter a valid email domain';
    }

    // Additional validation for ambiguous/suspicious patterns

    // Local part must be at least 2 characters to avoid single-letter ambiguity
    if (localPart.length < 2) {
      return 'Email username must be at least 2 characters';
    }

    // Local part must contain at least one letter (not just numbers)
    if (!RegExp(r'[a-zA-Z]').hasMatch(localPart)) {
      return 'Email username must contain at least one letter';
    }

    // Split domain into parts (e.g., 'mail.google.com' -> ['mail', 'google', 'com'])
    final domainParts = domainPart.split('.');

    // Domain must have at least 2 parts (domain + TLD)
    if (domainParts.length < 2) {
      return 'Please enter a valid email domain';
    }

    // Get the main domain and TLD
    final mainDomain = domainParts[domainParts.length - 2];
    final tld = domainParts[domainParts.length - 1];

    // Main domain must be at least 2 characters
    if (mainDomain.length < 2) {
      return 'Email domain name is too short';
    }

    // Main domain must contain at least one letter (not be all numbers)
    if (!RegExp(r'[a-zA-Z]').hasMatch(mainDomain)) {
      return 'Email domain must contain letters, not just numbers';
    }

    // TLD must be at least 2 characters (already checked by regex, but explicit)
    if (tld.length < 2) {
      return 'Email domain extension is too short';
    }

    // Reject single-letter main domains (like 't.com')
    if (mainDomain.length == 1) {
      return 'Email domain name is too short';
    }

    // Optional: Check against common valid TLDs to reduce typos
    // This is a reasonable subset of popular TLDs
    final commonTLDs = [
      'com', 'org', 'net', 'edu', 'gov', 'mil', 'int',
      'co', 'uk', 'us', 'ca', 'au', 'de', 'fr', 'jp', 'cn', 'in',
      'io', 'pk', // Added Pakistan
      'info', 'biz', 'name', 'pro', 'dev', 'app', 'tech',
    ];

    // If it's a two-part domain (like example.com), validate TLD more strictly
    if (domainParts.length == 2 && !commonTLDs.contains(tld)) {
      return 'Please enter a valid email domain extension';
    }

    return null;
  }

  // License ID validation (alphanumeric with some special characters)
  static String? validateLicenseId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License ID is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 3) {
      return 'License ID must be at least 3 characters long';
    }

    if (trimmedValue.length > 20) {
      return 'License ID cannot exceed 20 characters';
    }

    // Allow letters, numbers, hyphens, and underscores
    final licenseRegex = RegExp(r'^[a-zA-Z0-9\-_]+$');
    if (!licenseRegex.hasMatch(trimmedValue)) {
      return 'License ID can only contain letters, numbers, hyphens, and underscores';
    }

    return null;
  }

  // Bio/Description validation
  static String? validateBio(
    String? value, {
    int minLength = 50,
    int maxLength = 500,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Bio is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < minLength) {
      return 'Bio must be at least $minLength characters long';
    }

    if (trimmedValue.length > maxLength) {
      return 'Bio cannot exceed $maxLength characters';
    }

    return null;
  }

  // Experience years validation
  static String? validateExperienceYears(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Experience years is required';
    }

    final years = int.tryParse(value.trim());
    if (years == null) {
      return 'Please enter a valid number';
    }

    if (years < 0) {
      return 'Experience years cannot be negative';
    }

    if (years > 60) {
      return 'Experience years cannot exceed 60';
    }

    return null;
  }

  // Consultation fee validation
  static String? validateConsultationFee(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Consultation fee is required';
    }

    final fee = int.tryParse(value.trim());
    if (fee == null) {
      return 'Please enter a valid amount';
    }

    if (fee <= 0) {
      return 'Consultation fee must be greater than 0';
    }

    if (fee > 100000) {
      return 'Consultation fee cannot exceed 100,000 PKR';
    }

    return null;
  }

  // Password validation - comprehensive security requirements
  static String? validatePassword(
    String? value, {
    String fieldName = 'Password',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final password = value.trim();

    // Check minimum length
    if (password.length < 8) {
      return '$fieldName must be at least 8 characters long';
    }

    // Check for at least one letter (uppercase or lowercase)
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return '$fieldName must contain at least one letter';
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return '$fieldName must contain at least one number';
    }

    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_+=\-\[\]\\;/~`]').hasMatch(password)) {
      return '$fieldName must contain at least one special character (!@#\$%^&*(),.?":{}|<>_+=\\-\\[\\]\\\\;/~`)';
    }

    return null;
  }

  // Password strength indicator (returns 0-4)
  static int getPasswordStrength(String? password) {
    if (password == null || password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_+=\-\[\]\\;/~`]').hasMatch(password)) {
      strength++;
    }

    return strength > 4 ? 4 : strength;
  }

  // Password strength description
  static String getPasswordStrengthDescription(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Strong';
      default:
        return 'Very Weak';
    }
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Date of birth validation
  static String? validateDateOfBirth(DateTime? dateOfBirth) {
    if (dateOfBirth == null) {
      return 'Date of birth is required';
    }

    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;

    if (age < 13) {
      return 'You must be at least 13 years old';
    }

    if (age > 120) {
      return 'Please enter a valid date of birth';
    }

    return null;
  }
}

// Input formatters for different field types
class InputFormatters {
  // Name formatter - only letters, spaces, apostrophes, and hyphens
  static final TextInputFormatter nameFormatter =
      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s'\-]"));

  // Phone number formatter - digits, spaces, hyphens, parentheses, plus
  static final TextInputFormatter phoneFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)\+]'));

  // License ID formatter - alphanumeric, hyphens, underscores
  static final TextInputFormatter licenseFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-_]'));

  // Numbers only formatter
  static final TextInputFormatter numbersOnlyFormatter =
      FilteringTextInputFormatter.digitsOnly;

  // Password formatter - allow common password characters
  static final TextInputFormatter passwordFormatter =
      FilteringTextInputFormatter.allow(
        RegExp(r'[a-zA-Z0-9!@#$%^&*(),.?":{}|<>_+=\-\[\]\\;/~`]'),
      );

  // Capitalize first letter of each word
  static final TextInputFormatter capitalizeWordsFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty) return newValue;

        final words = text.split(' ');
        final capitalizedWords = words
            .map((word) {
              if (word.isEmpty) return word;
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            })
            .join(' ');

        return TextEditingValue(
          text: capitalizedWords,
          selection: TextSelection.collapsed(offset: capitalizedWords.length),
        );
      });
}
