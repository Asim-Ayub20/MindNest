import 'package:flutter/material.dart';
import '../utils/country_city_data.dart';

class LocationSelector extends StatefulWidget {
  final String? initialCountry;
  final String? initialCity;
  final Function(String country, String city) onLocationChanged;
  final String? Function(String?)? validator;

  const LocationSelector({
    super.key,
    this.initialCountry,
    this.initialCity,
    required this.onLocationChanged,
    this.validator,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  String? _selectedCountry;
  String? _selectedCity;
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final FocusNode _countryFocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();

  List<String> _countryResults = [];
  List<String> _cityResults = [];
  bool _showCountryDropdown = false;
  bool _showCityDropdown = false;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
    _selectedCity = widget.initialCity;

    if (_selectedCountry != null) {
      _countryController.text = _selectedCountry!;
    }
    if (_selectedCity != null) {
      _cityController.text = _selectedCity!;
    }

    _countryFocusNode.addListener(() {
      if (!_countryFocusNode.hasFocus) {
        setState(() {
          _showCountryDropdown = false;
        });
      } else {
        // When field gains focus, show all countries if no text is entered
        if (_countryController.text.isEmpty) {
          setState(() {
            _countryResults = CountryCityData.searchCountries('');
            _showCountryDropdown = _countryResults.isNotEmpty;
          });
        }
      }
    });

    _cityFocusNode.addListener(() {
      if (!_cityFocusNode.hasFocus) {
        setState(() {
          _showCityDropdown = false;
        });
      } else {
        // When field gains focus, show all cities if no text is entered and country is selected
        if (_selectedCountry != null && _cityController.text.isEmpty) {
          setState(() {
            _cityResults = CountryCityData.searchCities(_selectedCountry!, '');
            _showCityDropdown = _cityResults.isNotEmpty;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    _countryFocusNode.dispose();
    _cityFocusNode.dispose();
    super.dispose();
  }

  void _onCountryTextChanged(String value) {
    setState(() {
      _countryResults = CountryCityData.searchCountries(value);
      // Always show dropdown when user is typing, even if no results
      _showCountryDropdown = true;

      // Clear city selection if country changes
      if (value != _selectedCountry) {
        _selectedCity = null;
        _cityController.clear();
        _showCityDropdown = false;
      }
    });
  }

  void _onCityTextChanged(String value) {
    if (_selectedCountry == null) return;

    setState(() {
      _cityResults = CountryCityData.searchCities(_selectedCountry!, value);
      // Always show dropdown when user is typing, even if no results
      _showCityDropdown = true;
    });
  }

  void _selectCountry(String country) {
    setState(() {
      _selectedCountry = country;
      _countryController.text = country;
      _showCountryDropdown = false;

      // Clear city selection when country changes
      _selectedCity = null;
      _cityController.clear();
      _showCityDropdown = false;
    });

    // Move focus to city field
    _cityFocusNode.requestFocus();
  }

  void _selectCity(String city) {
    setState(() {
      _selectedCity = city;
      _cityController.text = city;
      _showCityDropdown = false;
    });

    // Notify parent widget
    if (_selectedCountry != null && _selectedCity != null) {
      widget.onLocationChanged(_selectedCountry!, _selectedCity!);
    }

    // Remove focus
    _cityFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country Field
        const Text(
          'Country',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            TextFormField(
              controller: _countryController,
              focusNode: _countryFocusNode,
              onChanged: _onCountryTextChanged,
              onTap: () {
                // Always show dropdown when field is tapped
                setState(() {
                  _countryResults = CountryCityData.searchCountries(
                    _countryController.text,
                  );
                  _showCountryDropdown = _countryResults.isNotEmpty;
                });
              },
              validator: widget.validator,
              decoration: InputDecoration(
                hintText: 'Type to search countries...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
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
                    color: Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF9CA3AF),
                ),
                errorStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  height: 1.2,
                ),
                errorMaxLines: 3,
              ),
            ),
            if (_showCountryDropdown)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _countryResults.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No countries found',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _countryResults.length,
                        itemBuilder: (context, index) {
                          final country = _countryResults[index];
                          return ListTile(
                            title: Text(
                              country,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _selectCountry(country),
                            hoverColor: const Color(0xFFF3F4F6),
                            dense: true,
                          );
                        },
                      ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // City Field
        const Text(
          'City',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            TextFormField(
              controller: _cityController,
              focusNode: _cityFocusNode,
              onChanged: _onCityTextChanged,
              onTap: () {
                if (_selectedCountry != null) {
                  // Always show dropdown when field is tapped
                  setState(() {
                    _cityResults = CountryCityData.searchCities(
                      _selectedCountry!,
                      _cityController.text,
                    );
                    _showCityDropdown = _cityResults.isNotEmpty;
                  });
                }
              },
              enabled: _selectedCountry != null,
              validator: (value) {
                if (_selectedCountry == null) {
                  return 'Please select a country first';
                }
                if (value == null || value.trim().isEmpty) {
                  return 'City is required';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: _selectedCountry == null
                    ? 'Select country first...'
                    : 'Type to search cities...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: _selectedCountry == null
                    ? const Color(0xFFF3F4F6)
                    : const Color(0xFFF9FAFB),
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
                    color: Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: _selectedCountry == null
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF9CA3AF),
                ),
                errorStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  height: 1.2,
                ),
                errorMaxLines: 3,
              ),
            ),
            if (_showCityDropdown && _selectedCountry != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _cityResults.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No cities found',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _cityResults.length,
                        itemBuilder: (context, index) {
                          final city = _cityResults[index];
                          return ListTile(
                            title: Text(
                              city,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _selectCity(city),
                            hoverColor: const Color(0xFFF3F4F6),
                            dense: true,
                          );
                        },
                      ),
              ),
          ],
        ),
      ],
    );
  }
}
