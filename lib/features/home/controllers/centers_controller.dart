import 'package:flutter_map/flutter_map.dart'; // 🌟 CHANGED: Replaced Google Maps
import 'package:latlong2/latlong.dart';        // 🌟 CHANGED: Using free LatLng
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recycleingcenter_model.dart';
import '../repositories/centers_repository.dart'; // Make sure this path matches your repo

final centersProvider = StreamNotifierProvider<CentersController, List<RecyclingCenterModel>>(() {
  return CentersController();
});

class CentersController extends StreamNotifier<List<RecyclingCenterModel>> {
  // 🌟 CHANGED: Initialized the OpenStreetMap controller
  final MapController mapController = MapController();
  String selectedCategory = "All";

  @override
  Stream<List<RecyclingCenterModel>> build() {
    return ref.read(centersRepositoryProvider).getCentersStream();
  }

  void setFilter(String category) {
    selectedCategory = category;
    ref.invalidateSelf(); // Refresh the stream and UI
  }

  // 🌟 CHANGED: Using flutter_map's `.move()` syntax instead of animateCamera
  void animateToCenter(double lat, double lng) {
    mapController.move(LatLng(lat, lng), 15.0);
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return await Geolocator.getCurrentPosition();
  }
}