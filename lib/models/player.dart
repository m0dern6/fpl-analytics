class Player {
  final int id;
  final String webName;
  final String firstName;
  final String secondName;
  final int teamId;
  final int elementType;
  final int nowCost;
  final int totalPoints;
  final String form;
  final String selectedByPercent;
  final String pointsPerGame;
  final int minutes;
  final int goals;
  final int assists;
  final int cleanSheets;
  final int goalsConceded;
  final int yellowCards;
  final int redCards;
  final int saves;
  final int bonus;
  final int bps;
  final String influence;
  final String creativity;
  final String threat;
  final String ictIndex;
  final int transfersIn;
  final int transfersOut;
  final int transfersInEvent;
  final int transfersOutEvent;
  final int? chanceOfPlayingNextRound;
  final int? chanceOfPlayingThisRound;
  final String valueForm;
  final String valueSeason;
  final String status;
  final String photo;
  final String news;
  final int teamCode;
  final int expectedGoals;
  final String expectedGoalsStr;
  final String expectedAssistsStr;
  final int ownGoals;
  final int penaltiesSaved;
  final int penaltiesMissed;
  final int eventPoints;

  const Player({
    required this.id,
    required this.webName,
    required this.firstName,
    required this.secondName,
    required this.teamId,
    required this.elementType,
    required this.nowCost,
    required this.totalPoints,
    required this.form,
    required this.selectedByPercent,
    required this.pointsPerGame,
    required this.minutes,
    required this.goals,
    required this.assists,
    required this.cleanSheets,
    required this.goalsConceded,
    required this.yellowCards,
    required this.redCards,
    required this.saves,
    required this.bonus,
    required this.bps,
    required this.influence,
    required this.creativity,
    required this.threat,
    required this.ictIndex,
    required this.transfersIn,
    required this.transfersOut,
    required this.transfersInEvent,
    required this.transfersOutEvent,
    this.chanceOfPlayingNextRound,
    this.chanceOfPlayingThisRound,
    required this.valueForm,
    required this.valueSeason,
    required this.status,
    required this.photo,
    required this.news,
    required this.teamCode,
    this.expectedGoals = 0,
    this.expectedGoalsStr = '0.00',
    this.expectedAssistsStr = '0.00',
    this.ownGoals = 0,
    this.penaltiesSaved = 0,
    this.penaltiesMissed = 0,
    this.eventPoints = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as int,
      webName: json['web_name'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      secondName: json['second_name'] as String? ?? '',
      teamId: json['team'] as int,
      elementType: json['element_type'] as int,
      nowCost: json['now_cost'] as int,
      totalPoints: json['total_points'] as int,
      form: json['form'] as String? ?? '0.0',
      selectedByPercent: json['selected_by_percent'] as String? ?? '0.0',
      pointsPerGame: json['points_per_game'] as String? ?? '0.0',
      minutes: json['minutes'] as int? ?? 0,
      goals: json['goals_scored'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      cleanSheets: json['clean_sheets'] as int? ?? 0,
      goalsConceded: json['goals_conceded'] as int? ?? 0,
      yellowCards: json['yellow_cards'] as int? ?? 0,
      redCards: json['red_cards'] as int? ?? 0,
      saves: json['saves'] as int? ?? 0,
      bonus: json['bonus'] as int? ?? 0,
      bps: json['bps'] as int? ?? 0,
      influence: json['influence'] as String? ?? '0.0',
      creativity: json['creativity'] as String? ?? '0.0',
      threat: json['threat'] as String? ?? '0.0',
      ictIndex: json['ict_index'] as String? ?? '0.0',
      transfersIn: json['transfers_in'] as int? ?? 0,
      transfersOut: json['transfers_out'] as int? ?? 0,
      transfersInEvent: json['transfers_in_event'] as int? ?? 0,
      transfersOutEvent: json['transfers_out_event'] as int? ?? 0,
      chanceOfPlayingNextRound: json['chance_of_playing_next_round'] as int?,
      chanceOfPlayingThisRound: json['chance_of_playing_this_round'] as int?,
      valueForm: json['value_form'] as String? ?? '0.0',
      valueSeason: json['value_season'] as String? ?? '0.0',
      status: json['status'] as String? ?? 'a',
      photo: json['photo'] as String? ?? '',
      news: json['news'] as String? ?? '',
      teamCode: json['team_code'] as int? ?? 0,
      expectedGoalsStr: json['expected_goals'] as String? ?? '0.00',
      expectedAssistsStr: json['expected_assists'] as String? ?? '0.00',
      ownGoals: json['own_goals'] as int? ?? 0,
      penaltiesSaved: json['penalties_saved'] as int? ?? 0,
      penaltiesMissed: json['penalties_missed'] as int? ?? 0,
      eventPoints: json['event_points'] as int? ?? 0,
    );
  }

  String get photoUrl {
    final code = photo.replaceAll('.jpg', '');
    return 'https://resources.premierleague.com/premierleague25/photos/players/110x140/$code.png';
  }

  String get teamBadgeUrl =>
      'https://resources.premierleague.com/premierleague/badges/70/t$teamCode.png';

  double get formValue => double.tryParse(form) ?? 0;
  double get ictValue => double.tryParse(ictIndex) ?? 0;
  double get influenceValue => double.tryParse(influence) ?? 0;
  double get creativityValue => double.tryParse(creativity) ?? 0;
  double get threatValue => double.tryParse(threat) ?? 0;
  double get selectedPercent => double.tryParse(selectedByPercent) ?? 0;
  double get ppgValue => double.tryParse(pointsPerGame) ?? 0;
  double get valueSeasonValue => double.tryParse(valueSeason) ?? 0;
  double get xG => double.tryParse(expectedGoalsStr) ?? 0;
  double get xA => double.tryParse(expectedAssistsStr) ?? 0;
  double get xGI => xG + xA;
  double get goalsDelta => goals - xG;
  double get assistsDelta => assists - xA;
}
