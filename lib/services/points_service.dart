import 'package:flutter/material.dart';

class PointsService with ChangeNotifier {
  int _totalPoints = 1240; // Starting points
  int _totalScans = 45;

  int get totalPoints => _totalPoints;
  int get totalScans => _totalScans;

  void addPoints(int points) {
    _totalPoints += points;
    _totalScans += 1;
    notifyListeners(); // 📢 This tells the UI to refresh!
  }
}