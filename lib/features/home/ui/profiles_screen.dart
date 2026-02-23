import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/user_controller.dart';
import 'package:ecoscan/features/auth/logic/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
                if (mounted) Navigator.pop(context, image);
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
                if (mounted) Navigator.pop(context, image);
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
      body: ref.watch(userControllerProvider(firebaseUser.uid)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
            data: (user) => SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderAndFloatingCard(context, user),
                  const SizedBox(height: 80),
                  _buildStatsSection(user),
                  const SizedBox(height: 32),
                  _buildActionButtons(user),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  // ================= HEADER + FLOATING CARD =================
  Widget _buildHeaderAndFloatingCard(BuildContext context, dynamic user) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Gradient Header
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
              Positioned(
                top: -50,
                right: -50,
                child: _circleDeco(150, Colors.white.withValues(alpha: 0.1)),
              ),
              Positioned(
                top: 50,
                left: -20,
                child: _circleDeco(100, Colors.white.withValues(alpha: 0.05)),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 80, left: 30),
                child: Text(
                  "My Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Floating Card
        Positioned(
          bottom: -60,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (user.profileurl != null &&
                                  user.profileurl.isNotEmpty)
                              ? NetworkImage(user.profileurl)
                              : null,
                      child: (_pickedImage == null &&
                              (user.profileurl == null ||
                                  user.profileurl.isEmpty))
                          ? const Icon(Icons.person,
                              size: 45, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  user.username,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.rankTier,
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleDeco(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // ================= STATS SECTION =================
  Widget _buildStatsSection(dynamic user) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;
            final stats = [
              _statCard("Eco Points", user.ecoPoints.toString(),
                  Icons.stars, Colors.amber),
              _statCard("Weekly Points", user.weeklyPoints.toString(),
                  Icons.auto_graph, Colors.green),
              _statCard("Total Scans", user.totalScans.toString(),
                  Icons.recycling, Colors.teal),
              _statCard("CO₂ Offset", "${user.co2Offset.toStringAsFixed(2)} kg",
                  Icons.eco, Colors.lightGreen),
              _statCard("Rank", user.rankTier, Icons.emoji_events, Colors.orange),
              _statCard("Streak", "${user.streak} days", Icons.whatshot,
                  Colors.redAccent),
            ];

            return isDesktop
                ? Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: stats,
                  )
                : Column(
                    children: stats
                        .map((e) =>
                            Padding(padding: const EdgeInsets.only(bottom: 16), child: e))
                        .toList(),
                  );
          },
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 220,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _buildActionButtons(dynamic user) {
    return Wrap(
      spacing: 20,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _actionButton(
          icon: Icons.edit,
          label: "Edit Profile",
          color: Colors.green,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
        ),
        _actionButton(
          icon: Icons.lock,
          label: "Change Password",
          color: Colors.orange,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
        ),
        _actionButton(
          icon: Icons.logout,
          label: "Logout",
          color: Colors.redAccent,
          width: 200,
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            }
          },
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double width = 180,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}