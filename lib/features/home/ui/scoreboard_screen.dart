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
      backgroundColor: const Color(0xFFF4F9F5),
      body: scoreboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
        error: (e, s) {
          debugPrint("Leaderboard Error: $e");
          debugPrint("Stack: $s");
          return Center(
            child: Text("Error: $e"),
          );
        },
        data: (leaderboard) {
          if (leaderboard.isEmpty) {
            return const Center(child: Text("No data found"));
          }

          final topThree =
              leaderboard.length >= 3 ? leaderboard.sublist(0, 3) : leaderboard;
          final theRest =
              leaderboard.length > 3 ? leaderboard.sublist(3) : [];

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeaderSection(topThree, currentUid),
                    const SizedBox(height: 80),

                    // LIST SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: theRest.asMap().entries.map((entry) {
                          final index = entry.key;
                          final user = entry.value;
                          final rank = index + 4;
                          final isMe = user.id == currentUid;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.green.shade50
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: isMe
                                    ? Border.all(
                                        color: Colors.green, width: 2)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 5),
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "#$rank",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isMe
                                              ? Colors.green[800]
                                              : Colors.grey[500]),
                                    ),
                                    const SizedBox(width: 15),
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isMe
                                          ? Colors.green
                                          : Colors.grey[100],
                                      backgroundImage:
                                          user.profileurl.isNotEmpty
                                              ? NetworkImage(
                                                  user.profileurl)
                                              : null,
                                      child: user.profileurl.isEmpty
                                          ? Text(
                                              _getInitials(
                                                  user.username),
                                              style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 12),
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                                title: Text(
                                  user.username,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isMe
                                          ? Colors.green[900]
                                          : Colors.black87),
                                ),
                                trailing: Text(
                                  "${user.weeklyPoints} pts",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isMe
                                          ? Colors.green[800]
                                          : Colors.green[700]),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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

  // ================= HEADER SECTION =================

  Widget _buildHeaderSection(
      List<UserModel> topThree, String? currentUid) {
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
              Positioned(
                  top: -50,
                  right: -50,
                  child: _circleDeco(
                      150, Colors.white.withOpacity(0.1))),
              Positioned(
                  top: 50,
                  left: -20,
                  child: _circleDeco(
                      100, Colors.white.withOpacity(0.05))),
              const Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Text("Leaderboard",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("Weekly Top Heroes 🏆",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // FLOATING PODIUM CARD
        Positioned(
          bottom: -50,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (topThree.length > 1)
                  _buildPodiumPlace(
                      2, topThree[1], currentUid),
                if (topThree.isNotEmpty)
                  _buildPodiumPlace(
                      1, topThree[0], currentUid),
                if (topThree.length > 2)
                  _buildPodiumPlace(
                      3, topThree[2], currentUid),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumPlace(
      int rank, UserModel user, String? currentUid) {
    final isMe = user.id == currentUid;

    final Color color = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey.shade400
            : Colors.brown.shade400;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank == 1)
            const Icon(Icons.emoji_events,
                color: Colors.amber, size: 24),
          CircleAvatar(
            radius: rank == 1 ? 25 : 18,
            backgroundColor:
                isMe ? Colors.green : color.withOpacity(0.2),
            backgroundImage: user.profileurl.isNotEmpty
                ? NetworkImage(user.profileurl)
                : null,
            child: user.profileurl.isEmpty
                ? Text(
                    _getInitials(user.username),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black87),
                  )
                : null,
          ),
          const SizedBox(height: 5),
          Text(
            user.username.split(' ')[0],
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.green[900] : Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "${user.weeklyPoints}",
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.green : color),
          ),
          const SizedBox(height: 5),
          Container(
            height: rank == 1 ? 60 : (rank == 2 ? 40 : 30),
            width: double.infinity,
            margin:
                const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
                color: isMe
                    ? Colors.green.withOpacity(0.3)
                    : color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(5)),
            alignment: Alignment.center,
            child: Text(
              "$rank",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMe ? Colors.green : color,
                  fontSize: 18),
            ),
          )
        ],
      ),
    );
  }

  Widget _circleDeco(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "??";
    final parts = name.split(" ");
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}