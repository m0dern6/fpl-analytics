import 'dart:convert';

/// Typed model for an FPL Entry (manager's team).
class FplEntry {
  final int id;
  final String name;
  final String playerFirstName;
  final String playerLastName;
  final String playerRegionName;
  final int summaryOverallPoints;
  final int summaryOverallRank;
  final int summaryEventPoints;
  final int summaryEventRank;
  final int currentEvent;
  final List<FplLeagueMembership> leagues;

  const FplEntry({
    required this.id,
    required this.name,
    required this.playerFirstName,
    required this.playerLastName,
    required this.playerRegionName,
    required this.summaryOverallPoints,
    required this.summaryOverallRank,
    required this.summaryEventPoints,
    required this.summaryEventRank,
    required this.currentEvent,
    required this.leagues,
  });

  String get fullName => '$playerFirstName $playerLastName';

  factory FplEntry.fromJson(Map<String, dynamic> json) {
    final leaguesData = json['leagues'] as Map<String, dynamic>? ?? {};
    final classic = (leaguesData['classic'] as List<dynamic>? ?? [])
        .map((e) => FplLeagueMembership.fromJson(e as Map<String, dynamic>))
        .toList();
    final h2h = (leaguesData['h2h'] as List<dynamic>? ?? [])
        .map((e) => FplLeagueMembership.fromJson(e as Map<String, dynamic>))
        .toList();

    return FplEntry(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      playerFirstName: json['player_first_name'] as String? ?? '',
      playerLastName: json['player_last_name'] as String? ?? '',
      playerRegionName: json['player_region_name'] as String? ?? '',
      summaryOverallPoints: json['summary_overall_points'] as int? ?? 0,
      summaryOverallRank: json['summary_overall_rank'] as int? ?? 0,
      summaryEventPoints: json['summary_event_points'] as int? ?? 0,
      summaryEventRank: json['summary_event_rank'] as int? ?? 0,
      currentEvent: json['current_event'] as int? ?? 0,
      leagues: [...classic, ...h2h],
    );
  }
}

class FplLeagueMembership {
  final int id;
  final String name;
  final String leagueType; // 'x' = private, 's' = system/public, 'h' = h2h
  final String scoring; // 'c' = classic, 'h' = h2h
  final int entryRank;
  final int entryLastRank;

  const FplLeagueMembership({
    required this.id,
    required this.name,
    required this.leagueType,
    required this.scoring,
    required this.entryRank,
    required this.entryLastRank,
  });

  bool get isClassic => scoring == 'c';
  bool get isH2H => scoring == 'h';
  bool get isPublic => leagueType == 's';

  factory FplLeagueMembership.fromJson(Map<String, dynamic> json) {
    return FplLeagueMembership(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      leagueType: json['league_type'] as String? ?? 'x',
      scoring: json['scoring'] as String? ?? 'c',
      entryRank: json['entry_rank'] as int? ?? 0,
      entryLastRank: json['entry_last_rank'] as int? ?? 0,
    );
  }
}

/// A single player pick in an entry's GW squad.
class EntryPick {
  final int element;
  final int position; // 1-11 starting, 12-15 bench
  final int multiplier; // 1=normal, 2=captain, 3=triple captain, 0=benched
  final bool isCaptain;
  final bool isViceCaptain;
  final int purchasePrice; // in tenths of millions
  final int sellingPrice; // in tenths of millions

  const EntryPick({
    required this.element,
    required this.position,
    required this.multiplier,
    required this.isCaptain,
    required this.isViceCaptain,
    required this.purchasePrice,
    required this.sellingPrice,
  });

  bool get isStarting => position <= 11;

  factory EntryPick.fromJson(Map<String, dynamic> json) {
    return EntryPick(
      element: json['element'] as int,
      position: json['position'] as int,
      multiplier: json['multiplier'] as int? ?? 1,
      isCaptain: json['is_captain'] as bool? ?? false,
      isViceCaptain: json['is_vice_captain'] as bool? ?? false,
      purchasePrice: json['purchase_price'] as int? ?? 0,
      sellingPrice: json['selling_price'] as int? ?? 0,
    );
  }
}

/// Entry picks for a specific GW, including chip and financial data.
class EntryGwPicks {
  final int activeChip; // null if no chip; store as string
  final String? activeChipName;
  final List<EntryPick> picks;
  final int eventTransfers;
  final int eventTransfersCost;
  final int value; // team value in tenths of millions
  final int bank; // bank in tenths of millions
  final int points;
  final int pointsOnBench;

  const EntryGwPicks({
    this.activeChip = 0,
    this.activeChipName,
    required this.picks,
    required this.eventTransfers,
    required this.eventTransfersCost,
    required this.value,
    required this.bank,
    required this.points,
    required this.pointsOnBench,
  });

  List<EntryPick> get startingPicks => picks.where((p) => p.isStarting).toList()
    ..sort((a, b) => a.position.compareTo(b.position));

  List<EntryPick> get benchPicks => picks.where((p) => !p.isStarting).toList()
    ..sort((a, b) => a.position.compareTo(b.position));

  EntryPick? get captain => picks.where((p) => p.isCaptain).firstOrNull;
  EntryPick? get viceCaptain => picks.where((p) => p.isViceCaptain).firstOrNull;

  int get freeTransfers => eventTransfers - (eventTransfersCost ~/ 4);

