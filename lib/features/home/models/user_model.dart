class UserModel {
  final String id;
  final String username;
  final String profileurl;
  final String email;
  final int ecoPoints;
  final int weeklyPoints;
  final int totalScans;
  final double co2Offset;
  final String rankTier;
  final int streak;
  final Map<String, int> categoryCounts; 
  final double nextMilestoneCo2;

  UserModel({
    required this.id,
    required this.username,
    required this.profileurl,
    required this.email,
    required this.ecoPoints,
    required this.weeklyPoints,
    required this.totalScans,
    required this.co2Offset,
    required this.rankTier,
    required this.streak,
    required this.categoryCounts,
    required this.nextMilestoneCo2,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> json) {
    return UserModel(
      id: id,
      username: json['username'] ?? '',
      profileurl: json['profileurl'] ?? '',
      email: json['email'] ?? '',
      ecoPoints: json['ecoPoints'] ?? 0,
      weeklyPoints: json['weeklyPoints'] ?? 0,
      totalScans: json['totalScans'] ?? 0,
      co2Offset: (json['co2Offset'] ?? 0.0).toDouble(),
      rankTier: json['rankTier'] ?? 'Bronze',
      streak: json['streak'] ?? 0,
      categoryCounts: Map<String, int>.from(json['categoryCounts'] ?? {}),
      nextMilestoneCo2: (json['nextMilestoneCo2'] ?? 20.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'profileurl': profileurl,
      'email': email,
      'ecoPoints': ecoPoints,
      'weeklyPoints': weeklyPoints,
      'totalScans': totalScans,
      'co2Offset': co2Offset,
      'rankTier': rankTier,
      'streak': streak,
      'categoryCounts': categoryCounts,
      'nextMilestoneCo2': nextMilestoneCo2,
    };
  }
}