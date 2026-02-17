import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. THE STATE (Holds your numbers safely)
class PointsState {
  final int totalPoints;
  final int totalScans;

  // Constructor with default values
  PointsState({this.totalPoints = 1240, this.totalScans = 45});
}

// 2. THE NOTIFIER (Handles the logic)
class PointsService extends Notifier<PointsState> {
  @override
  PointsState build() {
    // Initialize the state when the app starts
    return PointsState();
  }

  void addPoints(int points) {
    // In modern Riverpod, we don't 'notify listeners'.
    // Instead, we create a new state, and the UI updates automatically.
    state = PointsState(
      totalPoints: state.totalPoints + points,
      totalScans: state.totalScans + 1,
    );
  }

  void resetStats() {
    state = PointsState(totalPoints: 0, totalScans: 0);
  }
}

// 3. THE PROVIDER (Exposes the logic to the app)
final pointsServiceProvider = NotifierProvider<PointsService, PointsState>(PointsService.new);