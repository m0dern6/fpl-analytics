import 'dart:convert';

class UserTeamSlot {
  final int playerId;
  final bool isStarting;
  final int slotIndex; // 0-10 starting, 11-14 bench

  const UserTeamSlot({
    required this.playerId,
    required this.isStarting,
    required this.slotIndex,
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'isStarting': isStarting,
        'slotIndex': slotIndex,
      };

  factory UserTeamSlot.fromJson(Map<String, dynamic> json) => UserTeamSlot(
        playerId: json['playerId'] as int,
        isStarting: json['isStarting'] as bool,
        slotIndex: json['slotIndex'] as int,
      );
}

class UserTeam {
  final String id;
  final String name;
  final List<UserTeamSlot> slots;
  final int captainId;
  final int viceCaptainId;
  final String formation;
  final DateTime createdAt;

  const UserTeam({
    required this.id,
    required this.name,
    required this.slots,
    required this.captainId,
    required this.viceCaptainId,
    required this.formation,
    required this.createdAt,
  });

  /// Total cost in tenths of millions (same unit as Player.nowCost).
  /// Requires a price lookup map: playerId → nowCost.
  int totalCost(Map<int, int> prices) =>
      slots.fold(0, (sum, s) => sum + (prices[s.playerId] ?? 0));

  List<int> get startingPlayerIds =>
      slots.where((s) => s.isStarting).map((s) => s.playerId).toList();

  List<int> get benchPlayerIds =>
      slots.where((s) => !s.isStarting).map((s) => s.playerId).toList();

  List<int> get allPlayerIds => slots.map((s) => s.playerId).toList();

  UserTeam copyWith({
    String? id,
    String? name,
    List<UserTeamSlot>? slots,
    int? captainId,
    int? viceCaptainId,
    String? formation,
    DateTime? createdAt,
  }) {
    return UserTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      slots: slots ?? this.slots,
      captainId: captainId ?? this.captainId,
      viceCaptainId: viceCaptainId ?? this.viceCaptainId,
      formation: formation ?? this.formation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slots': slots.map((s) => s.toJson()).toList(),
        'captainId': captainId,
        'viceCaptainId': viceCaptainId,
        'formation': formation,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserTeam.fromJson(Map<String, dynamic> json) => UserTeam(
        id: json['id'] as String,
        name: json['name'] as String,
        slots: (json['slots'] as List<dynamic>)
            .map((s) => UserTeamSlot.fromJson(s as Map<String, dynamic>))
            .toList(),
        captainId: json['captainId'] as int? ?? 0,
        viceCaptainId: json['viceCaptainId'] as int? ?? 0,
        formation: json['formation'] as String? ?? '4-3-3',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());

  factory UserTeam.fromJsonString(String s) =>
      UserTeam.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
