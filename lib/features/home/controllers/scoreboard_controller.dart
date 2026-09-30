import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/scoreboard_repository.dart';

// Provide the Repository
final scoreboardRepositoryProvider = Provider((ref) => ScoreboardRepository());

// 🌟 CHANGED: Upgraded to StreamNotifierProvider for real-time magic
final scoreboardProvider = StreamNotifierProvider<ScoreboardController, List<UserModel>>(() {
  return ScoreboardController();
});

// 🌟 CHANGED: Now extends StreamNotifier
class ScoreboardController extends StreamNotifier<List<UserModel>> {

  @override
  Stream<List<UserModel>> build() {
    return _streamLeaderboard();
  }

  // Your brilliant Pure Dart Week Number Calculation stays exactly the same!
  String _getCurrentWeekId() {
    DateTime now = DateTime.now();
    int dayOfYear = int.parse(now.difference(DateTime(now.year, 1, 1)).inDays.toString());
    int weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();

    return "${now.year}-W${weekNumber.toString().padLeft(2, '0')}";
  }

  Stream<List<UserModel>> _streamLeaderboard() {
    final currentWeek = _getCurrentWeekId();
    print("Streaming live leaderboard for: $currentWeek");

    final repository = ref.read(scoreboardRepositoryProvider);
    // 🌟 CHANGED: Now calls the Stream method we created in the repository
    return repository.getTopWeeklyUsersStream(50);
  }

// Note: We completely removed the refresh() method!
// Because it's a live stream, it auto-refreshes the second Firestore changes.
}