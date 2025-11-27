import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/therapist.dart';
import '../../services/therapist_search_service.dart';
import '../../widgets/therapist_card.dart';
import '../../widgets/search_filters.dart';
import '../therapist_detail_screen.dart';

class PatientFindTab extends StatefulWidget {
  const PatientFindTab({super.key});

  @override
  State<PatientFindTab> createState() => _PatientFindTabState();
}

class _PatientFindTabState extends State<PatientFindTab> {
  final TextEditingController _searchController = TextEditingController();
  final TherapistSearchService _searchService = TherapistSearchService();

  List<Therapist> _filteredTherapists = [];
  SearchFilters _filters = SearchFilters();

  bool _isLoading = false;
  bool _isInitialLoad = true;
  String? _errorMessage;

  List<String> _availableSpecializations = [];
  List<String> _availableLocations = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _isInitialLoad = true;
      _errorMessage = null;
    });

    try {
      // Load featured/top-rated therapists initially
      final therapists = await _searchService.getFeaturedTherapists(limit: 20);

      // Load available filter options
      final [specializations, locations] = await Future.wait([
        _searchService.getAvailableSpecializations(),
        _searchService.getAvailableLocations(),
      ]);

      if (mounted) {
        setState(() {
          _filteredTherapists = therapists;
          _availableSpecializations = specializations;
          _availableLocations = locations;
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  Future<void> _searchTherapists() async {
    final query = _searchController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Therapist> results;

      if (query.isEmpty && !_filters.hasActiveFilters) {
        // Load featured therapists if no search query or filters
        results = await _searchService.getFeaturedTherapists(limit: 50);
      } else {
        // Perform filtered search
        results = await _searchService.getTherapists(
          searchQuery: query.isEmpty ? null : query,
          specializations: _filters.selectedSpecializations.isNotEmpty
              ? _filters.selectedSpecializations
              : null,
          location: _filters.selectedLocation,
          minFee: _filters.minFee,
          maxFee: _filters.maxFee,
          minExperience: _filters.minExperience,
          maxExperience: _filters.maxExperience,
          minRating: _filters.minRating,
          verifiedOnly: _filters.verifiedOnly,
          limit: 50,
        );
      }

      if (mounted) {
        setState(() {
          _filteredTherapists = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onFiltersChanged(SearchFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
    _searchTherapists();
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: TherapistSearchFiltersWidget(
            filters: _filters,
            onFiltersChanged: _onFiltersChanged,
            availableSpecializations: _availableSpecializations,
            availableLocations: _availableLocations,
          ),
        );
      },
    );
  }

  void _navigateToTherapistDetail(Therapist therapist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TherapistDetailScreen(therapist: therapist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildQuickFilters(),
            const SizedBox(height: 24),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Find Your Therapist',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with licensed mental health professionals',
          style: TextStyle(fontSize: 16, color: AppTheme.secondaryText),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _searchTherapists(),
              decoration: InputDecoration(
                hintText: 'Search by name, specialization...',
                hintStyle: TextStyle(color: AppTheme.lightText),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: AppTheme.secondaryText),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchTherapists();
                        },
                        icon: Icon(Icons.clear, color: AppTheme.secondaryText),
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide clear button
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showFiltersBottomSheet,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: [
                    const Icon(Icons.tune, color: Colors.white, size: 24),
                    if (_filters.hasActiveFilters)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${_filters.activeFilterCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return QuickFilterChips(
      filters: _filters,
      onFiltersChanged: _onFiltersChanged,
    );
  }

  Widget _buildContent() {
    if (_isInitialLoad && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredTherapists.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                '${_filteredTherapists.length} therapists found',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryGreen,
                  ),
                ),
            ],
          ),
        ),

        // Therapist list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInitialData,
            color: AppTheme.primaryGreen,
            child: ListView.builder(
              itemCount: _filteredTherapists.length,
              itemBuilder: (context, index) {
                final therapist = _filteredTherapists[index];
                return TherapistCard(
                  therapist: therapist,
                  onTap: () => _navigateToTherapistDetail(therapist),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!.replaceFirst('Exception: ', ''),
            style: const TextStyle(fontSize: 14, color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearchQuery = _searchController.text.trim().isNotEmpty;
    final hasFilters = _filters.hasActiveFilters;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              hasSearchQuery || hasFilters ? Icons.search_off : Icons.people,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchQuery || hasFilters
                ? 'No therapists found'
                : 'No therapists available',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchQuery || hasFilters
                ? 'Try adjusting your search or filters'
                : 'Check back later for available therapists',
            style: const TextStyle(fontSize: 14, color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
          if (hasSearchQuery || hasFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _filters = SearchFilters();
                });
                _loadInitialData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }
}
