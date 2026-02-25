import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
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
      ),
      body: Column(
        children: [
          // 1. MAP SECTION (Top) - Now 100% Free!
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: FlutterMap(
              mapController: controller.mapController,
              options: const MapOptions(
                initialCenter: LatLng(1.85, 103.08), // Centered on campus
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ecoscan',
                ),
                centersAsync.maybeWhen(
                  data: (centers) => MarkerLayer(
                    markers: centers.map((c) => Marker(
                      point: LatLng(c.location!.latitude, c.location!.longitude),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                    )).toList(),
                  ),
                  orElse: () => const MarkerLayer(markers: []),
                ),
              ],
            ),
          ),

          // 2. CHIP FILTERS
          _buildFilterBar(ref, controller),

          // 3. LIST SECTION (Bottom)
          Expanded(
            child: centersAsync.when(
              data: (centers) {
                final filtered = controller.selectedCategory == "All"
                    ? centers
                    : centers.where((c) => c.acceptedCategories.contains(controller.selectedCategory)).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildCenterCard(filtered[index], controller),
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
    final categories = ["All", "Plastic", "Paper", "Glass", "Metal"];
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
            labelStyle: TextStyle(color: current == cat ? Colors.white : Colors.black),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCenterCard(RecyclingCenterModel center, CentersController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.location_on, color: Colors.green)),
        title: Text(center.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(center.address, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Text("Accepted: ${center.acceptedCategories.join(', ')}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.directions_rounded, color: Colors.blue),
          onPressed: () => _openDirections(center.location!.latitude, center.location!.longitude),
        ),
        onTap: () => controller.animateToCenter(center.location!.latitude, center.location!.longitude),
      ),
    );
  }

  // 🌟 BONUS FIX: Now actually dynamically routes to the specific lat/long of the center!
  Future<void> _openDirections(double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch routing for $url");
    }
  }
}