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
    // 🌟 Referencing .env properly now
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      // If this throws, it means the key name in .env doesn't match this string
      throw Exception("Missing GOOGLE_PLACES_API_KEY in .env file");
    }

    final searchQuery = category == "All"
        ? "recycling center"
        : "${category.toLowerCase()} recycling center";

    String targetUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json?'
        'query=${Uri.encodeComponent(searchQuery)}'
        '&location=$_currentLat,$_currentLng'
        '&radius=15000'
        '&key=$apiKey';

    // 🌟 CORS Proxy for Web (Crucial for Chrome/Edge)
    if (kIsWeb) {
      targetUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}';
    }

    try {
      final response = await http.get(Uri.parse(targetUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        return results
            .map((json) => RecyclingCenterModel.fromGooglePlaces(json as Map<String, dynamic>, category))
            .toList();
      } else {
        throw Exception("Google API returned ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ API Error: $e");
      throw Exception("Check your internet connection or API key restrictions.");
    }
  }
}