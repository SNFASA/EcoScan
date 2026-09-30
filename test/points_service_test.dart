import 'package:ecoscan/services/points_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recordScan updates local points, scans, and category counts', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(pointsServiceProvider.notifier)
        .recordScan(points: 10, category: 'Plastic');
    container
        .read(pointsServiceProvider.notifier)
        .recordScan(points: 2, category: 'General');

    final state = container.read(pointsServiceProvider);
    expect(state.totalPoints, 12);
    expect(state.totalScans, 2);
    expect(state.categoryCounts, {'Plastic': 1, 'General': 1});
  });

  test('resetStats clears the current guest session', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(pointsServiceProvider.notifier)
        .recordScan(points: 10, category: 'Glass');
    container.read(pointsServiceProvider.notifier).resetStats();

    expect(container.read(pointsServiceProvider).totalScans, 0);
  });
}