  factory EntryGwPicks.fromJson(Map<String, dynamic> json) {
    final entryHistory = json['entry_history'] as Map<String, dynamic>? ?? {};
    return EntryGwPicks(
      activeChipName: json['active_chip'] as String?,
      picks: (json['picks'] as List<dynamic>? ?? [])
          .map((e) => EntryPick.fromJson(e as Map<String, dynamic>))
          .toList(),
      eventTransfers: entryHistory['event_transfers'] as int? ?? 0,
      eventTransfersCost: entryHistory['event_transfers_cost'] as int? ?? 0,
      value: entryHistory['value'] as int? ?? 0,
      bank: entryHistory['bank'] as int? ?? 0,
      points: entryHistory['points'] as int? ?? 0,
      pointsOnBench: entryHistory['points_on_bench'] as int? ?? 0,
    );
  }
}

/// Entry season history (one item per GW played).
class EntryGwHistory {
  final int event;
  final int points;
  final int totalPoints;
  final int rank;
  final int rankSort;
  final int overallRank;
  final int bank;
  final int value;
  final int eventTransfers;
  final int eventTransfersCost;
  final int pointsOnBench;
  final String? chipPlayed;

  const EntryGwHistory({
    required this.event,
    required this.points,
    required this.totalPoints,
    required this.rank,
    required this.rankSort,
    required this.overallRank,
    required this.bank,
    required this.value,
    required this.eventTransfers,
    required this.eventTransfersCost,
    required this.pointsOnBench,
    this.chipPlayed,
  });

  factory EntryGwHistory.fromJson(Map<String, dynamic> json) {
    return EntryGwHistory(
      event: json['event'] as int,
      points: json['points'] as int? ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      rankSort: json['rank_sort'] as int? ?? 0,
      overallRank: json['overall_rank'] as int? ?? 0,
      bank: json['bank'] as int? ?? 0,
      value: json['value'] as int? ?? 0,
      eventTransfers: json['event_transfers'] as int? ?? 0,
      eventTransfersCost: json['event_transfers_cost'] as int? ?? 0,
      pointsOnBench: json['points_on_bench'] as int? ?? 0,
    );
  }
}

/// Full season history for an entry.
class EntryHistory {
  final List<EntryGwHistory> current;
  final List<EntryChipPlay> chips;

  const EntryHistory({required this.current, required this.chips});

  factory EntryHistory.fromJson(Map<String, dynamic> json) {
    return EntryHistory(
      current: (json['current'] as List<dynamic>? ?? [])
          .map((e) => EntryGwHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      chips: (json['chips'] as List<dynamic>? ?? [])
          .map((e) => EntryChipPlay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EntryChipPlay {
  final String name;
  final int event;

  const EntryChipPlay({required this.name, required this.event});

  factory EntryChipPlay.fromJson(Map<String, dynamic> json) {
    return EntryChipPlay(
      name: json['name'] as String? ?? '',
      event: json['event'] as int? ?? 0,
    );
  }
}

/// A single transfer made by an entry.
class EntryTransfer {
  final int elementIn;
  final int elementInCost;
  final int elementOut;
  final int elementOutCost;
  final int event;
  final String time;

  const EntryTransfer({
    required this.elementIn,
    required this.elementInCost,
    required this.elementOut,
    required this.elementOutCost,
    required this.event,
    required this.time,
  });

  factory EntryTransfer.fromJson(Map<String, dynamic> json) {
    return EntryTransfer(
      elementIn: json['element_in'] as int,
      elementInCost: json['element_in_cost'] as int? ?? 0,
      elementOut: json['element_out'] as int,
      elementOutCost: json['element_out_cost'] as int? ?? 0,
      event: json['event'] as int,
      time: json['time'] as String? ?? '',
    );
  }
}

/// Live element stats for a single player in a GW.
class LiveElementStats {
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
  final int totalPoints;
  final bool inDreamteam;

  const LiveElementStats({
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
    required this.totalPoints,
    required this.inDreamteam,
  });

  factory LiveElementStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? json;
    return LiveElementStats(
      minutes: stats['minutes'] as int? ?? 0,
      goalsScored: stats['goals_scored'] as int? ?? 0,
      assists: stats['assists'] as int? ?? 0,
      cleanSheets: stats['clean_sheets'] as int? ?? 0,
      goalsConceded: stats['goals_conceded'] as int? ?? 0,
      ownGoals: stats['own_goals'] as int? ?? 0,
      penaltiesSaved: stats['penalties_saved'] as int? ?? 0,
      penaltiesMissed: stats['penalties_missed'] as int? ?? 0,
      yellowCards: stats['yellow_cards'] as int? ?? 0,
      redCards: stats['red_cards'] as int? ?? 0,
      saves: stats['saves'] as int? ?? 0,
      bonus: stats['bonus'] as int? ?? 0,
      bps: stats['bps'] as int? ?? 0,
      totalPoints: stats['total_points'] as int? ?? 0,
      inDreamteam: json['in_dreamteam'] as bool? ?? false,
    );
  }

  /// Returns a short event description string for the live feed.
  List<String> get eventDescriptions {
    final events = <String>[];
    if (goalsScored > 0) events.add('⚽ $goalsScored goal${goalsScored > 1 ? 's' : ''}');
    if (assists > 0) events.add('🎯 $assists assist${assists > 1 ? 's' : ''}');
    if (cleanSheets > 0) events.add('🧤 Clean sheet');
    if (yellowCards > 0) events.add('🟨 Yellow card');
    if (redCards > 0) events.add('🟥 Red card');
    if (saves >= 3) events.add('🥅 $saves saves');
    if (penaltiesSaved > 0) events.add('🛡 Penalty saved');
    if (ownGoals > 0) events.add('😬 $ownGoals own goal${ownGoals > 1 ? 's' : ''}');
    return events;
  }
}
