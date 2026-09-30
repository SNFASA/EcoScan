import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../controllers/scoreboard_controller.dart';
import 'package:ecoscan/features/auth/logic/auth_provider.dart';

class ScoreboardScreen extends ConsumerWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreboardAsync = ref.watch(scoreboardProvider);
    final firebaseAuth = ref.watch(firebaseAuthProvider);
    final String? currentUid = firebaseAuth.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5), // Standard EcoScan background
      body: scoreboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
        error: (e, s) {
          debugPrint("Leaderboard Error: $e");
          return Center(child: Text("Error loading data: $e"));
        },
        data: (leaderboard) {
          if (leaderboard.isEmpty) {
            return const Center(child: Text("No eco-heroes yet!"));
          }

          final topThree = leaderboard.length >= 3 ? leaderboard.sublist(0, 3) : leaderboard;
          final theRest = leaderboard.length > 3 ? leaderboard.sublist(3) : [];

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  children: [
                    // Enhanced Header with Podium
                    _buildHeaderSection(topThree, currentUid),
                    const SizedBox(height: 80),

                    // Ranking List Header
                    if (theRest.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Top Contributors",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ),

                    // Refined Ranking List
                    if (theRest.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: theRest.length,
                          itemBuilder: (context, index) {
                            final user = theRest[index];
                            final rank = index + 4;
                            final isMe = user.id == currentUid;
                            return _buildRankItem(user, rank, isMe);
                          },
                        ),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= RANK ITEM COMPONENT =================

  Widget _buildRankItem(UserModel user, int rank, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isMe ? Border.all(color: Colors.green.withValues(alpha: 0.5), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: SizedBox(
          width: 80,
          child: Row(
            children: [
              Text(
                "#$rank",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isMe ? Colors.green : Colors.grey[400],
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey[100],
                backgroundImage: user.profileurl.isNotEmpty ? NetworkImage(user.profileurl) : null,
                child: user.profileurl.isEmpty
                    ? Text(_getInitials(user.username), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
                    : null,
              ),
            ],
          ),
        ),
        title: Text(
          user.username,
          style: TextStyle(
            fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
            color: isMe ? Colors.green[900] : Colors.black87,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${user.weeklyPoints} pts",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
            ),
            if (isMe)
              const Text("YOU", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }

  // ================= HEADER & PODIUM =================

  Widget _buildHeaderSection(List<UserModel> topThree, String? currentUid) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(45),
              bottomRight: Radius.circular(45),
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -40, right: -40, child: _circleDeco(180, Colors.white.withValues(alpha: 0.1))),
              Positioned(top: 60, left: -30, child: _circleDeco(120, Colors.white.withValues(alpha: 0.05))),
              const Positioned(
                top: 70,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text("Eco Leaderboard", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("Weekly Top Heroes 🌿", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -70,
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (topThree.length > 1) _buildPodiumPlace(2, topThree[1], currentUid),
                if (topThree.isNotEmpty) _buildPodiumPlace(1, topThree[0], currentUid),
                if (topThree.length > 2) _buildPodiumPlace(3, topThree[2], currentUid),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumPlace(int rank, UserModel user, String? currentUid) {
    final isMe = user.id == currentUid;
    final double avatarSize = rank == 1 ? 32 : 24;
    final Color rankColor = rank == 1 ? Colors.amber : (rank == 2 ? Colors.blueGrey.shade300 : Colors.brown.shade300);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank == 1) const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
          CircleAvatar(
            radius: avatarSize,
            backgroundColor: isMe ? Colors.green : Colors.grey[200],
            backgroundImage: user.profileurl.isNotEmpty ? NetworkImage(user.profileurl) : null,
            child: user.profileurl.isEmpty ? Text(_getInitials(user.username), style: const TextStyle(fontSize: 10)) : null,
          ),
          const SizedBox(height: 8),
          Text(user.username.split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text("${user.weeklyPoints} pts", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          Container(
            height: rank == 1 ? 70 : (rank == 2 ? 50 : 40),
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [rankColor, rankColor.withValues(alpha: 0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            alignment: Alignment.center,
            child: Text("$rank", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ),
        ],
      ),
    );
  }

  Widget _circleDeco(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  String _getInitials(String name) {
    final parts = name.trim().split(" ");
    if (parts.length > 1) return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : "?";
  }
}