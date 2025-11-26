/// Supabase configuration
///
/// SECURITY NOTE: In production, consider using environment variables
/// or a secure configuration management service to store these values.
///
/// For development: These keys are safe to use in client-side applications
/// as they are designed for public access. Row Level Security (RLS) in
/// Supabase protects your data.
class SupabaseConfig {
  // Supabase project URL
  static const String supabaseUrl = 'https://yqhgsmrtxgfjuljazoie.supabase.co';

  // Supabase anonymous key (safe for client-side use)
  // This key has limited permissions controlled by Row Level Security (RLS)
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxaGdzbXJ0eGdmanVsamF6b2llIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NTE2ODEsImV4cCI6MjA3NDEyNzY4MX0.Iny6UH4vjesqQyh4sDMcmV58XKgUXDeERImhlKJNcUk';

  // Debug mode - set to false in production builds
  static const bool debugMode = false;

  // Deep link scheme
  static const String deepLinkScheme = 'io.supabase.mindnest';
}
