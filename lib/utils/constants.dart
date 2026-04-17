import 'package:flutter/material.dart';

class ApiConstants {
  static const String baseUrl = 'https://fantasy.premierleague.com/api';
  static const String bootstrapStatic = '$baseUrl/bootstrap-static/';
  static const String fixtures = '$baseUrl/fixtures/';
  static String fixturesForGw(int gw) => '$baseUrl/fixtures/?event=$gw';
  static String elementSummary(int id) => '$baseUrl/element-summary/$id/';
  static String liveGw(int gw) => '$baseUrl/event/$gw/live/';
  static String playerPhotoUrl(String photo) {
    final code = photo.replaceAll('.jpg', '');
    return 'https://resources.premierleague.com/premierleague/photos/players/110x140/p$code.png';
  }

  static String teamBadgeUrl(int teamCode) =>
      'https://resources.premierleague.com/premierleague/badges/70/t$teamCode.png';
}

class PositionConstants {
  static const int goalkeeper = 1;
  static const int defender = 2;
  static const int midfielder = 3;
  static const int forward = 4;
  static const Map<int, String> positionNames = {
    1: 'GK',
    2: 'DEF',
    3: 'MID',
    4: 'FWD',
  };
  static const Map<int, String> positionFullNames = {
    1: 'Goalkeeper',
    2: 'Defender',
    3: 'Midfielder',
    4: 'Forward',
  };
  static const Map<int, Color> positionColors = {
    1: Color(0xFF00FF87),
    2: Color(0xFF04F5FF),
    3: Color(0xFFFFEB04),
    4: Color(0xFFFF6B35),
  };
}

class DifficultyConstants {
  static const Map<int, Color> colors = {
    1: Color(0xFF00C853),
    2: Color(0xFF69F0AE),
    3: Color(0xFFFFD740),
    4: Color(0xFFFF6D00),
    5: Color(0xFFD50000),
  };
  static const Map<int, String> labels = {
    1: 'Very Easy',
    2: 'Easy',
    3: 'Medium',
    4: 'Hard',
    5: 'Very Hard',
  };
}

class AppColors {
  static const Color primary = Color(0xFF00FF87);
  static const Color secondary = Color(0xFF37003C);
  static const Color background = Color(0xFF0f0f1a);
  static const Color cardDark = Color(0xFF1a1a2e);
  static const Color cardMedium = Color(0xFF16213e);
  static const Color accent = Color(0xFF04F5FF);
  static const Color warning = Color(0xFFFFEB04);
  static const Color error = Color(0xFFFF6B6B);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C3);
  static const Color divider = Color(0xFF2a2a3e);
}
