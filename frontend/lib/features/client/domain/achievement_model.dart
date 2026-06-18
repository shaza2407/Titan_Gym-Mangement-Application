// lib/features/client/domain/achievement_model.dart

class AchievementModel {
  final int achievementID;
  final String key;
  final String chainKey;
  final String name;
  final String description;
  final String icon;
  final String difficulty;
  final String category;
  final int target;
  final String unit;
  final int currentValue;
  final int bestValue;
  final int currentStreak;
  final int longestStreak;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progressPercentage;

  AchievementModel({
    required this.achievementID,
    required this.key,
    required this.chainKey,
    required this.name,
    required this.description,
    required this.icon,
    required this.difficulty,
    required this.category,
    required this.target,
    required this.unit,
    required this.currentValue,
    required this.bestValue,
    required this.currentStreak,
    required this.longestStreak,
    required this.isUnlocked,
    this.unlockedAt,
    required this.progressPercentage,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      achievementID: json['achievementID'],
      key: json['key'] ?? '',
      chainKey: json['chain_key'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏅',
      difficulty: json['difficulty'] ?? '',
      category: json['category'] ?? '',
      target: json['target'] ?? 1,
      unit: json['unit'] ?? '',
      currentValue: json['current_value'] ?? 0,
      bestValue: json['best_value'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedAt: json['unlocked_at'] != null ? DateTime.parse(json['unlocked_at']) : null,
      progressPercentage: json['progress_percentage'] ?? 0,
    );
  }
}
