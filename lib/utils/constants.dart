import 'package:flutter/material.dart';

class ApiConstants {
  static const String baseUrl = 'https://fantasy.premierleague.com/api';
  static const String bootstrapStatic = '${baseUrl}/bootstrap-static/';
  static const String fixtures = '${baseUrl}/fixtures/';
  static String fixturesForGw(int gw) => '$baseUrl/fixtures/?event=$gw';
  static String elementSummary(int id) => '$baseUrl/element-summary/$id/';
  static String liveGw(int gw) => '$baseUrl/event/$gw/live/';
  static String dreamTeam(int gw) => '$baseUrl/dream-team/$gw/';
  static String fplEntry(int entryId) => '$baseUrl/entry/$entryId/';
  static String fplEntryPicks(int entryId, int gw) =>
      '$baseUrl/entry/$entryId/event/$gw/picks/';
  static String leagueStandings(int leagueId) =>
      '$baseUrl/leagues-classic/$leagueId/standings/';
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
    1: Color(0xFF34D399),
    2: Color(0xFF60A5FA),
    3: Color(0xFFFBBF24),
    4: Color(0xFFF97316),
  };
}

class DifficultyConstants {
  static const Map<int, Color> colors = {
    1: Color(0xFF34D399),
    2: Color(0xFF86EFAC),
    3: Color(0xFFFBBF24),
    4: Color(0xFFFB923C),
    5: Color(0xFFF87171),
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
  final Color primary;
  final Color secondary;
  final Color background;
  final Color cardDark;
  final Color cardMedium;
  final Color accent;
  final Color warning;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color navBar;
  final Color pitchGreen;
  final Color pitchGreenDark;

  const AppColors._({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.cardDark,
    required this.cardMedium,
    required this.accent,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.navBar,
    required this.pitchGreen,
    required this.pitchGreenDark,
  });

  static const dark = AppColors._(
    primary: Color(0xFF00E5A0),
    secondary: Color(0xFF0C0720),
    background: Color(0xFF070C1A),
    cardDark: Color(0xFF0F1828),
    cardMedium: Color(0xFF172238),
    accent: Color(0xFF7B87FA),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    textPrimary: Color(0xFFEDF2FF),
    textSecondary: Color(0xFF7A8BAA),
    divider: Color(0xFF182540),
    navBar: Color(0xFF090F1F),
    pitchGreen: Color(0xFF0A3318),
    pitchGreenDark: Color(0xFF06200F),
  );

  static const light = AppColors._(
    primary: Color(0xFF00C787),
    secondary: Color(0xFFFFFFFF),
    background: Color(0xFFF0F4F8),
    cardDark: Color(0xFFFFFFFF),
    cardMedium: Color(0xFFE8EEF5),
    accent: Color(0xFF5B6FE8),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    divider: Color(0xFFCBD5E1),
    navBar: Color(0xFFFFFFFF),
    pitchGreen: Color(0xFF166534),
    pitchGreenDark: Color(0xFF14532D),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
