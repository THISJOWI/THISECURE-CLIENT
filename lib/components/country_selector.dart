import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/i18n/translations.dart';

/// Selector de países nativo con diseño moderno tipo iOS/Android
/// Incluye: búsqueda, banderas, agrupación por región, animaciones suaves
class CountrySelector extends StatefulWidget {
  final Function(String?) onCountrySelected;
  final String? initialValue;
  final String? labelText;

  const CountrySelector({
    super.key,
    required this.onCountrySelected,
    this.initialValue,
    this.labelText,
  });

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector>
    with SingleTickerProviderStateMixin {
  String? _selectedCountry;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialValue;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountryPickerSheet(
        initialValue: _selectedCountry,
        onCountrySelected: (country) {
          setState(() => _selectedCountry = country);
          widget.onCountrySelected(country);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountryData = _selectedCountry != null
        ? CountryData.countries.firstWhere(
            (c) => c.name == _selectedCountry,
            orElse: () => CountryData.countries.first,
          )
        : null;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: _showCountryPicker,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedCountry != null
                    ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: _selectedCountry != null ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      // Icono de globo o bandera seleccionada
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _selectedCountry != null
                              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            selectedCountryData != null
                                ? CountryFlagHelper.getFlagEmoji(selectedCountryData.code)
                                : '🌍',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Texto del país o placeholder
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.labelText ?? "country_optional".i18n,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedCountry ??
                                  "select_country".i18n,
                              style: TextStyle(
                                color: _selectedCountry != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                fontSize: 16,
                                fontWeight: _selectedCountry != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icono de flecha
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom Sheet del selector de países
class CountryPickerSheet extends StatefulWidget {
  final String? initialValue;
  final Function(String?) onCountrySelected;

  const CountryPickerSheet({
    super.key,
    this.initialValue,
    required this.onCountrySelected,
  });

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String? _selectedCountry;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialValue;
    _tabController = TabController(
      length: CountryData.regions.length,
      vsync: this,
    );
    // Focus en el campo de búsqueda después de la animación
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Country> get _filteredCountries {
    if (_searchQuery.isEmpty) return [];
    return CountryData.countries
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.code.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<Country> _getCountriesByRegion(String region) {
    return CountryData.countries.where((c) => c.region == region).toList();
  }

  void _selectCountry(Country country) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCountry = country.name);
    widget.onCountrySelected(country.name);
    final navigator = Navigator.of(context);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (navigator.mounted) {
        navigator.pop();
      }
    });
  }

  void _clearSelection() {
    HapticFeedback.lightImpact();
    setState(() => _selectedCountry = null);
    widget.onCountrySelected(null);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Handle de arrastre
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "select_country".i18n,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Botón de limpiar selección
                if (_selectedCountry != null)
                  TextButton.icon(
                    onPressed: _clearSelection,
                    icon: Icon(
                      Icons.clear,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    label: Text(
                      "clear".i18n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _searchFocusNode.hasFocus
                      ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: "search_country".i18n,
                  hintText: "search_country".i18n,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          tooltip: 'Clear search'.i18n,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Tabs de regiones (solo cuando no se está buscando)
          if (!isSearching) ...[
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Theme.of(context).colorScheme.secondary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              tabs: CountryData.regions
                  .map((region) => Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(region),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          // Lista de países
          Expanded(
            child: isSearching
                ? _buildSearchResults()
                : TabBarView(
                    controller: _tabController,
                    children: CountryData.regions
                        .map((region) => _buildCountryList(
                              _getCountriesByRegion(region),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final countries = _filteredCountries;

    if (countries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              "no_results".i18n,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final country = countries[index];
        final isSelected = _selectedCountry == country.name;

        return _CountryListItem(
          country: country,
          isSelected: isSelected,
          onTap: () => _selectCountry(country),
        );
      },
    );
  }

  Widget _buildCountryList(List<Country> countries) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final country = countries[index];
        final isSelected = _selectedCountry == country.name;

        return _CountryListItem(
          country: country,
          isSelected: isSelected,
          onTap: () => _selectCountry(country),
        );
      },
    );
  }
}

/// Item de la lista de países
class _CountryListItem extends StatelessWidget {
  final Country country;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountryListItem({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          highlightColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                // Bandera
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      CountryFlagHelper.getFlagEmoji(country.code),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Nombre del país
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        country.code,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Checkmark si está seleccionado
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modelo de datos de país
class Country {
  final String code;
  final String name;
  final String flag;
  final String region;

  const Country({
    required this.code,
    required this.name,
    required this.flag,
    required this.region,
  });
}

/// Helper para convertir código de país a emoji de bandera
class CountryFlagHelper {
  /// Convierte código ISO de 2 letras a emoji de bandera
  /// Las banderas se forman con los regional indicator symbols
  static String getFlagEmoji(String countryCode) {
    if (countryCode.length != 2) return '🏳️';
    final upperCode = countryCode.toUpperCase();
    // Los emojis de bandera usan los regional indicator symbols (A=🇦, B=🇧, etc.)
    // Cada letra se convierte a su regional indicator symbol
    final first = upperCode.codeUnitAt(0) - 0x41 + 0x1F1E6; // A -> 🇦
    final second = upperCode.codeUnitAt(1) - 0x41 + 0x1F1E6; // B -> 🇧
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}

/// Datos de países organizados por región
class CountryData {
  static const List<String> regions = [
    'Popular',
    'Europe',
    'Americas',
    'Asia',
    'Africa',
    'Oceania',
  ];

  static const List<Country> countries = [
    // Popular
    Country(code: 'US', name: 'United States', flag: 'US', region: 'Popular'),
    Country(code: 'ES', name: 'Spain', flag: 'ES', region: 'Popular'),
    Country(code: 'MX', name: 'Mexico', flag: 'MX', region: 'Popular'),
    Country(code: 'AR', name: 'Argentina', flag: 'AR', region: 'Popular'),
    Country(code: 'CO', name: 'Colombia', flag: 'CO', region: 'Popular'),
    Country(code: 'CL', name: 'Chile', flag: 'CL', region: 'Popular'),
    Country(code: 'PE', name: 'Peru', flag: 'PE', region: 'Popular'),
    Country(code: 'GB', name: 'United Kingdom', flag: 'GB', region: 'Popular'),
    Country(code: 'DE', name: 'Germany', flag: 'DE', region: 'Popular'),
    Country(code: 'FR', name: 'France', flag: 'FR', region: 'Popular'),
    Country(code: 'IT', name: 'Italy', flag: 'IT', region: 'Popular'),
    Country(code: 'BR', name: 'Brazil', flag: 'BR', region: 'Popular'),
    Country(code: 'CA', name: 'Canada', flag: 'CA', region: 'Popular'),

    // Europe
    Country(code: 'PT', name: 'Portugal', flag: 'PT', region: 'Europe'),
    Country(code: 'NL', name: 'Netherlands', flag: 'NL', region: 'Europe'),
    Country(code: 'BE', name: 'Belgium', flag: 'BE', region: 'Europe'),
    Country(code: 'CH', name: 'Switzerland', flag: 'CH', region: 'Europe'),
    Country(code: 'AT', name: 'Austria', flag: 'AT', region: 'Europe'),
    Country(code: 'SE', name: 'Sweden', flag: 'SE', region: 'Europe'),
    Country(code: 'NO', name: 'Norway', flag: 'NO', region: 'Europe'),
    Country(code: 'DK', name: 'Denmark', flag: 'DK', region: 'Europe'),
    Country(code: 'FI', name: 'Finland', flag: 'FI', region: 'Europe'),
    Country(code: 'IE', name: 'Ireland', flag: 'IE', region: 'Europe'),
    Country(code: 'PL', name: 'Poland', flag: 'PL', region: 'Europe'),
    Country(code: 'CZ', name: 'Czech Republic', flag: 'CZ', region: 'Europe'),
    Country(code: 'HU', name: 'Hungary', flag: 'HU', region: 'Europe'),
    Country(code: 'RO', name: 'Romania', flag: 'RO', region: 'Europe'),
    Country(code: 'BG', name: 'Bulgaria', flag: 'BG', region: 'Europe'),
    Country(code: 'HR', name: 'Croatia', flag: 'HR', region: 'Europe'),
    Country(code: 'SI', name: 'Slovenia', flag: 'SI', region: 'Europe'),
    Country(code: 'SK', name: 'Slovakia', flag: 'SK', region: 'Europe'),
    Country(code: 'LT', name: 'Lithuania', flag: 'LT', region: 'Europe'),
    Country(code: 'LV', name: 'Latvia', flag: 'LV', region: 'Europe'),
    Country(code: 'EE', name: 'Estonia', flag: 'EE', region: 'Europe'),
    Country(code: 'UA', name: 'Ukraine', flag: 'UA', region: 'Europe'),
    Country(code: 'BY', name: 'Belarus', flag: 'BY', region: 'Europe'),
    Country(code: 'MD', name: 'Moldova', flag: 'MD', region: 'Europe'),
    Country(code: 'AL', name: 'Albania', flag: 'AL', region: 'Europe'),
    Country(code: 'BA', name: 'Bosnia and Herzegovina', flag: 'BA', region: 'Europe'),
    Country(code: 'RS', name: 'Serbia', flag: 'RS', region: 'Europe'),
    Country(code: 'ME', name: 'Montenegro', flag: 'ME', region: 'Europe'),
    Country(code: 'MK', name: 'North Macedonia', flag: 'MK', region: 'Europe'),
    Country(code: 'GR', name: 'Greece', flag: 'GR', region: 'Europe'),
    Country(code: 'CY', name: 'Cyprus', flag: 'CY', region: 'Europe'),
    Country(code: 'MT', name: 'Malta', flag: 'MT', region: 'Europe'),
    Country(code: 'IS', name: 'Iceland', flag: 'IS', region: 'Europe'),
    Country(code: 'LU', name: 'Luxembourg', flag: 'LU', region: 'Europe'),
    Country(code: 'MC', name: 'Monaco', flag: 'MC', region: 'Europe'),
    Country(code: 'LI', name: 'Liechtenstein', flag: 'LI', region: 'Europe'),
    Country(code: 'AD', name: 'Andorra', flag: 'AD', region: 'Europe'),
    Country(code: 'SM', name: 'San Marino', flag: 'SM', region: 'Europe'),
    Country(code: 'VA', name: 'Vatican City', flag: 'VA', region: 'Europe'),

    // Americas
    Country(code: 'VE', name: 'Venezuela', flag: 'VE', region: 'Americas'),
    Country(code: 'BO', name: 'Bolivia', flag: 'BO', region: 'Americas'),
    Country(code: 'PY', name: 'Paraguay', flag: 'PY', region: 'Americas'),
    Country(code: 'UY', name: 'Uruguay', flag: 'UY', region: 'Americas'),
    Country(code: 'EC', name: 'Ecuador', flag: 'EC', region: 'Americas'),
    Country(code: 'GY', name: 'Guyana', flag: 'GY', region: 'Americas'),
    Country(code: 'SR', name: 'Suriname', flag: 'SR', region: 'Americas'),
    Country(code: 'GF', name: 'French Guiana', flag: 'GF', region: 'Americas'),
    Country(code: 'FK', name: 'Falkland Islands', flag: 'FK', region: 'Americas'),
    Country(code: 'US', name: 'United States', flag: 'US', region: 'Americas'),
    Country(code: 'CA', name: 'Canada', flag: 'CA', region: 'Americas'),
    Country(code: 'MX', name: 'Mexico', flag: 'MX', region: 'Americas'),
    Country(code: 'GT', name: 'Guatemala', flag: 'GT', region: 'Americas'),
    Country(code: 'BZ', name: 'Belize', flag: 'BZ', region: 'Americas'),
    Country(code: 'SV', name: 'El Salvador', flag: 'SV', region: 'Americas'),
    Country(code: 'HN', name: 'Honduras', flag: 'HN', region: 'Americas'),
    Country(code: 'NI', name: 'Nicaragua', flag: 'NI', region: 'Americas'),
    Country(code: 'CR', name: 'Costa Rica', flag: 'CR', region: 'Americas'),
    Country(code: 'PA', name: 'Panama', flag: 'PA', region: 'Americas'),
    Country(code: 'CU', name: 'Cuba', flag: 'CU', region: 'Americas'),
    Country(code: 'JM', name: 'Jamaica', flag: 'JM', region: 'Americas'),
    Country(code: 'HT', name: 'Haiti', flag: 'HT', region: 'Americas'),
    Country(code: 'DO', name: 'Dominican Republic', flag: 'DO', region: 'Americas'),
    Country(code: 'PR', name: 'Puerto Rico', flag: 'PR', region: 'Americas'),
    Country(code: 'BS', name: 'Bahamas', flag: 'BS', region: 'Americas'),
    Country(code: 'TT', name: 'Trinidad and Tobago', flag: 'TT', region: 'Americas'),
    Country(code: 'BB', name: 'Barbados', flag: 'BB', region: 'Americas'),
    Country(code: 'GD', name: 'Grenada', flag: 'GD', region: 'Americas'),
    Country(code: 'LC', name: 'Saint Lucia', flag: 'LC', region: 'Americas'),
    Country(code: 'VC', name: 'Saint Vincent', flag: 'VC', region: 'Americas'),
    Country(code: 'AG', name: 'Antigua and Barbuda', flag: 'AG', region: 'Americas'),
    Country(code: 'DM', name: 'Dominica', flag: 'DM', region: 'Americas'),
    Country(code: 'KN', name: 'Saint Kitts and Nevis', flag: 'KN', region: 'Americas'),

    // Asia
    Country(code: 'JP', name: 'Japan', flag: 'JP', region: 'Asia'),
    Country(code: 'KR', name: 'South Korea', flag: 'KR', region: 'Asia'),
    Country(code: 'CN', name: 'China', flag: 'CN', region: 'Asia'),
    Country(code: 'IN', name: 'India', flag: 'IN', region: 'Asia'),
    Country(code: 'ID', name: 'Indonesia', flag: 'ID', region: 'Asia'),
    Country(code: 'TH', name: 'Thailand', flag: 'TH', region: 'Asia'),
    Country(code: 'VN', name: 'Vietnam', flag: 'VN', region: 'Asia'),
    Country(code: 'MY', name: 'Malaysia', flag: 'MY', region: 'Asia'),
    Country(code: 'PH', name: 'Philippines', flag: 'PH', region: 'Asia'),
    Country(code: 'SG', name: 'Singapore', flag: 'SG', region: 'Asia'),
    Country(code: 'TW', name: 'Taiwan', flag: 'TW', region: 'Asia'),
    Country(code: 'HK', name: 'Hong Kong', flag: 'HK', region: 'Asia'),
    Country(code: 'MO', name: 'Macau', flag: 'MO', region: 'Asia'),
    Country(code: 'MN', name: 'Mongolia', flag: 'MN', region: 'Asia'),
    Country(code: 'KP', name: 'North Korea', flag: 'KP', region: 'Asia'),
    Country(code: 'KH', name: 'Cambodia', flag: 'KH', region: 'Asia'),
    Country(code: 'LA', name: 'Laos', flag: 'LA', region: 'Asia'),
    Country(code: 'MM', name: 'Myanmar', flag: 'MM', region: 'Asia'),
    Country(code: 'BD', name: 'Bangladesh', flag: 'BD', region: 'Asia'),
    Country(code: 'NP', name: 'Nepal', flag: 'NP', region: 'Asia'),
    Country(code: 'BT', name: 'Bhutan', flag: 'BT', region: 'Asia'),
    Country(code: 'LK', name: 'Sri Lanka', flag: 'LK', region: 'Asia'),
    Country(code: 'MV', name: 'Maldives', flag: 'MV', region: 'Asia'),
    Country(code: 'PK', name: 'Pakistan', flag: 'PK', region: 'Asia'),
    Country(code: 'AF', name: 'Afghanistan', flag: 'AF', region: 'Asia'),
    Country(code: 'IR', name: 'Iran', flag: 'IR', region: 'Asia'),
    Country(code: 'IQ', name: 'Iraq', flag: 'IQ', region: 'Asia'),
    Country(code: 'SY', name: 'Syria', flag: 'SY', region: 'Asia'),
    Country(code: 'LB', name: 'Lebanon', flag: 'LB', region: 'Asia'),
    Country(code: 'JO', name: 'Jordan', flag: 'JO', region: 'Asia'),
    Country(code: 'IL', name: 'Israel', flag: 'IL', region: 'Asia'),
    Country(code: 'PS', name: 'Palestine', flag: 'PS', region: 'Asia'),
    Country(code: 'SA', name: 'Saudi Arabia', flag: 'SA', region: 'Asia'),
    Country(code: 'YE', name: 'Yemen', flag: 'YE', region: 'Asia'),
    Country(code: 'OM', name: 'Oman', flag: 'OM', region: 'Asia'),
    Country(code: 'AE', name: 'United Arab Emirates', flag: 'AE', region: 'Asia'),
    Country(code: 'QA', name: 'Qatar', flag: 'QA', region: 'Asia'),
    Country(code: 'BH', name: 'Bahrain', flag: 'BH', region: 'Asia'),
    Country(code: 'KW', name: 'Kuwait', flag: 'KW', region: 'Asia'),
    Country(code: 'TR', name: 'Turkey', flag: 'TR', region: 'Asia'),
    Country(code: 'GE', name: 'Georgia', flag: 'GE', region: 'Asia'),
    Country(code: 'AM', name: 'Armenia', flag: 'AM', region: 'Asia'),
    Country(code: 'AZ', name: 'Azerbaijan', flag: 'AZ', region: 'Asia'),
    Country(code: 'KZ', name: 'Kazakhstan', flag: 'KZ', region: 'Asia'),
    Country(code: 'UZ', name: 'Uzbekistan', flag: 'UZ', region: 'Asia'),
    Country(code: 'KG', name: 'Kyrgyzstan', flag: 'KG', region: 'Asia'),
    Country(code: 'TJ', name: 'Tajikistan', flag: 'TJ', region: 'Asia'),
    Country(code: 'TM', name: 'Turkmenistan', flag: 'TM', region: 'Asia'),

    // Africa
    Country(code: 'ZA', name: 'South Africa', flag: 'ZA', region: 'Africa'),
    Country(code: 'EG', name: 'Egypt', flag: 'EG', region: 'Africa'),
    Country(code: 'NG', name: 'Nigeria', flag: 'NG', region: 'Africa'),
    Country(code: 'KE', name: 'Kenya', flag: 'KE', region: 'Africa'),
    Country(code: 'MA', name: 'Morocco', flag: 'MA', region: 'Africa'),
    Country(code: 'ET', name: 'Ethiopia', flag: 'ET', region: 'Africa'),
    Country(code: 'GH', name: 'Ghana', flag: 'GH', region: 'Africa'),
    Country(code: 'TZ', name: 'Tanzania', flag: 'TZ', region: 'Africa'),
    Country(code: 'UG', name: 'Uganda', flag: 'UG', region: 'Africa'),
    Country(code: 'MZ', name: 'Mozambique', flag: 'MZ', region: 'Africa'),
    Country(code: 'MG', name: 'Madagascar', flag: 'MG', region: 'Africa'),
    Country(code: 'CM', name: 'Cameroon', flag: 'CM', region: 'Africa'),
    Country(code: 'CI', name: 'Ivory Coast', flag: 'CI', region: 'Africa'),
    Country(code: 'NE', name: 'Niger', flag: 'NE', region: 'Africa'),
    Country(code: 'BF', name: 'Burkina Faso', flag: 'BF', region: 'Africa'),
    Country(code: 'ML', name: 'Mali', flag: 'ML', region: 'Africa'),
    Country(code: 'MW', name: 'Malawi', flag: 'MW', region: 'Africa'),
    Country(code: 'ZM', name: 'Zambia', flag: 'ZM', region: 'Africa'),
    Country(code: 'SN', name: 'Senegal', flag: 'SN', region: 'Africa'),
    Country(code: 'SO', name: 'Somalia', flag: 'SO', region: 'Africa'),
    Country(code: 'ZW', name: 'Zimbabwe', flag: 'ZW', region: 'Africa'),
    Country(code: 'RW', name: 'Rwanda', flag: 'RW', region: 'Africa'),
    Country(code: 'SS', name: 'South Sudan', flag: 'SS', region: 'Africa'),
    Country(code: 'GN', name: 'Guinea', flag: 'GN', region: 'Africa'),
    Country(code: 'BI', name: 'Burundi', flag: 'BI', region: 'Africa'),
    Country(code: 'BJ', name: 'Benin', flag: 'BJ', region: 'Africa'),
    Country(code: 'TD', name: 'Chad', flag: 'TD', region: 'Africa'),
    Country(code: 'SL', name: 'Sierra Leone', flag: 'SL', region: 'Africa'),
    Country(code: 'TG', name: 'Togo', flag: 'TG', region: 'Africa'),
    Country(code: 'LY', name: 'Libya', flag: 'LY', region: 'Africa'),
    Country(code: 'LR', name: 'Liberia', flag: 'LR', region: 'Africa'),
    Country(code: 'CF', name: 'Central African Republic', flag: 'CF', region: 'Africa'),
    Country(code: 'MR', name: 'Mauritania', flag: 'MR', region: 'Africa'),
    Country(code: 'ER', name: 'Eritrea', flag: 'ER', region: 'Africa'),
    Country(code: 'GM', name: 'Gambia', flag: 'GM', region: 'Africa'),
    Country(code: 'BW', name: 'Botswana', flag: 'BW', region: 'Africa'),
    Country(code: 'GA', name: 'Gabon', flag: 'GA', region: 'Africa'),
    Country(code: 'LS', name: 'Lesotho', flag: 'LS', region: 'Africa'),
    Country(code: 'GW', name: 'Guinea-Bissau', flag: 'GW', region: 'Africa'),
    Country(code: 'GQ', name: 'Equatorial Guinea', flag: 'GQ', region: 'Africa'),
    Country(code: 'MU', name: 'Mauritius', flag: 'MU', region: 'Africa'),
    Country(code: 'SZ', name: 'Eswatini', flag: 'SZ', region: 'Africa'),
    Country(code: 'DJ', name: 'Djibouti', flag: 'DJ', region: 'Africa'),
    Country(code: 'KM', name: 'Comoros', flag: 'KM', region: 'Africa'),
    Country(code: 'CV', name: 'Cape Verde', flag: 'CV', region: 'Africa'),
    Country(code: 'SC', name: 'Seychelles', flag: 'SC', region: 'Africa'),
    Country(code: 'ST', name: 'Sao Tome and Principe', flag: 'ST', region: 'Africa'),

    // Oceania
    Country(code: 'AU', name: 'Australia', flag: 'AU', region: 'Oceania'),
    Country(code: 'NZ', name: 'New Zealand', flag: 'NZ', region: 'Oceania'),
    Country(code: 'FJ', name: 'Fiji', flag: 'FJ', region: 'Oceania'),
    Country(code: 'PG', name: 'Papua New Guinea', flag: 'PG', region: 'Oceania'),
    Country(code: 'SB', name: 'Solomon Islands', flag: 'SB', region: 'Oceania'),
    Country(code: 'VU', name: 'Vanuatu', flag: 'VU', region: 'Oceania'),
    Country(code: 'WS', name: 'Samoa', flag: 'WS', region: 'Oceania'),
    Country(code: 'TO', name: 'Tonga', flag: 'TO', region: 'Oceania'),
    Country(code: 'KI', name: 'Kiribati', flag: 'KI', region: 'Oceania'),
    Country(code: 'PW', name: 'Palau', flag: 'PW', region: 'Oceania'),
    Country(code: 'MH', name: 'Marshall Islands', flag: 'MH', region: 'Oceania'),
    Country(code: 'FM', name: 'Micronesia', flag: 'FM', region: 'Oceania'),
    Country(code: 'NR', name: 'Nauru', flag: 'NR', region: 'Oceania'),
    Country(code: 'TV', name: 'Tuvalu', flag: 'TV', region: 'Oceania'),
    Country(code: 'CK', name: 'Cook Islands', flag: 'CK', region: 'Oceania'),
    Country(code: 'NU', name: 'Niue', flag: 'NU', region: 'Oceania'),
    Country(code: 'TK', name: 'Tokelau', flag: 'TK', region: 'Oceania'),
    Country(code: 'AS', name: 'American Samoa', flag: 'AS', region: 'Oceania'),
    Country(code: 'WF', name: 'Wallis and Futuna', flag: 'WF', region: 'Oceania'),
    Country(code: 'PF', name: 'French Polynesia', flag: 'PF', region: 'Oceania'),
    Country(code: 'NC', name: 'New Caledonia', flag: 'NC', region: 'Oceania'),
    Country(code: 'GU', name: 'Guam', flag: 'GU', region: 'Oceania'),
    Country(code: 'MP', name: 'Northern Mariana Islands', flag: 'MP', region: 'Oceania'),
  ];
}
