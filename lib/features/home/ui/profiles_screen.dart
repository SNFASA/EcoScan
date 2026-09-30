import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/user_controller.dart';
import 'package:ecoscan/features/auth/logic/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../models/user_model.dart';

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
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    width: 40, 
                    height: 4, 
                    decoration: const BoxDecoration(
                      color: Colors.black12, 
                      borderRadius: BorderRadius.all(Radius.circular(10))
                    )
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (mounted) Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Take a Photo'),
                onTap: () async {
                  final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                  if (mounted) Navigator.pop(context, image);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
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
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      body: ref.watch(userControllerProvider(firebaseUser.uid)).when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.green)),
            error: (e, _) => Center(child: Text("Error: $e")),
            data: (user) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      // FIXED: Removed 'const' from here because 'user' is dynamic
                      _buildHeaderAndFloatingCard(context, user),
                      const SizedBox(height: 100),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Eco Statistics", 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 16),
                            _buildStatsSection(user),
                            const SizedBox(height: 40),
                            const Text("Account Settings", 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 16),
                            _buildActionButtons(user),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildHeaderAndFloatingCard(BuildContext context, dynamic user) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 260,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -50, right: -50, child: _circleDeco(150, Colors.white.withValues(alpha: 0.1))),
              Positioned(top: 50, left: -20, child: _circleDeco(100, Colors.white.withValues(alpha: 0.05))),
              const SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text("My Eco Profile", 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -80,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (user.profileurl != null && user.profileurl.isNotEmpty)
                                ? NetworkImage(user.profileurl)
                                : null,
                        child: (_pickedImage == null && (user.profileurl == null || user.profileurl.isEmpty))
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(user.username,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Text(user.rankTier,
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(dynamic user) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _statCard("Eco Points", user.ecoPoints.toString(), Icons.stars, Colors.amber),
        _statCard("Weekly", user.weeklyPoints.toString(), Icons.auto_graph, Colors.green),
        _statCard("Scans", user.totalScans.toString(), Icons.recycling, Colors.teal),
        _statCard("CO₂ Offset", "${user.co2Offset.toStringAsFixed(1)}kg", Icons.eco, Colors.lightGreen),
        _statCard("Streak", "${user.streak}d", Icons.whatshot, Colors.redAccent),
        _statCard("Level", user.rankTier.split(' ')[0], Icons.bolt, Colors.orange),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(UserModel user) {
    return Column(
      children: [
        _fullWidthButton(
          icon: Icons.person_outline,
          label: "Edit Profile Details",
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(user: user))),
        ),
        const SizedBox(height: 12),
        _fullWidthButton(
          icon: Icons.lock_outline,
          label: "Change Password",
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
        ),
        const SizedBox(height: 12),
        _fullWidthButton(
          icon: Icons.logout_rounded,
          label: "Log Out",
          color: Colors.redAccent,
          isOutlined: true,
          onTap: () async {
            final confirm = await _showConfirmLogout();
            if (confirm == true) {
              await ref.read(authProvider.notifier).logout();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            }
          },
        ),
      ],
    );
  }

  Widget _fullWidthButton({required IconData icon, required String label, required Color color, required VoidCallback onTap, bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity,
      child: isOutlined 
      ? OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        )
      : ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 20),
          label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
    );
  }

  Future<bool?> _showConfirmLogout() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to leave? Your eco-progress is saved!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _circleDeco(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}