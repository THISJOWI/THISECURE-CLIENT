import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/auth/register.dart';

class CountryMapScreen extends StatefulWidget {
  final String? accountType;
  final String? hostingMode;
  final Map<String, dynamic>? ldapConfig;

  const CountryMapScreen({
    super.key,
    this.accountType,
    this.hostingMode,
    this.ldapConfig,
  });

  @override
  State<CountryMapScreen> createState() => _CountryMapScreenState();
}

class _CountryMapScreenState extends State<CountryMapScreen> {
  final MapController _mapController = MapController();
  String? _selectedCountry;

  // Simple mapping of coordinates to countries (Demo purpose)
  final Map<String, LatLng> _countries = {
    'Spain': const LatLng(40.4637, -3.7492),
    'United States': const LatLng(37.0902, -95.7129),
    'United Kingdom': const LatLng(55.3781, -3.4360),
    'Germany': const LatLng(51.1657, 10.4515),
    'France': const LatLng(46.2276, 2.2137),
    'Italy': const LatLng(41.8719, 12.5674),
    'Japan': const LatLng(36.2048, 138.2529),
    'China': const LatLng(35.8617, 104.1954),
    'Brazil': const LatLng(-14.2350, -51.9253),
    'Canada': const LatLng(56.1304, -106.3468),
    'Mexico': const LatLng(23.6345, -102.5528),
    'Argentina': const LatLng(-38.4161, -63.6167),
    'Colombia': const LatLng(4.5709, -74.2973),
    'India': const LatLng(20.5937, 78.9629),
    'Australia': const LatLng(-25.2744, 133.7751),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Select Country".i18n),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          tooltip: 'Back'.i18n,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Please select your country from the map".i18n,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(20.0, 0.0),
                    initialZoom: 2.0,
                    onTap: (tapPosition, point) {
                      // Optional: Implement logic to find nearest country or just rely on markers
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.thisjowi.app',
                    ),
                    MarkerLayer(
                      markers: _countries.entries.map((entry) {
                        final isSelected = _selectedCountry == entry.key;
                        return Marker(
                          point: entry.value,
                          width: 80,
                          height: 80,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCountry = entry.key;
                              });
                            },
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.primary,
                                  size: 40,
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Theme.of(context).colorScheme.secondary),
                                    ),
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_selectedCountry != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "Selected: $_selectedCountry",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedCountry == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        Text("Next".i18n, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
