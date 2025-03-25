import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../cubits/FetchMosquesCubit.dart';
import '../Model/MosqueModel.dart';
import '../Provider/MosqueProvider.dart';
import '../app/routes.dart';
import 'MostNeededMosquesFromMap.dart';

class QatarMosques extends StatefulWidget {
  /// If `isFromCheckout` is `true`, we will return the selected mosque back
  /// to the caller by popping with a [MosqueModel].
  ///
  /// If it's `false`, we fall back to the old behavior:
  /// going to `Routers.mostNeededMosquesScreen` after confirmation.
  final bool isFromCheckout;

  const QatarMosques({
    Key? key,
    this.isFromCheckout = false, // default to old behavior
  }) : super(key: key);

  @override
  _QatarMosquesState createState() => _QatarMosquesState();
}

class _QatarMosquesState extends State<QatarMosques> {
  // Default center (Doha, Qatar)
  static const LatLng _center = LatLng(25.276987, 51.520008);

  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  // Get the current location using geolocator.
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled.
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied.
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever.
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = position;
    });
  }

  // Search for a location using the geocoding package.
  void _searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        LatLng searchedLocation = LatLng(location.latitude, location.longitude);
        // Move the map to the searched location.
        _mapController.move(searchedLocation, 15.0);
      }
    } catch (e) {
      // Handle any errors, e.g. show a snackbar.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location not found: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mosqueProvider = context.watch<MosqueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Mosque for Delivery"),
        // Adding a search bar in the AppBar.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: _searchLocation,
              decoration: InputDecoration(
                hintText: "Search location...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: const Color.fromARGB(255, 16, 122, 101),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<FetchMosquesCubit, FetchMosquesState>(
        builder: (context, state) {
          if (state is FetchMosquesInProgress) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FetchMosquesFail) {
            return Center(child: Text("Error: ${state.error}"));
          } else if (state is FetchMosquesSuccess) {
            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),

                // Current location marker (if available).
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),

                // Mosque markers
                MarkerLayer(
                  markers: state.mosques.map((mosque) {
                    final bool isSelected =
                        (mosqueProvider.selectedMosque?.id == mosque.id);
                    return Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(mosque.latitude, mosque.longitude),
                      child: GestureDetector(
                        onTap: () => _showConfirmationDialog(context, mosque),
                        child: Icon(
                          Icons.location_on,
                          color: isSelected ? Colors.green : Colors.red,
                          size: 40,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }
          return const Center(child: Text("No mosques available"));
        },
      ),
      // Floating Action Button to center the map on the current location.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _mapController.move(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              15.0,
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  /// Displays a confirmation dialog when a marker is tapped.
  void _showConfirmationDialog(BuildContext context, MosqueModel mosque) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Confirm Mosque Selection"),
          content: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mosque Name:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    (mosque.name != null && mosque.name!.isNotEmpty)
                        ? mosque.name!
                        : "Mosque at (${mosque.latitude}, ${mosque.longitude})",
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Address:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    (mosque.address != null && mosque.address!.isNotEmpty)
                        ? mosque.address!
                        : "No address provided",
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Coordinates:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("(${mosque.latitude}, ${mosque.longitude})"),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // dismisses the dialog
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Save to provider
                context.read<MosqueProvider>().setSelectedMosque(mosque);

                if (widget.isFromCheckout) {
                  // If we are from Checkout, return MosqueModel to caller:
                  Navigator.pop(context);           // close the dialog
                  Navigator.pop(context, mosque);   // pop the entire map screen + pass MosqueModel
                } else {
                  // Old behavior: push replacement to `mostNeededMosquesScreen`
                  Navigator.pop(context); // close the dialog
                  Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MostNeededMosquesFromMap(
          mosques: (context.read<FetchMosquesCubit>().state is FetchMosquesSuccess)
              ? (context.read<FetchMosquesCubit>().state as FetchMosquesSuccess).mosques
              : [],
        ),
      ),
    );
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }
}
