import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SearchFilters {
  String? searchQuery;
  List<String> selectedSpecializations;
  String? selectedLocation;
  int? minFee;
  int? maxFee;
  int? minExperience;
  int? maxExperience;
  double? minRating;
  bool verifiedOnly;

  SearchFilters({
    this.searchQuery,
    this.selectedSpecializations = const [],
    this.selectedLocation,
    this.minFee,
    this.maxFee,
    this.minExperience,
    this.maxExperience,
    this.minRating,
    this.verifiedOnly = false,
  });

  SearchFilters copyWith({
    String? searchQuery,
    List<String>? selectedSpecializations,
    String? selectedLocation,
    int? minFee,
    int? maxFee,
    int? minExperience,
    int? maxExperience,
    double? minRating,
    bool? verifiedOnly,
  }) {
    return SearchFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSpecializations:
          selectedSpecializations ?? this.selectedSpecializations,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      minFee: minFee ?? this.minFee,
      maxFee: maxFee ?? this.maxFee,
      minExperience: minExperience ?? this.minExperience,
      maxExperience: maxExperience ?? this.maxExperience,
      minRating: minRating ?? this.minRating,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }

  void clear() {
    searchQuery = null;
    selectedSpecializations = [];
    selectedLocation = null;
    minFee = null;
    maxFee = null;
    minExperience = null;
    maxExperience = null;
    minRating = null;
    verifiedOnly = false;
  }

  bool get hasActiveFilters {
    return selectedSpecializations.isNotEmpty ||
        selectedLocation != null ||
        minFee != null ||
        maxFee != null ||
        minExperience != null ||
        maxExperience != null ||
        minRating != null ||
        verifiedOnly;
  }

  int get activeFilterCount {
    int count = 0;
    if (selectedSpecializations.isNotEmpty) count++;
    if (selectedLocation != null) count++;
    if (minFee != null || maxFee != null) count++;
    if (minExperience != null || maxExperience != null) count++;
    if (minRating != null) count++;
    if (verifiedOnly) count++;
    return count;
  }
}

class TherapistSearchFiltersWidget extends StatefulWidget {
  final SearchFilters filters;
  final Function(SearchFilters) onFiltersChanged;
  final List<String> availableSpecializations;
  final List<String> availableLocations;

  const TherapistSearchFiltersWidget({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    this.availableSpecializations = const [],
    this.availableLocations = const [],
  });

  @override
  State<TherapistSearchFiltersWidget> createState() =>
      _TherapistSearchFiltersWidgetState();
}

