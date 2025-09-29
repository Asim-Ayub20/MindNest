/// Application-wide constants to eliminate hardcoded values
class AppConstants {
  // Animation durations (milliseconds)
  static const int defaultAnimationDuration = 300;
  static const int longAnimationDuration = 500;
  static const int shortAnimationDuration = 150;

  // Spacing values
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border radius values
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Font sizes
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 20.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeHeading = 28.0;
  static const double fontSizeDisplay = 32.0;

  // Icon sizes
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 20.0;
  static const double iconSizeL = 24.0;
  static const double iconSizeXL = 32.0;
  static const double iconSizeXXL = 48.0;
  static const double iconSizeHuge = 64.0;

  // Elevation levels
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Input field dimensions
  static const double inputHeight = 48.0;
  static const double buttonHeight = 48.0;

  // Container dimensions
  static const double cardWidth = 300.0;
  static const double modalMaxWidth = 400.0;
  static const double avatarSizeS = 32.0;
  static const double avatarSizeM = 48.0;
  static const double avatarSizeL = 64.0;
  static const double avatarSizeXL = 96.0;

  // Validation constraints
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxBioLength = 500;
  static const int maxQualificationsLength = 1000;

  // Phone number constraints
  static const int minPhoneLength = 7;
  static const int maxPhoneLength = 15;

  // Professional constraints
  static const int minExperienceYears = 0;
  static const int maxExperienceYears = 50;
  static const int minConsultationFee = 0;
  static const int maxConsultationFee = 10000;

  // Network timeouts (seconds)
  static const int defaultTimeout = 30;
  static const int uploadTimeout = 60;
  static const int downloadTimeout = 120;

  // Image constraints
  static const int maxImageSizeMB = 5;
  static const int imageQuality = 85;
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Storage keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';

  // API endpoints (relative paths)
  static const String apiVersion = '/v1';
  static const String authEndpoint = '/auth';
  static const String profilesEndpoint = '/profiles';
  static const String onboardingEndpoint = '/user_onboarding';

  // Error messages
  static const String networkError =
      'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unknown error occurred.';
  static const String validationError =
      'Please check your input and try again.';
  static const String permissionError =
      'Permission denied. Please check your permissions.';

  // Success messages
  static const String profileSaved = 'Profile saved successfully!';
  static const String passwordReset = 'Password reset successfully!';
  static const String emailSent = 'Email sent successfully!';
  static const String accountCreated = 'Account created successfully!';

  // Loading messages
  static const String loading = 'Loading...';
  static const String saving = 'Saving...';
  static const String uploading = 'Uploading...';
  static const String processing = 'Processing...';

  // General labels
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String done = 'Done';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String skip = 'Skip';
  static const String continueLabel = 'Continue';

  // Validation patterns (regex)
  static const String namePattern = r"^[a-zA-Z\s\'\-]+$";
  static const String phonePattern = r"^[\d\s\-\(\)\+]+$";
  static const String emailPattern =
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";

  // File extensions
  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
  ];

  // Supported countries (subset for demonstration)
  static const List<String> priorityCountries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'South Korea',
    'Singapore',
    'India',
  ];

  // Development flags
  static const bool enableDebugMode = true;
  static const bool enableLogging = true;
  static const bool enableCrashlytics = false; // Set to true in production

  // Performance settings
  static const int maxCacheSize = 50; // Number of cached items
  static const int cacheExpirationHours = 24;
  static const int maxConcurrentRequests = 5;
}
