import 'package:flutter/material.dart';

enum AchievementMetric {
  levelsCompleted,
  wordsFound,
  coinsEarned,
  streakDays,
  fastSolves, // levels solved with 3 stars
}

/// Data-driven achievement definition.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementMetric metric;
  final int threshold;
  final int rewardCoins;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.metric,
    required this.threshold,
    required this.rewardCoins,
  });
}
