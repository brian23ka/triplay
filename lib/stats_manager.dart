import 'package:shared_preferences/shared_preferences.dart';

class StatsManager {
  static final StatsManager _instance = StatsManager._internal();
  factory StatsManager() => _instance;
  StatsManager._internal();

  static const String keyPlayed = 'total_played';
  static const String keyWins = 'total_wins';
  static const String keyFavPrefix = 'played_count_';
  static const String keyBestPrefix = 'best_score_';

  Future<void> recordGamePlay(String gameTitle) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Increment total played
    int total = prefs.getInt(keyPlayed) ?? 0;
    await prefs.setInt(keyPlayed, total + 1);

    // Increment specific game count for "Favorite" logic
    int gameCount = prefs.getInt(keyFavPrefix + gameTitle) ?? 0;
    await prefs.setInt(keyFavPrefix + gameTitle, gameCount + 1);
    
    // Update favorite game string
    await _updateFavoriteGame(prefs);
  }

  Future<void> recordWin() async {
    final prefs = await SharedPreferences.getInstance();
    int wins = prefs.getInt(keyWins) ?? 0;
    await prefs.setInt(keyWins, wins + 1);
  }

  Future<void> saveBestScore(String modeKey, int score, {bool lowerIsBetter = true}) async {
    final prefs = await SharedPreferences.getInstance();
    String key = keyBestPrefix + modeKey;
    int? currentBest = prefs.getInt(key);

    if (currentBest == null || (lowerIsBetter ? score < currentBest : score > currentBest)) {
      await prefs.setInt(key, score);
    }
  }

  Future<int?> getBestScore(String modeKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyBestPrefix + modeKey);
  }

  Future<void> _updateFavoriteGame(SharedPreferences prefs) async {
    List<String> games = ['TIC TAC TOE', 'REACTION', 'GUESS MASTER', 'SEQUENCE', 'CHECKERS', 'CHESS'];
    String fav = 'None';
    int maxCount = -1;

    for (var game in games) {
      int count = prefs.getInt(keyFavPrefix + game) ?? 0;
      if (count > maxCount) {
        maxCount = count;
        fav = game;
      }
    }
    if (maxCount > 0) {
      await prefs.setString('fav_game', fav);
    }
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('user_name');
    await prefs.clear();
    if (name != null) await prefs.setString('user_name', name);
  }
}
