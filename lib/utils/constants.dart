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
  static const Color primary = Color(0xFF00D68F);
  static const Color secondary = Color(0xFF1B0A3F);
  static const Color background = Color(0xFF080D1A);
  static const Color cardDark = Color(0xFF0E1729);
  static const Color cardMedium = Color(0xFF162035);
  static const Color accent = Color(0xFF5B8DEF);
  static const Color warning = Color(0xFFFFCC02);
  static const Color error = Color(0xFFFF5C5C);
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8896B3);
  static const Color divider = Color(0xFF1E2D4A);
  // Nav bar background – slightly lighter than background
  static const Color navBar = Color(0xFF0D1526);
  // Pitch green
  static const Color pitchGreen = Color(0xFF0D3D1A);
  static const Color pitchGreenDark = Color(0xFF072410);
}
