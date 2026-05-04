/// FPL Rule Logic — pure functions, no Flutter dependencies.
///
/// All values use integer tenths-of-millions for prices (matching the API),
/// e.g. £10.0m = 100.
///
/// These functions are unit-tested in test/fpl_rules_test.dart.
library fpl_rules;

// ── Sell Price ─────────────────────────────────────────────────────────────────

/// Official FPL sell-price rule.
///
/// If [currentPrice] > [purchasePrice], the seller receives:
///   purchasePrice + floor((currentPrice - purchasePrice) / 2)
///
/// If [currentPrice] <= [purchasePrice], sell price = [currentPrice].
///
/// All prices in integer tenths-of-millions (e.g. 100 = £10.0m).
int calculateSellPrice({
  required int purchasePrice,
  required int currentPrice,
}) {
  if (currentPrice > purchasePrice) {
    final profit = currentPrice - purchasePrice;
    return purchasePrice + (profit ~/ 2);
  }
  return currentPrice;
}

// ── Free Transfers & Hits ──────────────────────────────────────────────────────

/// Maximum number of banked free transfers in a single gameweek.
const int defaultMaxBankedFreeTransfers = 5;

/// Returns how many free transfers a manager has for the next gameweek.
///
/// [currentFreeTransfers] — FTs available *this* week.
/// [transfersMadeThisWeek] — How many transfers the manager made.
/// [maxBanked] — Season maximum banked FTs (default 5).
///
/// Logic:
///   unused = max(0, currentFreeTransfers - transfersMadeThisWeek)
///   nextFTs = clamp(unused + 1, 1, maxBanked)
int bankFreeTransfers({
  required int currentFreeTransfers,
  required int transfersMadeThisWeek,
  int maxBanked = defaultMaxBankedFreeTransfers,
}) {
  final unused = (currentFreeTransfers - transfersMadeThisWeek).clamp(0, maxBanked);
  // Each week the manager accrues 1 new FT on top of any rolled-over ones
  return (unused + 1).clamp(1, maxBanked);
}

/// Returns the hit (points deduction) for making [transfersMade] transfers
/// when [freeTransfers] are available.
///
/// Each extra transfer beyond the free allowance costs 4 points.
/// Returns a *negative* integer (e.g. -4 for 1 hit).
///
/// A wildcard or free-hit chip removes hits entirely — pass [chipActive] = true.
int calculateHits({
  required int transfersMade,
  required int freeTransfers,
  bool chipActive = false,
}) {
  if (chipActive) return 0;
  final hits = (transfersMade - freeTransfers).clamp(0, transfersMade);
  return -(hits * 4);
}

// ── Captain / Vice-Captain ─────────────────────────────────────────────────────

/// Represents a player's live stats for scoring purposes.
class LivePlayerStats {
  final int playerId;
  final int minutes;
  final int rawPoints;

  const LivePlayerStats({
    required this.playerId,
    required this.minutes,
    required this.rawPoints,
  });
}

/// Captain/Vice-captain point resolution result.
class CaptainResult {
  final int captainId;
  final bool usingVice;
  final int totalPoints;

  const CaptainResult({
    required this.captainId,
    required this.usingVice,
    required this.totalPoints,
  });
}

/// Resolves captain/vice-captain bonus points.
///
/// Rules:
/// - Captain gets double points.
/// - If the captain played 0 minutes AND at least one fixture in their GW has
///   started (indicated by [gwHasStarted] = true), the vice-captain gets
///   double points instead.
/// - "Played 0 minutes" = [captainStats.minutes] == 0.
///
/// Returns a [CaptainResult] with the effective captain ID and bonus points.
CaptainResult resolveCaptain({
  required LivePlayerStats captainStats,
  required LivePlayerStats viceCaptainStats,
  required bool gwHasStarted,
}) {
  final captainDidNotPlay = captainStats.minutes == 0 && gwHasStarted;

  if (captainDidNotPlay) {
    return CaptainResult(
      captainId: viceCaptainStats.playerId,
      usingVice: true,
      totalPoints: viceCaptainStats.rawPoints,
    );
  }
  return CaptainResult(
    captainId: captainStats.playerId,
    usingVice: false,
    totalPoints: captainStats.rawPoints,
  );
}

