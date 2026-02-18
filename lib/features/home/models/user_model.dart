class UserModel{
  final String id;
  final String username;
  final String email;
  final int ecoPoints;
  final int weeklyPoints;
  final int totalScans;
  final double co2Offset;
  final String rankTier;
  final int streak;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.ecoPoints,
    required this.weeklyPoints,
    required this.totalScans,
    required this.co2Offset,
    required this.rankTier,
    required this.streak,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> json){
    return UserModel(
      id:id,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      ecoPoints: json['ecoPoints'] ?? 0,
      weeklyPoints: json['weeklyPoints'] ?? 0,
      totalScans: json['totalScans'] ?? 0,
      co2Offset: (json['co2Offset'] ?? 0.0).toDouble(),
      rankTier: json['rankTier'] ?? '',
      streak: json['streak'] ?? 0,
    );
  }
}