import 'package:flutter/foundation.dart'; // 👈 Added for @immutable
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 1️⃣ THE STATE (holds points and scans)
@immutable
class PointsState {
  final int totalPoints;
  final int totalScans;

  const PointsState({this.totalPoints = 0, this.totalScans = 0});

  // copyWith helper for cleaner, immutable updates
  PointsState copyWith({int? totalPoints, int? totalScans}) {
    return PointsState(
      totalPoints: totalPoints ?? this.totalPoints,
      totalScans: totalScans ?? this.totalScans,
    );
  }
}

/// 2️⃣ THE NOTIFIER (handles logic)
class PointsService extends Notifier<PointsState> {
  @override
  PointsState build() {
    // 💡 TODO: For a production release, replace these hardcoded initial values
    // by loading them from SharedPreferences or a backend database.
    return const PointsState(totalPoints: 1240, totalScans: 45);
  }

  void addPoints(int points) {
    // Prevent updating state if no points were earned
    if (points <= 0) return;

    // Update state immutably
    state = state.copyWith(
      totalPoints: state.totalPoints + points,
      totalScans: state.totalScans + 1,
    );
  }

  void resetStats() {
    state = const PointsState(totalPoints: 0, totalScans: 0);
  }
}

/// 3️⃣ THE PROVIDER (exposes the Notifier)
final pointsServiceProvider = NotifierProvider<PointsService, PointsState>(PointsService.new);