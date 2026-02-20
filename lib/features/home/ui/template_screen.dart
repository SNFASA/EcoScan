import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemplateScreen extends ConsumerWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5), // 🎨 Minty White Background
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // 📏 The 800px Rule
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 1. 🌿 THE ECO-HEADER & FLOATING CARD
                _buildHeaderAndFloatingCard(),

                const SizedBox(height: 80), // Spacing to clear the floating card

                // 2. 📝 MAIN PAGE CONTENT GOES HERE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Section Title",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),

                      // 3. 🧩 SOFT UI ELEMENTS (Example Card)
                      _buildContentCard(),

                      const SizedBox(height: 30),

                      // Add more content here!

                      const SizedBox(height: 100), // Bottom padding for scroll clearance
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

  // --- REUSABLE COMPONENTS FOR THIS PAGE ---

  Widget _buildHeaderAndFloatingCard() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // 🟩 The Green Gradient Header
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
              // 🫧 Decorative Circles
              Positioned(top: -50, right: -50, child: _circleDeco(150, Colors.white.withOpacity(0.1))),
              Positioned(top: 50, left: -20, child: _circleDeco(100, Colors.white.withOpacity(0.05))),

              // 🅰️ Header Text
              const Padding(
                padding: EdgeInsets.only(top: 80, left: 30, right: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Page Title", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Subtitle or brief description here.", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ☁️ The Overlapping Floating Card
        Positioned(
          bottom: -50,
          child: Container(
            width: 340, // Standard mobile width
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2), // ❇️ Soft Green Glow
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text("Floating Card Content", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // 🟢 20px Radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // Super subtle shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🎨 Soft UI Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1), // 10% Opacity Background
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 15),

          // 🔤 Text Content
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Standard Content Card", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text("Use this for lists, settings, or details.", style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleDeco(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}