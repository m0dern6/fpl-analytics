/// A single player contribution within a fixture stat category.
class FixtureStatEntry {
  final int element;
  final int value;
  const FixtureStatEntry({required this.element, required this.value});

  factory FixtureStatEntry.fromJson(Map<String, dynamic> json) {
    return FixtureStatEntry(
      element: json['element'] as int,
      value: json['value'] as int? ?? 0,
    );
  }
}

/// One stat category for a fixture (e.g. goals_scored, assists, …).
class FixtureStat {
  final String identifier;

  /// Away team contributions.
  final List<FixtureStatEntry> away;

  /// Home team contributions.
  final List<FixtureStatEntry> home;

  const FixtureStat({
    required this.identifier,
    required this.away,
    required this.home,
  });

  factory FixtureStat.fromJson(Map<String, dynamic> json) {
    List<FixtureStatEntry> _parse(dynamic list) =>
        (list as List<dynamic>? ?? [])
            .map((e) => FixtureStatEntry.fromJson(e as Map<String, dynamic>))
            .toList();
    return FixtureStat(
      identifier: json['identifier'] as String,
      away: _parse(json['a']),
      home: _parse(json['h']),
    );
  }
}

class Fixture {
  final int id;
  final int? event;
  final bool finished;
  final bool finishedProvisional;
  final String? kickoffTime;
  final int homeTeamId;
  final int awayTeamId;
  final int? homeTeamScore;
  final int? awayTeamScore;
  final int teamHDifficulty;
  final int teamADifficulty;
  final bool? started;
  final bool provisionalStartTime;
  final int? minutes;
  final int? pulseId;
  final List<FixtureStat> stats;

  const Fixture({
    required this.id,
    this.event,
    required this.finished,
    this.finishedProvisional = false,
    this.kickoffTime,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeTeamScore,
    this.awayTeamScore,
    required this.teamHDifficulty,
    required this.teamADifficulty,
    this.started,
    this.provisionalStartTime = false,
    this.minutes,
    this.pulseId,
    this.stats = const [],
  });

  factory Fixture.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'] as List<dynamic>? ?? [];
    final rawKickoff = json['kickoff_time'] as String?;
    return Fixture(
      id: json['id'] as int,
      event: json['event'] as int?,
      finished: json['finished'] as bool? ?? false,
      finishedProvisional: json['finished_provisional'] as bool? ?? false,
      kickoffTime: rawKickoff == null
          ? null
          : DateTime.parse(rawKickoff).toUtc().toIso8601String(),
      homeTeamId: json['team_h'] as int,
      awayTeamId: json['team_a'] as int,
      homeTeamScore: json['team_h_score'] as int?,
      awayTeamScore: json['team_a_score'] as int?,
      teamHDifficulty: json['team_h_difficulty'] as int? ?? 3,
      teamADifficulty: json['team_a_difficulty'] as int? ?? 3,
      started: json['started'] as bool?,
      provisionalStartTime: json['provisional_start_time'] as bool? ?? false,
      minutes: json['minutes'] as int?,
      pulseId: json['pulse_id'] as int?,
      stats: rawStats
          .map((e) => FixtureStat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasResult => homeTeamScore != null && awayTeamScore != null;

  bool get isLive =>
      (started ?? false) && !finished && !finishedProvisional;

  bool get isFinishedOrProvisional => finished || finishedProvisional;

  DateTime? get kickoffDateTimeLocal {
    if (kickoffTime == null) return null;
    return DateTime.tryParse(kickoffTime!)?.toLocal();
  }

  String? get localDayKey {
    final local = kickoffDateTimeLocal;
    if (local == null) return null;
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
