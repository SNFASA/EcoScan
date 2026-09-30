  class BadgesModel {
    final String title;
    final String description;
    final String iconUrl;
    final int pointReward;
    final Map<String, dynamic> requirement; // Use Map<String, dynamic>

    BadgesModel({
      required this.title,
      required this.description,
      required this.iconUrl,
      required this.pointReward,
      required this.requirement,
    });

    factory BadgesModel.fromMap(Map<String, dynamic> json) {
      return BadgesModel(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        iconUrl: json['iconUrl'] ?? '',
        pointReward: json['pointReward'] ?? 0,
        requirement: Map<String, dynamic>.from(json['requirement'] ?? {
          'category': '',
          'type': '',
          'value': 0,
        }),
      );
    }

    Map<String, dynamic> toMap() {
      return {
        'title': title,
        'description': description,
        'iconUrl': iconUrl,
        'pointReward': pointReward,
        'requirement': requirement,
      };
    }
  }