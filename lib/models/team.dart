class Team {
  final int id;
  final String name;
  final String shortName;
  final int code;
  final int strength;
  final int strengthOverallHome;
  final int strengthOverallAway;
  final int strengthAttackHome;
  final int strengthAttackAway;
  final int strengthDefenceHome;
  final int strengthDefenceAway;
  final int pulseId;
  final int win;
  final int draw;
  final int loss;
  final int played;
  final int points;
  final int position;

  const Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.code,
    required this.strength,
    required this.strengthOverallHome,
    required this.strengthOverallAway,
    required this.strengthAttackHome,
    required this.strengthAttackAway,
    required this.strengthDefenceHome,
    required this.strengthDefenceAway,
    required this.pulseId,
    this.win = 0,
    this.draw = 0,
    this.loss = 0,
    this.played = 0,
    this.points = 0,
    this.position = 0,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      shortName: json['short_name'] as String? ?? '',
      code: json['code'] as int? ?? 0,
      strength: json['strength'] as int? ?? 0,
      strengthOverallHome: json['strength_overall_home'] as int? ?? 0,
      strengthOverallAway: json['strength_overall_away'] as int? ?? 0,
      strengthAttackHome: json['strength_attack_home'] as int? ?? 0,
      strengthAttackAway: json['strength_attack_away'] as int? ?? 0,
      strengthDefenceHome: json['strength_defence_home'] as int? ?? 0,
      strengthDefenceAway: json['strength_defence_away'] as int? ?? 0,
      pulseId: json['pulse_id'] as int? ?? 0,
      win: json['win'] as int? ?? 0,
      draw: json['draw'] as int? ?? 0,
      loss: json['loss'] as int? ?? 0,
      played: json['played'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
    );
  }

  String get badgeUrl =>
      'https://resources.premierleague.com/premierleague/badges/70/t$code.png';
}
