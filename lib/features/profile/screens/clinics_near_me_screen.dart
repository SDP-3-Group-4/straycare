import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ClinicsNearMeScreen extends StatefulWidget {
  const ClinicsNearMeScreen({super.key});

  @override
  State<ClinicsNearMeScreen> createState() => _ClinicsNearMeScreenState();
}

class _ClinicsNearMeScreenState extends State<ClinicsNearMeScreen> {
  final MapController _mapController = MapController();
  List<dynamic> _clinics = [];
  bool _isLoading = true;
  LatLng? _currentPosition;
  String _statusMessage = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check Service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Location services are disabled. Please enable GPS.';
          _isLoading = false;
        });
        _showErrorDialog('GPS Disabled', 'Please enable location services.');
      }
      return;
    }

    // Check Permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Location permissions are denied';
            _isLoading = false;
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _statusMessage =
              'Location permissions are permanently denied, we cannot request permissions.';
          _isLoading = false;
        });
      }
      return;
    }

    // Get Position
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _statusMessage = 'Searching for clinics...';
        });
        _fetchClinics();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error getting location: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchClinics() async {
    if (_currentPosition == null) return;

    // Nominatim Search API (Free, OSM)
    // q=veterinary
    // format=json
    // limit=10
    // viewbox/bounded could be used, but lat/lon bias works too if generalized
    // Actually Nominatim doesn't take lat/lon for biasing easily without viewbox,
    // but we can filter results or use 'near' logic manually if the API supports it.
    // Better: https://nominatim.openstreetmap.org/search?q=veterinary&format=json&limit=20&viewbox=...&bounded=1
    // Easier: Just search 'veterinary' globally? No.
    // Use 'amenity=veterinary' near coordinate?
    // Let's use simple search with viewbox around user.
    // ~0.2 degree is roughly 22km.
    final boxStr =
        '${_currentPosition!.longitude - 0.2},${_currentPosition!.latitude + 0.2},${_currentPosition!.longitude + 0.2},${_currentPosition!.latitude - 0.2}';

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=veterinary&format=json&limit=20&viewbox=$boxStr&bounded=1&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'StrayCareDemoApp/1.0'}, // Required by OSM
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (mounted) {
          setState(() {
            _clinics = data;
            _isLoading = false;
          });

          // Fit Camera to show all results + user
          if (_clinics.isNotEmpty && _currentPosition != null) {
            List<LatLng> points = [_currentPosition!];
            for (var clinic in _clinics) {
              points.add(
                LatLng(
                  double.parse(clinic['lat']),
                  double.parse(clinic['lon']),
                ),
              );
            }

            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(points),
                padding: const EdgeInsets.all(50),
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to load clinics');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error fetching clinics: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchMapsUrl(double lat, double lon) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not launch maps')));
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Okay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clinics Near Me',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: _currentPosition == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage),
                ],
              ),
            )
          : Column(
              children: [
                // Map Widget
                SizedBox(
                  height: 300,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition!,
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.straycare',
                      ),
                      MarkerLayer(
                        markers: [
                          // User Location
                          Marker(
                            point: _currentPosition!,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                          // Clinics
                          ..._clinics.map((clinic) {
                            final lat = double.parse(clinic['lat']);
                            final lon = double.parse(clinic['lon']);
                            return Marker(
                              point: LatLng(lat, lon),
                              width: 80,
                              height: 80,
                              child: GestureDetector(
                                onTap: () {
                                  // Highlight via Scrollable not implemented yet for simplicity
                                  // Just show name
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        clinic['display_name'] ?? 'Clinic',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 35,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                // List Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                  child: Text(
                    'Found ${_clinics.length} Veterinary Clinics nearby',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                  ),
                ),

                // Clinic List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _clinics.isEmpty
                      ? const Center(child: Text('No clinics found nearby.'))
                      : ListView.builder(
                          itemCount: _clinics.length,
                          itemBuilder: (context, index) {
                            final clinic = _clinics[index];
                            final name =
                                clinic['display_name']?.split(',')[0] ??
                                'Unknown Clinic';
                            final address =
                                clinic['display_name'] ?? 'No address';
                            final lat = double.parse(clinic['lat']);
                            final lon = double.parse(clinic['lon']);

                            final isDarkMode =
                                Theme.of(context).brightness == Brightness.dark;

                            return Card(
                              elevation: 0, // No Shadow
                              color: isDarkMode
                                  ? Color(0xFF1E1E1E)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDarkMode
                                      ? Colors.grey[800]!
                                      : Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDarkMode
                                      ? Colors.grey[800]
                                      : const Color(0xFFF3E5F5),
                                  child: Icon(
                                    Icons.local_hospital,
                                    color: isDarkMode
                                        ? Colors.purpleAccent
                                        : const Color(0xFF9C27B0),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.directions,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _launchMapsUrl(lat, lon),
                                ),
                                onTap: () {
                                  _mapController.move(LatLng(lat, lon), 15);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
