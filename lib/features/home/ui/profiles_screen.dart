import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/user_controller.dart';
import 'package:ecoscan/features/auth/logic/auth_provider.dart';

import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

/// IMPORTANT:
/// - NOT a ConsumerStatefulWidget (prevents mouse_tracker crash)
/// - Riverpod Consumer is scoped only where needed
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                final image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                Navigator.pop(context, image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                final image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                Navigator.pop(context, image);
              },
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      body: Consumer(
        builder: (context, ref, _) {
          final userAsync =
              ref.watch(userControllerProvider(firebaseUser.uid));

          return userAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text("Error: $e")),
            data: (user) => _ProfileBody(
              user: user,
              pickedImage: _pickedImage,
              onPickImage: _pickImage,
              onLogout: () async {
                await ref.read(authProvider.notifier).logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (_) => false);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

/// UI BODY (separated to avoid rebuild crashes)
class _ProfileBody extends StatelessWidget {
  final dynamic user;
  final File? pickedImage;
  final VoidCallback onPickImage;
  final VoidCallback onLogout;

  const _ProfileBody({
    required this.user,
    required this.pickedImage,
    required this.onPickImage,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              /// Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.green[100],
                    backgroundImage:
                        pickedImage != null ? FileImage(pickedImage!) : null,
                    child: pickedImage == null
                        ? const Icon(Icons.person,
                            size: 60, color: Colors.green)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Colors.green,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onPickImage,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.edit,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text(user.username,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user.email,
                  style: TextStyle(color: Colors.grey[700])),

              const SizedBox(height: 32),

              /// Stats
              isDesktop
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _stats(user, horizontal: true),
                      ),
                    )
                  : Column(
                      children: _stats(user, horizontal: false),
                    ),

              const SizedBox(height: 32),

              /// Buttons
              Wrap(
                spacing: 20,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _actionButton(
                    icon: Icons.edit,
                    label: "Edit Profile",
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                  _actionButton(
                    icon: Icons.lock,
                    label: "Change Password",
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const ChangePasswordScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              _actionButton(
                icon: Icons.logout,
                label: "Logout",
                color: Colors.redAccent,
                width: 200,
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _stats(user, {required bool horizontal}) {
    final cards = [
      _statCard("Eco Points", user.ecoPoints.toString(),
          Icons.stars, Colors.amber),
      _statCard("Weekly Points", user.weeklyPoints.toString(),
          Icons.auto_graph, Colors.green),
      _statCard("Total Scans", user.totalScans.toString(),
          Icons.recycling, Colors.teal),
      _statCard("CO₂ Offset",
          "${user.co2Offset.toStringAsFixed(2)} kg",
          Icons.eco, Colors.lightGreen),
      _statCard("Rank", user.rankTier,
          Icons.emoji_events, Colors.orange),
      _statCard("Streak", "${user.streak} days",
          Icons.whatshot, Colors.redAccent),
    ];

    return horizontal
        ? cards
            .map((e) =>
                Padding(padding: const EdgeInsets.only(right: 20), child: e))
            .toList()
        : cards
            .map((e) =>
                Padding(padding: const EdgeInsets.only(bottom: 16), child: e))
            .toList();
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double width = 160,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}
