import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recycleingcenter_model.dart';
import '../repositories/centers_repository.dart';

final centersProvider = StreamNotifierProvider<CentersController, List<RecyclingCenterModel>>(() {
  return CentersController();
});

class CentersController extends StreamNotifier<List<RecyclingCenterModel>> {
  GoogleMapController? mapController;
  String selectedCategory = "All";

  @override
  Stream<List<RecyclingCenterModel>> build() {
    return ref.read(centersRepositoryProvider).getCentersStream();
  }

  void setFilter(String category) {
    selectedCategory = category;
    ref.invalidateSelf(); // Refresh the stream and UI
  }

  // Fly the map to a specific location
  void animateToCenter(double lat, double lng) {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 15),
      ),
    );
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