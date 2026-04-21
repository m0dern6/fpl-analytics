import 'package:flutter/material.dart';

class ApiConstants {
  static const String baseUrl = 'https://fantasy.premierleague.com/api';
  static const String bootstrapStatic = '$baseUrl/bootstrap-static/';
  static const String fixtures = '$baseUrl/fixtures/';
  static String fixturesForGw(int gw) => '$baseUrl/fixtures/?event=$gw';
  static String elementSummary(int id) => '$baseUrl/element-summary/$id/';
  static String liveGw(int gw) => '$baseUrl/event/$gw/live/';
  static String dreamTeam(int gw) => '$baseUrl/dream-team/$gw/';
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
    1: Color(0xFF34D399), // emerald – GK
    2: Color(0xFF60A5FA), // sky blue – DEF
    3: Color(0xFFFBBF24), // amber – MID
    4: Color(0xFFF97316), // orange – FWD
  };
}

class DifficultyConstants {
  static const Map<int, Color> colors = {
    1: Color(0xFF34D399), // easy
    2: Color(0xFF86EFAC), // fairly easy
    3: Color(0xFFFBBF24), // medium
    4: Color(0xFFFB923C), // hard
    5: Color(0xFFF87171), // very hard
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
  // Primary action – vibrant emerald
  static const Color primary = Color(0xFF00E5A0);
  // AppBar / deep surface
  static const Color secondary = Color(0xFF0C0720);
  // Page background
  static const Color background = Color(0xFF070C1A);
  // Card / surface level 1
  static const Color cardDark = Color(0xFF0F1828);
  // Card / surface level 2 (elevated)
  static const Color cardMedium = Color(0xFF172238);
  // Accent – soft indigo
  static const Color accent = Color(0xFF7B87FA);
  // Warning – warm amber
  static const Color warning = Color(0xFFFBBF24);
  // Error – soft coral
  static const Color error = Color(0xFFF87171);
  // Text
  static const Color textPrimary = Color(0xFFEDF2FF);
  static const Color textSecondary = Color(0xFF7A8BAA);
  // Divider / border
  static const Color divider = Color(0xFF182540);
  // Nav bar background
  static const Color navBar = Color(0xFF090F1F);
  // Pitch
  static const Color pitchGreen = Color(0xFF0A3318);
  static const Color pitchGreenDark = Color(0xFF06200F);
}
