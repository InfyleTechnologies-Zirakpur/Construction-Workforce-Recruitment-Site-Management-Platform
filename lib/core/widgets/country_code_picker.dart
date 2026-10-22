import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

export 'package:country_picker/country_picker.dart';


Country get defaultCountry => Country.parse('IN');



class CountryCodeSelector extends StatelessWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;

  const CountryCodeSelector({
    super.key,
    required this.selectedCountry,
    required this.onCountryChanged,
  });

  static final List<Country> _allCountries = CountryService().getAll();

  @override
  Widget build(BuildContext context) {
    final currentValue = _allCountries.any(
      (c) => c.countryCode == selectedCountry.countryCode,
    )
        ? selectedCountry.countryCode
        : _allCountries.first.countryCode;

    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isDense: true,
          menuMaxHeight: 320,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF6B7280),
            size: 16,
          ),
          items: _allCountries.map((c) {
            final isSelected = c.countryCode == selectedCountry.countryCode;
            return DropdownMenuItem<String>(
              value: c.countryCode,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.flagEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${c.phoneCode}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF1E2A38)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return _allCountries.map((c) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.flagEmoji,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '+${c.phoneCode}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2A38),
                    ),
                  ),
                ],
              );
            }).toList();
          },
          onChanged: (code) {
            if (code != null) {
              final country = _allCountries.firstWhere(
                (c) => c.countryCode == code,
                orElse: () => selectedCountry,
              );
              onCountryChanged(country);
            }
          },
        ),
      ),
    );
  }
}
