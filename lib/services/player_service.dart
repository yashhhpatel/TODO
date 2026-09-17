import 'package:flutter/foundation.dart';
import '../core/app_config.dart';
import '../data/achievements_catalog.dart';
import '../models/achievement.dart';
import 'storage_service.dart';

/// Central progression + economy. Every coin change and progress mutation goes
/// through here (never directly from widgets) and is persisted immediately.
class PlayerService extends ChangeNotifier {
  PlayerService(this._storage) {
    _load();
  }

  final StorageService _storage;
  static const String _key = 'player_v1';

  // ---- State ----
  bool onboardingDone = false;
  int coins = 0;
  int highestUnlocked = 1; // level number, always >= 1
  final Map<int, int> _stars = {}; // level -> best stars (1..3)
  int totalWordsFound = 0;
  int totalCoinsEarned = 0;
  int totalCoinsSpent = 0;
  int? fastestSeconds;
  int currentStreak = 0;
  int longestStreak = 0;
  String? _lastActiveDate;
  String? _dailyLastClaim;
  int dailyDayIndex = 0;
  final Set<String> _unlockedAchievements = {};
  bool premium = false;

  static const List<int> dailyRewardTable = [50, 75, 100, 150, 200, 300, 500];

  // ---- Derived ----
  int get levelsCompleted => _stars.length;
  int get starsEarned => _stars.values.fold(0, (a, b) => a + b);
  int get threeStarCount => _stars.values.where((s) => s == 3).length;
  int starsFor(int level) => _stars[level] ?? 0;
  bool isCompleted(int level) => _stars.containsKey(level);
  bool isUnlocked(int level) => level <= highestUnlocked;
  Set<String> get unlockedAchievements => Set.unmodifiable(_unlockedAchievements);
  bool isAchievementUnlocked(String id) => _unlockedAchievements.contains(id);

  String _today() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  int _dayDiff(String from, String to) {
    final a = DateTime.parse(from);
    final b = DateTime.parse(to);
    return b.difference(a).inDays;
  }

  // ---- Persistence ----
  void _load() {
    final j = _storage.readJson(_key);
    if (j.isEmpty) {
      _persist();
      return;
    }
    onboardingDone = j['onboardingDone'] as bool? ?? false;
    coins = _posInt(j['coins']);
    highestUnlocked = (j['highestUnlocked'] as int?)?.clamp(1, AppConfig.totalLevels) ?? 1;
    totalWordsFound = _posInt(j['totalWordsFound']);
    totalCoinsEarned = _posInt(j['totalCoinsEarned']);
    totalCoinsSpent = _posInt(j['totalCoinsSpent']);
    fastestSeconds = j['fastestSeconds'] as int?;
    currentStreak = _posInt(j['currentStreak']);
    longestStreak = _posInt(j['longestStreak']);
    _lastActiveDate = j['lastActiveDate'] as String?;
    _dailyLastClaim = j['dailyLastClaim'] as String?;
    dailyDayIndex = (j['dailyDayIndex'] as int?)?.clamp(0, 6) ?? 0;
    premium = j['premium'] as bool? ?? false;

    final stars = j['stars'] as Map<String, dynamic>? ?? {};
    stars.forEach((k, v) {
      final lvl = int.tryParse(k);
      final s = (v as num?)?.toInt();
      if (lvl != null && s != null && s >= 1 && s <= 3) _stars[lvl] = s;
    });
    final ach = j['achievements'] as List<dynamic>? ?? [];
    for (final a in ach) {
      if (a is String) _unlockedAchievements.add(a);
    }
  }

  int _posInt(dynamic v) {
    final n = (v as num?)?.toInt() ?? 0;
    return n < 0 ? 0 : n;
  }

  void _persist() {
    _storage.writeJson(_key, {
      'version': 1,
      'onboardingDone': onboardingDone,
      'coins': coins,
      'highestUnlocked': highestUnlocked,
      'stars': _stars.map((k, v) => MapEntry(k.toString(), v)),
      'totalWordsFound': totalWordsFound,
      'totalCoinsEarned': totalCoinsEarned,
      'totalCoinsSpent': totalCoinsSpent,
      'fastestSeconds': fastestSeconds,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': _lastActiveDate,
      'dailyLastClaim': _dailyLastClaim,
      'dailyDayIndex': dailyDayIndex,
      'achievements': _unlockedAchievements.toList(),
      'premium': premium,
    });
  }

  // ---- Onboarding ----
  void completeOnboarding() {
    onboardingDone = true;
    _persist();
    notifyListeners();
  }

  // ---- Coins ----
  void addCoins(int amount, String reason) {
    if (amount <= 0) return;
    coins += amount;
    totalCoinsEarned += amount;
    _persist();
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (amount <= 0 || coins < amount) return false;
    coins -= amount;
    totalCoinsSpent += amount;
    _persist();
    notifyListeners();
    return true;
  }