// ── Auto-Substitutions ─────────────────────────────────────────────────────────

/// Represents a player slot in a squad.
class SquadSlot {
  final int playerId;

  /// Position: 1=GK, 2=DEF, 3=MID, 4=FWD
  final int position;

  /// Slot index in squad (0–10 = starting XI, 11=bench GK, 12–14=bench outfield)
  final int slotIndex;

  const SquadSlot({
    required this.playerId,
    required this.position,
    required this.slotIndex,
  });

  bool get isStarting => slotIndex <= 10;
  bool get isBenchGk => slotIndex == 11;
  bool get isBenchOutfield => slotIndex >= 12;
}

/// Result of auto-substitution calculation.
class AutoSubResult {
  /// Map of replacements: outgoing player ID → incoming player ID
  final Map<int, int> subs;

  /// IDs of players that could not be substituted (bench exhausted / formation)
  final List<int> unresolved;

  const AutoSubResult({required this.subs, required this.unresolved});
}

/// Minimum formation constraints per position.
const Map<int, int> _minPlayers = {
  1: 1, // GK
  2: 3, // DEF
  3: 2, // MID
  4: 1, // FWD
};

/// Applies FPL auto-substitution logic.
///
/// For each starting player who did NOT play (minutes == 0) and whose
/// fixture has started (or is finished), find the first eligible bench
/// player in bench order (slots 12→13→14 for outfield, slot 11 for GK)
/// who DID play and whose inclusion does not violate formation minimums.
///
/// [squad] — Full 15-player squad (starting XI + bench).
/// [liveStats] — Map of playerId → [LivePlayerStats].
/// [gwHasStarted] — Whether at least one fixture in the GW has kicked off.
AutoSubResult applyAutoSubs({
  required List<SquadSlot> squad,
  required Map<int, LivePlayerStats> liveStats,
  required bool gwHasStarted,
}) {
  if (!gwHasStarted) return const AutoSubResult(subs: {}, unresolved: []);

  final starting = squad.where((s) => s.isStarting).toList();
  final benchGk = squad.where((s) => s.isBenchGk).toList();
  final benchOut = squad.where((s) => s.isBenchOutfield).toList()
    ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

  // Track current on-pitch formation counts
  final positionCount = <int, int>{};
  for (final s in starting) {
    positionCount[s.position] = (positionCount[s.position] ?? 0) + 1;
  }

  final subs = <int, int>{};
  final unresolved = <int>[];

  // Work on a mutable copy of starting to track who's been replaced
  final currentStarting = List<SquadSlot>.from(starting);
  final usedBenchIds = <int>{};

  for (final player in List<SquadSlot>.from(starting)) {
    final stats = liveStats[player.playerId];
    if (stats == null || stats.minutes > 0) continue; // playing or unknown

    // Determine which bench list to search
    if (player.position == 1) {
      // GK must be replaced by bench GK
      final eligible = benchGk.where(
        (b) {
          if (usedBenchIds.contains(b.playerId)) return false;
          final s = liveStats[b.playerId];
          return s != null && s.minutes > 0;
        },
      ).toList();

      if (eligible.isNotEmpty) {
        final sub = eligible.first;
        subs[player.playerId] = sub.playerId;
        usedBenchIds.add(sub.playerId);
        positionCount[1] = (positionCount[1] ?? 0); // unchanged (still 1 GK)
      } else {
        unresolved.add(player.playerId);
      }
    } else {
      // Outfield sub — respect formation constraints
      bool found = false;
      for (final bench in benchOut) {
        if (usedBenchIds.contains(bench.playerId)) continue;
        final s = liveStats[bench.playerId];
        if (s == null || s.minutes == 0) continue;

        // Check: removing [player] and adding [bench] is formation-legal
        final newCount = Map<int, int>.from(positionCount);
        newCount[player.position] = (newCount[player.position] ?? 1) - 1;
        newCount[bench.position] = (newCount[bench.position] ?? 0) + 1;

        bool legal = true;
        for (final entry in _minPlayers.entries) {
          if (entry.key == 1) continue; // GK handled separately
          if ((newCount[entry.key] ?? 0) < entry.value) {
            legal = false;
            break;
          }
        }
        if (!legal) continue;

        subs[player.playerId] = bench.playerId;
        usedBenchIds.add(bench.playerId);
        positionCount[player.position] = newCount[player.position]!;
        positionCount[bench.position] = newCount[bench.position]!;
        found = true;
        break;
      }
      if (!found) unresolved.add(player.playerId);
    }
  }

  return AutoSubResult(subs: subs, unresolved: unresolved);
}

