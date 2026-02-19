import 'package:flutter_riverpod/flutter_riverpod.dart';

class PointsService with ChangeNotifier {
  // Start with some dummy data so the app doesn't look empty
  int _totalPoints = 1240;
  int _totalScans = 45;

  // Getters to read the data
  int get totalPoints => _totalPoints;
  int get totalScans => _totalScans;

  // Function to add points (Called from Camera Screen)
  void addPoints(int points) {
    _totalPoints += points;
    _totalScans += 1;

    // 📢 This is the magic line!
    // It tells the Home Screen to redraw itself with the new numbers.
    notifyListeners();
  }

  // Optional: Function to reset (good for testing)
  void resetStats() {
    _totalPoints = 0;
    _totalScans = 0;
    notifyListeners();
  int _totalPoints = 1240; // Starting points
  int _totalScans = 45;
/// 1️⃣ THE STATE (holds points and scans)
class PointsState {
  final int totalPoints;
  final int totalScans;

  const PointsState({this.totalPoints = 0, this.totalScans = 0});

  // Optional: copyWith helper for cleaner updates
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
    // Initial state
    return const PointsState(totalPoints: 1240, totalScans: 45);
  }

  void addPoints(int points) {
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
final pointsServiceProvider =
    NotifierProvider<PointsService, PointsState>(PointsService.new);
