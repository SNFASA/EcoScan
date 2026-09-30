import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_model.dart';
import '../repositories/history_repository.dart';

final scanHistoryProvider = StreamNotifierProvider<HistoryController, List<ScanModel>>(() {
  return HistoryController();
});

class HistoryController extends StreamNotifier<List<ScanModel>> {
  @override
  Stream<List<ScanModel>> build() {
    return ref.read(historyRepositoryProvider).getScanHistoryStream();
  }

  // Logic for the Floating Card metric
  int getTodayScanCount(List<ScanModel> scans) {
    final now = DateTime.now();
    return scans.where((scan) {
      final date = scan.timestamp.toDate();
      return date.year == now.year && 
             date.month == now.month && 
             date.day == now.day;
    }).length;
  }
}