class PlayerHistory {
  final int element;
  final int fixture;
  final int opponentTeam;
  final int totalPoints;
  final bool wasHome;
  final String? kickoffTime;
  final int? teamHScore;
  final int? teamAScore;
  final int round;
  final int minutes;
  final int goalsScored;
  final int assists;
  final int cleanSheets;
  final int goalsConceded;
  final int ownGoals;
  final int penaltiesSaved;
  final int penaltiesMissed;
  final int yellowCards;
  final int redCards;
  final int saves;
  final int bonus;
  final int bps;
  final String influence;
  final String creativity;
  final String threat;
  final String ictIndex;
  final int value;
  final int transfersBalance;
  final int selected;

  const PlayerHistory({
    required this.element,
    required this.fixture,
    required this.opponentTeam,
    required this.totalPoints,
    required this.wasHome,
    this.kickoffTime,
    this.teamHScore,
    this.teamAScore,
    required this.round,
    required this.minutes,
    required this.goalsScored,
    required this.assists,
    required this.cleanSheets,
    required this.goalsConceded,
    required this.ownGoals,
    required this.penaltiesSaved,
    required this.penaltiesMissed,
    required this.yellowCards,
    required this.redCards,
    required this.saves,
    required this.bonus,
    required this.bps,
    required this.influence,
    required this.creativity,
    required this.threat,
    required this.ictIndex,
    required this.value,
    required this.transfersBalance,
    required this.selected,
  });

  factory PlayerHistory.fromJson(Map<String, dynamic> json) {
    return PlayerHistory(
      element: json['element'] as int,
      fixture: json['fixture'] as int,
      opponentTeam: json['opponent_team'] as int,
      totalPoints: json['total_points'] as int,
      wasHome: json['was_home'] as bool? ?? false,
      kickoffTime: json['kickoff_time'] as String?,
      teamHScore: json['team_h_score'] as int?,
      teamAScore: json['team_a_score'] as int?,
      round: json['round'] as int,
      minutes: json['minutes'] as int? ?? 0,
      goalsScored: json['goals_scored'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      cleanSheets: json['clean_sheets'] as int? ?? 0,
      goalsConceded: json['goals_conceded'] as int? ?? 0,
      ownGoals: json['own_goals'] as int? ?? 0,
      penaltiesSaved: json['penalties_saved'] as int? ?? 0,
      penaltiesMissed: json['penalties_missed'] as int? ?? 0,
      yellowCards: json['yellow_cards'] as int? ?? 0,
      redCards: json['red_cards'] as int? ?? 0,
      saves: json['saves'] as int? ?? 0,
      bonus: json['bonus'] as int? ?? 0,
      bps: json['bps'] as int? ?? 0,
      influence: json['influence'] as String? ?? '0.0',
      creativity: json['creativity'] as String? ?? '0.0',
      threat: json['threat'] as String? ?? '0.0',
      ictIndex: json['ict_index'] as String? ?? '0.0',
      value: json['value'] as int? ?? 0,
      transfersBalance: json['transfers_balance'] as int? ?? 0,
      selected: json['selected'] as int? ?? 0,
    );
  }
}

class UpcomingFixture {
  final int id;
  final bool finished;
  final bool finishedProvisional;
  final String? kickoffTime;
  final int event;
  final String eventName;
  final bool isHome;
  final int difficulty;
  final int teamH;
  final int teamA;
  final int? teamHScore;
  final int? teamAScore;

  const UpcomingFixture({
    required this.id,
    required this.finished,
    required this.finishedProvisional,
    this.kickoffTime,
    required this.event,
    required this.eventName,
    required this.isHome,
    required this.difficulty,
    required this.teamH,
    required this.teamA,
    this.teamHScore,
    this.teamAScore,
  });

  factory UpcomingFixture.fromJson(Map<String, dynamic> json) {
    return UpcomingFixture(
      id: json['id'] as int,
      finished: json['finished'] as bool? ?? false,
      finishedProvisional: json['finished_provisional'] as bool? ?? false,
      kickoffTime: json['kickoff_time'] as String?,
      event: json['event'] as int? ?? 0,
      eventName: json['event_name'] as String? ?? '',
      isHome: json['is_home'] as bool? ?? false,
      difficulty: json['difficulty'] as int? ?? 3,
      teamH: json['team_h'] as int? ?? 0,
      teamA: json['team_a'] as int? ?? 0,
      teamHScore: json['team_h_score'] as int?,
      teamAScore: json['team_a_score'] as int?,
    );
  }
}

class PlayerSummary {
  final List<PlayerHistory> history;
  final List<UpcomingFixture> fixtures;

  const PlayerSummary({required this.history, required this.fixtures});

  factory PlayerSummary.fromJson(Map<String, dynamic> json) {
    final historyList = (json['history'] as List<dynamic>? ?? [])
        .map((e) => PlayerHistory.fromJson(e as Map<String, dynamic>))
        .toList();
    final fixtureList = (json['fixtures'] as List<dynamic>? ?? [])
        .map((e) => UpcomingFixture.fromJson(e as Map<String, dynamic>))
        .toList();
    return PlayerSummary(history: historyList, fixtures: fixtureList);
  }
}
