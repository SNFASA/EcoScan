import 'package:flutter/material.dart';

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
  }
}