import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/therapist.dart';

class TherapistSearchService {
  static final TherapistSearchService _instance =
      TherapistSearchService._internal();
  factory TherapistSearchService() => _instance;
  TherapistSearchService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all therapists with optional filtering
  Future<List<Therapist>> getTherapists({
    String? searchQuery,
    List<String>? specializations,
    String? location,
    int? minFee,
    int? maxFee,
    int? minExperience,
    int? maxExperience,
    double? minRating, // Keep for future compatibility
    bool verifiedOnly = false, // Keep for future compatibility
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('therapists').select('*');

      // Apply fee range filter
      if (minFee != null) {
        query = query.gte('consultation_fee', minFee);
      }
      if (maxFee != null) {
        query = query.lte('consultation_fee', maxFee);
      }

      // Apply experience range filter
      if (minExperience != null) {
        query = query.gte('experience_years', minExperience);
      }
      if (maxExperience != null) {
        query = query.lte('experience_years', maxExperience);
      }

      // Apply location filter (using ilike for case-insensitive partial match)
      if (location != null && location.isNotEmpty) {
        query = query.or(
          'location.ilike.%$location%,country.ilike.%$location%,city.ilike.%$location%',
        );
      }

      // Apply specialization filter (using overlaps for array matching)
      if (specializations != null && specializations.isNotEmpty) {
        query = query.overlaps('specialization', specializations);
      }

      // Apply ordering and pagination
      final List<dynamic> data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      List<Therapist> therapists = data
          .map((json) => Therapist.fromJson(json))
          .toList();

      // Apply text search filter on client side for better matching
      if (searchQuery != null && searchQuery.isNotEmpty) {
        therapists = therapists
            .where((therapist) => therapist.matchesSearchQuery(searchQuery))
            .toList();
      }

      return therapists;
    } catch (e) {
      throw Exception('Failed to fetch therapists: $e');
    }
  }

  // Search therapists by text query
  Future<List<Therapist>> searchTherapists(
    String searchQuery, {
    int limit = 50,
    int offset = 0,
  }) async {
    if (searchQuery.isEmpty) {
      return getTherapists(limit: limit, offset: offset);
    }

    try {
      // Use full-text search on multiple fields
      final List<dynamic> data = await _supabase
          .from('therapists')
          .select('*')
          .or(
            'full_name.ilike.%$searchQuery%,bio.ilike.%$searchQuery%,qualifications.ilike.%$searchQuery%,location.ilike.%$searchQuery%',
          )
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return data.map((json) => Therapist.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search therapists: $e');
    }
  }

  // Get therapists by specific specialization
  Future<List<Therapist>> getTherapistsBySpecialization(
    String specialization, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final List<dynamic> data = await _supabase
          .from('therapists')
          .select('*')
          .overlaps('specialization', [specialization])
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return data.map((json) => Therapist.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch therapists by specialization: $e');
    }
  }

  // Get therapist by ID
  Future<Therapist?> getTherapistById(String therapistId) async {
    try {
      final Map<String, dynamic>? data = await _supabase
          .from('therapists')
          .select('*')
          .eq('id', therapistId)
          .maybeSingle();

      return data != null ? Therapist.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to fetch therapist: $e');
    }
  }

  // Get featured/top-rated therapists
  Future<List<Therapist>> getFeaturedTherapists({int limit = 10}) async {
    try {
      final List<dynamic> data = await _supabase
          .from('therapists')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);

      return data.map((json) => Therapist.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured therapists: $e');
    }
  }

  // Get therapists by location
  Future<List<Therapist>> getTherapistsByLocation(
    String location, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final List<dynamic> data = await _supabase
          .from('therapists')
          .select('*')
          .or(
            'location.ilike.%$location%,country.ilike.%$location%,city.ilike.%$location%',
          )
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return data.map((json) => Therapist.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch therapists by location: $e');
    }
  }

  // Get therapist statistics
  Future<Map<String, dynamic>> getTherapistStats() async {
    try {
      final List<dynamic> data = await _supabase
          .from('therapists')
          .select('id, specialization, consultation_fee, experience_years');

      int totalTherapists = data.length;

      // Get unique specializations
      Set<String> allSpecializations = {};
      for (var therapist in data) {
        if (therapist['specialization'] != null) {
          List<String> specs = List<String>.from(therapist['specialization']);
          allSpecializations.addAll(specs);
        }
      }

      // Calculate fee ranges
      List<int> fees = data
          .map((t) => (t['consultation_fee'] ?? 0) as int)
          .where((fee) => fee > 0)
          .toList();
      fees.sort();

      int minFee = fees.isNotEmpty ? fees.first : 0;
      int maxFee = fees.isNotEmpty ? fees.last : 0;
      int medianFee = fees.isNotEmpty ? fees[fees.length ~/ 2] : 0;

      return {
        'total_therapists': totalTherapists,
        'specializations': allSpecializations.toList(),
        'min_fee': minFee,
        'max_fee': maxFee,
        'median_fee': medianFee,
      };
    } catch (e) {
      throw Exception('Failed to fetch therapist statistics: $e');
    }
  }

  // Helper method to get available specializations
  Future<List<String>> getAvailableSpecializations() async {
    try {
      final List<dynamic> data = await _supabase
          .from('therapists')
          .select('specialization');

      Set<String> specializations = {};
      for (var therapist in data) {
        if (therapist['specialization'] != null) {
          List<String> specs = List<String>.from(therapist['specialization']);
          specializations.addAll(specs);
        }
      }

      return specializations.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch specializations: $e');
    }
  }

  // Helper method to get available locations
  Future<List<String>> getAvailableLocations() async {
    try {
      final List<dynamic> data = await _supabase
          .from('therapists')
          .select('country, city, location')
          .not('location', 'is', null);

      Set<String> locations = {};
      for (var therapist in data) {
        if (therapist['location'] != null) {
          locations.add(therapist['location']);
        }
        if (therapist['country'] != null) {
          locations.add(therapist['country']);
        }
        if (therapist['city'] != null) {
          locations.add(therapist['city']);
        }
      }

      return locations.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch locations: $e');
    }
  }

  // Helper method for client-side filtering
  List<Therapist> filterTherapists(
    List<Therapist> therapists, {
    String? searchQuery,
    List<String>? specializations,
    String? location,
    int? minFee,
    int? maxFee,
    int? minExperience,
    int? maxExperience,
    double? minRating,
    bool verifiedOnly = false,
  }) {
    return therapists.where((therapist) {
      // Search query filter
      if (searchQuery != null && !therapist.matchesSearchQuery(searchQuery)) {
        return false;
      }

      // Specializations filter
      if (specializations != null &&
          !therapist.matchesSpecializations(specializations)) {
        return false;
      }

      // Location filter
      if (location != null && !therapist.matchesLocation(location)) {
        return false;
      }

      // Fee range filter
      if (!therapist.matchesFeeRange(minFee, maxFee)) {
        return false;
      }

      // Experience range filter
      if (!therapist.matchesExperienceRange(minExperience, maxExperience)) {
        return false;
      }

      // Rating filter - keep for future compatibility
      if (!therapist.matchesRating(minRating)) {
        return false;
      }

      // Verified filter - skip for now since field doesn't exist
      // TODO: Implement when verification system is added

      return true;
    }).toList();
  }
}