// ── Chip State ─────────────────────────────────────────────────────────────────

/// Known FPL chip names as returned by the API.
class ChipNames {
  static const String wildcard = 'wildcard';
  static const String freeHit = 'freehit';
  static const String benchBoost = 'bboost';
  static const String tripleCaptain = '3xc';
}

/// Returns true if the given [chipName] was used in [activeChip] or [usedChips].
///
/// [activeChip] — The chip currently active (from picks response: `active_chip`).
/// [usedChips] — Chips already used this season (from history: chip name list).
bool isChipUsed({
  required String chipName,
  String? activeChip,
  List<String> usedChips = const [],
}) {
  if (activeChip == chipName) return true;
  return usedChips.contains(chipName);
}

/// Returns the currently active chip name, or null if none.
String? activeChip(String? rawActiveChip) {
  if (rawActiveChip == null || rawActiveChip.isEmpty) return null;
  return rawActiveChip;
}

// ── Points Calculation ─────────────────────────────────────────────────────────

/// Calculates the total GW points for a squad considering captain bonus,
/// auto-subs, and active chip.
///
/// [startingIds] — Player IDs in starting XI (ordered, 0=GK, 1-10=outfield).
/// [benchIds] — Player IDs on bench (ordered by priority).
/// [captainId] — Captain player ID.
/// [viceCaptainId] — Vice-captain player ID.
/// [liveStats] — Map of playerId → [LivePlayerStats].
/// [gwHasStarted] — Whether the GW has kicked off.
/// [activeChipName] — Optional active chip name.
/// [squad] — Full squad slots (for auto-sub calculation).
int calculateGwPoints({
  required List<int> startingIds,
  required int captainId,
  required int viceCaptainId,
  required Map<int, LivePlayerStats> liveStats,
  required bool gwHasStarted,
  String? activeChipName,
  List<SquadSlot> squad = const [],
}) {
  final isBenchBoost = activeChipName == ChipNames.benchBoost;
  final isTripleCaptain = activeChipName == ChipNames.tripleCaptain;

  // Determine effective squad (auto-subs applied unless bench boost)
  final effectiveStarting = List<int>.from(startingIds);

  if (!isBenchBoost && squad.isNotEmpty) {
    final result = applyAutoSubs(
      squad: squad,
      liveStats: liveStats,
      gwHasStarted: gwHasStarted,
    );
    for (final entry in result.subs.entries) {
      final idx = effectiveStarting.indexOf(entry.key);
      if (idx >= 0) effectiveStarting[idx] = entry.value;
    }
  }

  // Captain resolution
  final captainStats = liveStats[captainId] ??
      LivePlayerStats(playerId: captainId, minutes: 0, rawPoints: 0);
  final viceStats = liveStats[viceCaptainId] ??
      LivePlayerStats(playerId: viceCaptainId, minutes: 0, rawPoints: 0);

  final captainResult = resolveCaptain(
    captainStats: captainStats,
    viceCaptainStats: viceStats,
    gwHasStarted: gwHasStarted,
  );

  // Sum points
  int total = 0;
  final playerIds = isBenchBoost
      ? [...startingIds, ...squad.where((s) => !s.isStarting).map((s) => s.playerId)]
      : effectiveStarting;

  for (final id in playerIds) {
    final stats = liveStats[id];
    if (stats == null) continue;
    int pts = stats.rawPoints;

    if (id == captainResult.captainId) {
      pts += isTripleCaptain ? pts * 2 : pts; // triple cap = 3x total = pts + 2*pts
    }

    total += pts;
  }

  return total;
}
