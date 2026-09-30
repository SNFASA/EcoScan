import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/centers_controller.dart';
import '../models/recycleingcenter_model.dart';

class CentersScreen extends ConsumerWidget {
  const CentersScreen({super.key});
  String _getDistance(double startLat, double startLng, double endLat, double endLng) {
    double distanceInMeters = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    double distanceInKm = distanceInMeters / 1000;
    return "${distanceInKm.toStringAsFixed(1)} km";
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(centersProvider);
    final controller = ref.read(centersProvider.notifier);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Header with Deeply Overlapping Map (-350)
                _buildHeaderSection(context, centersAsync, controller),

                // Adjusted spacer to prevent map from covering the text below
                const SizedBox(height: 380), 

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Filter Categories",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      _buildFilterBar(ref, controller),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Nearby Centers",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          centersAsync.whenData((scans) => Text(
                                "${scans.length} locations found",
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              )).maybeWhen(orElse: () => const SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 15),
                      centersAsync.when(
                        data: (centers) {
                          final filtered = controller.selectedCategory == "All"
                              ? centers
                              : centers
                                  .where((c) => c.acceptedCategories.contains(controller.selectedCategory))
                                  .toList();

                          if (filtered.isEmpty) {
                            return _buildEmptyState();
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _buildCenterCard(context, filtered[index], controller),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: Center(child: CircularProgressIndicator(color: Colors.green)),
                        ),
                        error: (err, _) => Center(child: Text("Error: $err")),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.location_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No centers found for this category.",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    AsyncValue<List<RecyclingCenterModel>> centersAsync,
    CentersController controller,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -50, right: -50, child: _circleDeco(150, Colors.white.withValues(alpha: 0.1))),
              Positioned(top: 50, left: -20, child: _circleDeco(100, Colors.white.withValues(alpha: 0.05))),
              Padding(
                padding: const EdgeInsets.only(top: 80, left: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Eco Locations", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    SizedBox(height: 6),
                    Text(
                      "Recycling Centers",
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        /// Floating MAP card - Moved to -350 for significant overlap
        Positioned(
          bottom: -350,
          child: Container(
            width: MediaQuery.of(context).size.width > 1000
                ? 960
                : MediaQuery.of(context).size.width * 0.9,
            height: 420,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: centersAsync.maybeWhen(
                    data: (centers) => centers.isNotEmpty
                        ? LatLng(centers.first.location!.latitude, centers.first.location!.longitude)
                        : const LatLng(3.107, 101.606),
                    orElse: () => const LatLng(3.107, 101.606),
                  ),
                  zoom: 13,
                ),
                onMapCreated: (gController) => controller.mapController = gController,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: centersAsync.maybeWhen(
                  data: (centers) => centers.map((c) => Marker(
                        markerId: MarkerId(c.placeId ?? c.name),
                        position: LatLng(c.location!.latitude, c.location!.longitude),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        infoWindow: InfoWindow(title: c.name),
                      )).toSet(),
                  orElse: () => {},
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(WidgetRef ref, CentersController controller) {
    final categories = ["All", "E-Waste", "Plastic", "Paper", "Glass", "Metal"];
    final current = controller.selectedCategory;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: categories.map((cat) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(cat),
                selected: current == cat,
                onSelected: (_) => controller.setFilter(cat),
                selectedColor: Colors.green,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                side: BorderSide(color: Colors.green.withValues(alpha: 0.1)),
                labelStyle: TextStyle(
                  color: current == cat ? Colors.white : Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            )).toList(),
      ),
    );
  }

 Widget _buildCenterCard(BuildContext context, RecyclingCenterModel center, CentersController controller) {
    // Calculate the real distance using the controller's current location
    final String realDistance = center.location != null 
        ? _getDistance(
            controller.currentLat, 
            controller.currentLng, 
            center.location!.latitude, 
            center.location!.longitude
          )
        : "N/A";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => controller.animateToCenter(center.location!.latitude, center.location!.longitude),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.green, size: 28),
                      const SizedBox(height: 4),
                      // 🌟 REAL DATA REPLACING "0.8 km"
                      Text(
                        realDistance,
                        style: const TextStyle(
                            fontSize: 10, 
                            color: Colors.blue, 
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(center.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(center.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 5,
                        children: center.acceptedCategories.map((cat) => _buildCategoryTag(cat)).toList(),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.directions_outlined, color: Colors.blueAccent),
                      onPressed: () => _openDirections(center.location!.latitude, center.location!.longitude),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_in_talk_outlined, color: Colors.green),
                      onPressed: () => _callCenter(context, center.placeId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.bold)),
    );
  }

  Widget _circleDeco(double size, Color color) {
    return Container(
        width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Future<void> _openDirections(double lat, double lng) async {
    final Uri url = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callCenter(BuildContext context, String? placeId) async {
    if (placeId == null || placeId.isEmpty) return;
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    String targetUrl =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=formatted_phone_number&key=$apiKey';
    if (kIsWeb) targetUrl = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';

    try {
      final response = await http.get(Uri.parse(targetUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final phoneNumber = data['result']?['formatted_phone_number'];
        if (phoneNumber != null) {
          final Uri phoneUri = Uri.parse('tel:$phoneNumber');
          if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
        }
      }
    } catch (e) {
      debugPrint("Call error: $e");
    }
  }
}