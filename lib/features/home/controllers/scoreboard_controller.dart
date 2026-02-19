import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/scoreboard_repository.dart';

// Provide the Repository (Make sure this exists in your repo file)
final scoreboardRepositoryProvider = Provider((ref) => ScoreboardRepository());

// The AsyncNotifier Provider
final scoreboardProvider = AsyncNotifierProvider<ScoreboardController, List<UserModel>>(() {
  return ScoreboardController();
});

class ScoreboardController extends AsyncNotifier<List<UserModel>> {
  
  @override
  FutureOr<List<UserModel>> build() async {
    return _fetchLeaderboard();
  }

  // Pure Dart Week Number Calculation (No 'intl' package needed)
  String _getCurrentWeekId() {
    DateTime now = DateTime.now();
    // ISO 8601 week number logic
    int dayOfYear = int.parse(now.difference(DateTime(now.year, 1, 1)).inDays.toString());
    int weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
    
    return "${now.year}-W${weekNumber.toString().padLeft(2, '0')}";
  }

  Future<List<UserModel>> _fetchLeaderboard() async {
    // Get current week ID to potentially filter or log
    final currentWeek = _getCurrentWeekId();
    print("Fetching leaderboard for: $currentWeek");

    final repository = ref.read(scoreboardRepositoryProvider);
    return await repository.getTopWeeklyUsers(50);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchLeaderboard());
  }
}