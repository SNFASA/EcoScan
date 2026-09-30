import 'package:flutter_riverpod/flutter_riverpod.dart';

class PointsState {
  const PointsState({
    this.totalPoints = 0,
    this.totalScans = 0,
    this.categoryCounts = const {},
  });

  final int totalPoints;
  final int totalScans;
  final Map<String, int> categoryCounts;

  PointsState copyWith({
    int? totalPoints,
    int? totalScans,
    Map<String, int>? categoryCounts,
  }) {
    return PointsState(
      totalPoints: totalPoints ?? this.totalPoints,
      totalScans: totalScans ?? this.totalScans,
      categoryCounts: categoryCounts ?? this.categoryCounts,
    );
  }
}

class PointsService extends Notifier<PointsState> {
  @override
  PointsState build() => const PointsState();

  void recordScan({required int points, required String category}) {
    final normalizedCategory = category.trim().isEmpty ? 'General' : category;
    final updatedCounts = Map<String, int>.from(state.categoryCounts);
    updatedCounts.update(
      normalizedCategory,
      (count) => count + 1,
      ifAbsent: () => 1,
    );

    state = state.copyWith(
      totalPoints: state.totalPoints + points,
      totalScans: state.totalScans + 1,
      categoryCounts: Map.unmodifiable(updatedCounts),
    );
  }

  void resetStats() => state = const PointsState();
}

final pointsServiceProvider = NotifierProvider<PointsService, PointsState>(
  PointsService.new,
);