class _TherapistSearchFiltersWidgetState
    extends State<TherapistSearchFiltersWidget> {
  late SearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = SearchFilters(
      searchQuery: widget.filters.searchQuery,
      selectedSpecializations: List.from(
        widget.filters.selectedSpecializations,
      ),
      selectedLocation: widget.filters.selectedLocation,
      minFee: widget.filters.minFee,
      maxFee: widget.filters.maxFee,
      minExperience: widget.filters.minExperience,
      maxExperience: widget.filters.maxExperience,
      minRating: widget.filters.minRating,
      verifiedOnly: widget.filters.verifiedOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Text(
                  'Filter Therapists',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Filters content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpecializationFilter(),
                  const SizedBox(height: 24),
                  _buildLocationFilter(),
                  const SizedBox(height: 24),
                  _buildFeeRangeFilter(),
                  const SizedBox(height: 24),
                  _buildExperienceFilter(),
                  const SizedBox(height: 24),
                  _buildRatingFilter(),
                  const SizedBox(height: 24),
                  _buildVerifiedFilter(),
                ],
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _filters.clear();
                      });
                      widget.onFiltersChanged(_filters);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onFiltersChanged(_filters);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationFilter() {
    return _buildFilterSection(
      title: 'Specializations',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _getSpecializationOptions().map((specialization) {
          final isSelected = _filters.selectedSpecializations.contains(
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
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _filters.selectedSpecializations.add(specialization);
                } else {
                  _filters.selectedSpecializations.remove(specialization);
                }
              });
            },
            selectedColor: AppTheme.primaryGreen,
            backgroundColor: AppTheme.lightGreen.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryGreen
                    : AppTheme.lightGreen.withValues(alpha: 0.3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationFilter() {
    return _buildFilterSection(
      title: 'Location',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _filters.selectedLocation,
            decoration: InputDecoration(
              hintText: 'Select location',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightGreen.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightGreen.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryGreen),
              ),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Any location'),
              ),
              ...widget.availableLocations.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _filters.selectedLocation = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRangeFilter() {
    return _buildFilterSection(
      title: 'Consultation Fee Range',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _filters.minFee?.toString(),
                  decoration: InputDecoration(
                    labelText: 'Min Fee (Rs.)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _filters.minFee = int.tryParse(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _filters.maxFee?.toString(),
                  decoration: InputDecoration(
                    labelText: 'Max Fee (Rs.)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _filters.maxFee = int.tryParse(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceFilter() {
    return _buildFilterSection(
      title: 'Experience (Years)',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _filters.minExperience,
                  decoration: InputDecoration(
                    labelText: 'Min Experience',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Any'),
                    ),
                    ...List.generate(20, (i) => i + 1).map((years) {
                      return DropdownMenuItem<int>(
                        value: years,
                        child: Text('$years+ years'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filters.minExperience = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter() {
    return _buildFilterSection(
      title: 'Minimum Rating',
      child: Column(
        children: [
          DropdownButtonFormField<double>(
            initialValue: _filters.minRating,
            decoration: InputDecoration(
              labelText: 'Min Rating',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem<double>(
                value: null,
                child: Text('Any rating'),
              ),
              ...[1.0, 2.0, 3.0, 4.0, 4.5].map((rating) {
                return DropdownMenuItem<double>(
                  value: rating,
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('$rating & above'),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _filters.minRating = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedFilter() {
    return _buildFilterSection(
      title: 'Verification Status',
      child: SwitchListTile(
        title: const Text(
          'Show only verified therapists',
          style: TextStyle(fontSize: 14, color: AppTheme.primaryText),
        ),
        value: _filters.verifiedOnly,
        onChanged: (value) {
          setState(() {
            _filters.verifiedOnly = value;
          });
        },
        activeThumbColor: AppTheme.primaryGreen,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  List<String> _getSpecializationOptions() {
    const defaultSpecializations = [
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
    ];

    // Combine default specializations with available ones from the service
    Set<String> allSpecializations = {...defaultSpecializations};
    allSpecializations.addAll(widget.availableSpecializations);

    return allSpecializations.toList()..sort();
  }
}

// Quick filter chips widget for the main search interface
class QuickFilterChips extends StatelessWidget {
  final SearchFilters filters;
  final Function(SearchFilters) onFiltersChanged;

  const QuickFilterChips({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickFilterChip(
            label: 'All',
            isSelected: !filters.hasActiveFilters,
            onTap: () {
              final newFilters = SearchFilters();
              onFiltersChanged(newFilters);
            },
          ),
          const SizedBox(width: 8),
          _buildQuickFilterChip(
            label: 'Verified',
            isSelected: filters.verifiedOnly,
            onTap: () {
              final newFilters = filters.copyWith(
                verifiedOnly: !filters.verifiedOnly,
              );
              onFiltersChanged(newFilters);
            },
          ),
          const SizedBox(width: 8),
          _buildQuickFilterChip(
            label: '4+ Stars',
            isSelected: filters.minRating == 4.0,
            onTap: () {
              final newFilters = filters.copyWith(
                minRating: filters.minRating == 4.0 ? null : 4.0,
              );
              onFiltersChanged(newFilters);
            },
          ),
          const SizedBox(width: 8),
          _buildQuickFilterChip(
            label: 'Anxiety',
            isSelected: filters.selectedSpecializations.contains(
              'Anxiety Disorders',
            ),
            onTap: () {
              final selectedSpecs = List<String>.from(
                filters.selectedSpecializations,
              );
              if (selectedSpecs.contains('Anxiety Disorders')) {
                selectedSpecs.remove('Anxiety Disorders');
              } else {
                selectedSpecs.add('Anxiety Disorders');
              }
              final newFilters = filters.copyWith(
                selectedSpecializations: selectedSpecs,
              );
              onFiltersChanged(newFilters);
            },
          ),
          const SizedBox(width: 8),
          _buildQuickFilterChip(
            label: 'Depression',
            isSelected: filters.selectedSpecializations.contains('Depression'),
            onTap: () {
              final selectedSpecs = List<String>.from(
                filters.selectedSpecializations,
              );
              if (selectedSpecs.contains('Depression')) {
                selectedSpecs.remove('Depression');
              } else {
                selectedSpecs.add('Depression');
              }
              final newFilters = filters.copyWith(
                selectedSpecializations: selectedSpecs,
              );
              onFiltersChanged(newFilters);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen
              : AppTheme.lightGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : AppTheme.lightGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.darkGreen,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