  // ---- Streak (call once when the app becomes active) ----
  void registerDailyActivity() {
    final today = _today();
    if (_lastActiveDate == null) {
      currentStreak = 1;
    } else if (today == _lastActiveDate) {
      // same day, no change
    } else {
      final diff = _dayDiff(_lastActiveDate!, today);
      if (diff == 1) {
        currentStreak += 1;
      } else if (diff > 1) {
        currentStreak = 1;
      } else {
        // clock moved backwards; ignore to prevent abuse
        return;
      }
    }
    if (currentStreak > longestStreak) longestStreak = currentStreak;
    _lastActiveDate = today;
    _persist();
    _checkAchievements();
    notifyListeners();
  }

  // ---- Daily reward ----
  bool get canClaimDailyReward {
    final today = _today();
    if (_dailyLastClaim == null) return true;
    return _dayDiff(_dailyLastClaim!, today) >= 1;
  }

  /// Index (0..6) that would be granted if claimed now.
  int get pendingDailyIndex {
    if (_dailyLastClaim == null) return 0;
    final diff = _dayDiff(_dailyLastClaim!, _today());
    if (diff == 1) return (dailyDayIndex + 1) % 7;
    if (diff > 1) return 0; // missed a day: restart cycle
    return dailyDayIndex;
  }

  /// Returns (index, reward) if claimed, or null if not claimable.
  ({int index, int reward})? claimDailyReward() {
    if (!canClaimDailyReward) return null;
    final index = pendingDailyIndex;
    final reward = dailyRewardTable[index];
    _dailyLastClaim = _today();
    dailyDayIndex = index;
    addCoins(reward, 'daily_reward'); // persists + notifies
    return (index: index, reward: reward);
  }

  // ---- Level completion ----
  /// Applies a completed level exactly once per call. Coins passed in are the
  /// already-computed level reward. Returns achievements newly unlocked.
  List<Achievement> applyLevelResult({
    required int level,
    required int stars,
    required int rewardCoins,
    required int wordsFound,
    required int seconds,
  }) {
    // Best stars only.
    final prev = _stars[level] ?? 0;
    if (stars > prev) _stars[level] = stars;
    _stars.putIfAbsent(level, () => stars);

    totalWordsFound += wordsFound;
    if (fastestSeconds == null || seconds < fastestSeconds!) {
      fastestSeconds = seconds;
    }
    // Unlock next level.
    if (level >= highestUnlocked && highestUnlocked < AppConfig.totalLevels) {
      highestUnlocked = (level + 1).clamp(1, AppConfig.totalLevels);
    }

    addCoins(rewardCoins, 'level_completion'); // persists + notifies
    final unlocked = _checkAchievements();
    _persist();
    notifyListeners();
    return unlocked;
  }

  /// Upgrades a completed level's recorded stars (used by the rewarded-ad
  /// "get 3 stars" option). Only ever raises the value, never lowers it, and
  /// persists so every screen that reads stars reflects the new value.
  void setLevelStars(int level, int stars) {
    final prev = _stars[level] ?? 0;
    final next = stars > prev ? stars : prev;
    if (next == prev) return;
    _stars[level] = next;
    _persist();
    _checkAchievements();
    notifyListeners();
  }

  // ---- Achievements ----
  int _metricValue(AchievementMetric m) {
    switch (m) {
      case AchievementMetric.levelsCompleted:
        return levelsCompleted;
      case AchievementMetric.wordsFound:
        return totalWordsFound;
      case AchievementMetric.coinsEarned:
        return totalCoinsEarned;
      case AchievementMetric.streakDays:
        return longestStreak;
      case AchievementMetric.fastSolves:
        return threeStarCount;
    }
  }

  double achievementProgress(Achievement a) {
    if (_unlockedAchievements.contains(a.id)) return 1.0;
    return (_metricValue(a.metric) / a.threshold).clamp(0.0, 1.0);
  }

  /// Unlocks any newly-earned achievements exactly once and grants rewards.
  List<Achievement> _checkAchievements() {
    final newly = <Achievement>[];
    for (final a in kAchievements) {
      if (_unlockedAchievements.contains(a.id)) continue;
      if (_metricValue(a.metric) >= a.threshold) {
        _unlockedAchievements.add(a.id);
        if (a.rewardCoins > 0) {
          coins += a.rewardCoins;
          totalCoinsEarned += a.rewardCoins;
        }
        newly.add(a);
      }
    }
    if (newly.isNotEmpty) _persist();
    return newly;
  }

  // ---- Premium ----
  void setPremium(bool value) {
    if (premium == value) return;
    premium = value;
    _persist();
    notifyListeners();
  }

  // ---- Danger: reset (used by nothing in prod UI directly) ----
  @visibleForTesting
  void debugReset() {
    coins = 0;
    highestUnlocked = 1;
    _stars.clear();
    _unlockedAchievements.clear();
    _persist();
    notifyListeners();
  }
}
