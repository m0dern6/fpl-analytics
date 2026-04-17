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
  });

  factory Fixture.fromJson(Map<String, dynamic> json) {
    return Fixture(
      id: json['id'] as int,
      event: json['event'] as int?,
      finished: json['finished'] as bool? ?? false,
      finishedProvisional: json['finished_provisional'] as bool? ?? false,
      kickoffTime: json['kickoff_time'] as String?,
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
    );
  }

  bool get hasResult => homeTeamScore != null && awayTeamScore != null;
}
