class Gameweek {
  final int id;
  final String name;
  final String deadlineTime;
  final int? averageEntryScore;
  final bool finished;
  final bool dataChecked;
  final int? highestScore;
  final int? highestScoringEntry;
  final bool isPrevious;
  final bool isCurrent;
  final bool isNext;
  final int? mostSelected;
  final int? mostTransferredIn;
  final int? topElement;
  final int? mostCaptained;
  final int? mostViceCaptained;
  final int transfersMade;
  final int chipPlays;

  const Gameweek({
    required this.id,
    required this.name,
    required this.deadlineTime,
    this.averageEntryScore,
    required this.finished,
    required this.dataChecked,
    this.highestScore,
    this.highestScoringEntry,
    required this.isPrevious,
    required this.isCurrent,
    required this.isNext,
    this.mostSelected,
    this.mostTransferredIn,
    this.topElement,
    this.mostCaptained,
    this.mostViceCaptained,
    this.transfersMade = 0,
    this.chipPlays = 0,
  });

  factory Gameweek.fromJson(Map<String, dynamic> json) {
    return Gameweek(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      deadlineTime: json['deadline_time'] as String? ?? '',
      averageEntryScore: json['average_entry_score'] as int?,
      finished: json['finished'] as bool? ?? false,
      dataChecked: json['data_checked'] as bool? ?? false,
      highestScore: json['highest_score'] as int?,
      highestScoringEntry: json['highest_scoring_entry'] as int?,
      isPrevious: json['is_previous'] as bool? ?? false,
      isCurrent: json['is_current'] as bool? ?? false,
      isNext: json['is_next'] as bool? ?? false,
      mostSelected: json['most_selected'] as int?,
      mostTransferredIn: json['most_transferred_in'] as int?,
      topElement: json['top_element'] as int?,
      mostCaptained: json['most_captained'] as int?,
      mostViceCaptained: json['most_vice_captained'] as int?,
      transfersMade: json['transfers_made'] as int? ?? 0,
    );
  }

  String get statusLabel {
    if (finished) return 'Finished';
    if (isCurrent) return 'Active';
    if (isNext) return 'Next';
    return 'Upcoming';
  }
}
