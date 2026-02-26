import 'dart:convert';
import 'package:flutter/foundation.dart'; // 🌟 Added for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../controllers/centers_controller.dart';
import '../models/recycleingcenter_model.dart';

class CentersScreen extends ConsumerWidget {
  const CentersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(centersProvider);
    final controller = ref.read(centersProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      appBar: AppBar(
        title: const Text("Recycling Centers", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // 🌟 Re-center button to find the user again
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () => centersAsync.whenData((centers) {
              if (centers.isNotEmpty) {
                controller.animateToCenter(
                    centers.first.location!.latitude,
                    centers.first.location!.longitude
                );
              }
            }),
          )
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: GoogleMap(
              // 🌟 Dynamic initial position based on first result found
              initialCameraPosition: CameraPosition(
                target: centersAsync.maybeWhen(
                  data: (centers) => centers.isNotEmpty
                      ? LatLng(centers.first.location!.latitude, centers.first.location!.longitude)
                      : const LatLng(3.107, 101.606), // Default to PJ/KL area
                  orElse: () => const LatLng(3.107, 101.606),
                ),
                zoom: 12.0,
              ),
              onMapCreated: (GoogleMapController gController) {
                controller.mapController = gController;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: centersAsync.maybeWhen(
                data: (centers) => centers.map((c) => Marker(
                  markerId: MarkerId(c.placeId ?? c.name),
                  position: LatLng(c.location!.latitude, c.location!.longitude),
                  infoWindow: InfoWindow(
                    title: c.name,
                    snippet: c.acceptedCategories.join(', '),
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                )).toSet(),
                orElse: () => <Marker>{},
              ),
            ),
          ),

          _buildFilterBar(ref, controller),

          Expanded(
            child: centersAsync.when(
              data: (centers) {
                final filtered = controller.selectedCategory == "All"
                    ? centers
                    : centers.where((c) => c.acceptedCategories.contains(controller.selectedCategory)).toList();

                if (filtered.isEmpty) {
                  return const Center(
                      child: Text("No centers found nearby.", style: TextStyle(color: Colors.grey))
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildCenterCard(context, filtered[index], controller),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.green)),
              error: (err, _) => Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(WidgetRef ref, CentersController controller) {
    final categories = ["All", "E-Waste", "Plastic", "Paper", "Glass", "Metal"];
    final current = controller.selectedCategory;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: categories.map((cat) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(cat),
            selected: current == cat,
            onSelected: (_) => controller.setFilter(cat),
            selectedColor: Colors.green,
            labelStyle: TextStyle(color: current == cat ? Colors.white : Colors.black87),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCenterCard(BuildContext context, RecyclingCenterModel center, CentersController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => controller.animateToCenter(center.location!.latitude, center.location!.longitude),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.location_on, color: Colors.green)
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(center.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(center.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: center.acceptedCategories.map((cat) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cat == "E-Waste" ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(cat, style: TextStyle(fontSize: 10, color: cat == "E-Waste" ? Colors.orange[800] : Colors.blue[800], fontWeight: FontWeight.bold)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.directions_rounded, color: Colors.blue),
                    onPressed: () => _openDirections(center.location!.latitude, center.location!.longitude),
                    tooltip: "Get Directions",
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, color: Colors.green),
                    onPressed: () => _callCenter(context, center.placeId),
                    tooltip: "Call Center",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDirections(double lat, double lng) async {
    // 🌟 URL Intent to open Google Maps directly
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri url = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch routing for $url");
    }
  }

  Future<void> _callCenter(BuildContext context, String? placeId) async {
    if (placeId == null || placeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contact info unavailable.")));
      return;
    }

    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    String targetUrl = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=formatted_phone_number&key=$apiKey';

    // 🌟 THE CORS FIX (Applied to Phone details as well)
    if (kIsWeb) {
      targetUrl = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';
    }

    try {
      final response = await http.get(Uri.parse(targetUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final phoneNumber = data['result']?['formatted_phone_number'];

        if (phoneNumber != null) {
          final Uri phoneUri = Uri.parse('tel:$phoneNumber');
          if (await canLaunchUrl(phoneUri)) {
            await launchUrl(phoneUri);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No phone number found.")));
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Network error.")));
      }
    }
  }
}