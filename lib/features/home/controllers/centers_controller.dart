import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🌟 Restored
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/recycleingcenter_model.dart';

final centersProvider = AsyncNotifierProvider<CentersController, List<RecyclingCenterModel>>(() {
  return CentersController();
});

class CentersController extends AsyncNotifier<List<RecyclingCenterModel>> {
  String selectedCategory = "All";
  GoogleMapController? mapController;

  double _currentLat = 1.85;
  double _currentLng = 103.08;

  @override
  FutureOr<List<RecyclingCenterModel>> build() async {
    // 🌟 Ensure .env is loaded before doing anything else
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: ".env");
    }
    await _determinePosition();
    return _fetchFromGooglePlaces(selectedCategory);
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      _currentLat = position.latitude;
      _currentLng = position.longitude;
    } catch (e) {
      debugPrint("⚠️ Location timeout, using fallback.");
    }
  }

  void setFilter(String category) {
    selectedCategory = category;
    state = const AsyncValue.loading();

    _fetchFromGooglePlaces(category).then((centers) {
      state = AsyncValue.data(centers);
      if (centers.isNotEmpty && mapController != null) {
        animateToCenter(centers.first.location!.latitude, centers.first.location!.longitude);
      }
    }).catchError((error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    });
  }

  void animateToCenter(double lat, double lng) {
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0),
    );
  }

 Future<List<RecyclingCenterModel>> _fetchFromGooglePlaces(String category) async {
  final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  if (apiKey.isEmpty) throw Exception("Missing API Key");

  final searchQuery = category == "All"
      ? "recycling center"
      : "${category.toLowerCase()} recycling center";

  String targetUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json?'
      'query=${Uri.encodeComponent(searchQuery)}'
      '&location=$_currentLat,$_currentLng'
      '&radius=15000'
      '&key=$apiKey';

  if (kIsWeb) {
    targetUrl = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';
  }

  try {
    // Added a timeout to prevent the 408/hanging state
    final response = await http.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Check if Google returned an error inside the 200 OK response
      if (data['status'] == 'REQUEST_DENIED') {
        throw Exception("Google API Denied: ${data['error_message']}");
      }

      final List results = data['results'] ?? [];
      return results
          .map((json) => RecyclingCenterModel.fromGooglePlaces(json as Map<String, dynamic>, category))
          .toList();
    } else {
      throw Exception("Server Error: ${response.statusCode}");
    }
  } on TimeoutException {
    throw Exception("The search took too long. Please try again.");
  } catch (e) {
    debugPrint("❌ API Error: $e");
    // Return empty list instead of crashing if you want the map to still show
    return []; 
  }
}
}