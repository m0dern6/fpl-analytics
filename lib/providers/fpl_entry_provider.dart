import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import '../models/player.dart';
import '../models/gameweek.dart';
import '../logic/fpl_rules.dart';
import '../services/fpl_service.dart';
import '../services/local_storage_service.dart';

/// State for a linked FPL entry (manager's team).
class FplEntryProvider extends ChangeNotifier {
  final FplService _service = FplService();
  final LocalStorageService _storage = LocalStorageService();

  int? _entryId;
  FplEntry? _entry;
  EntryGwPicks? _currentPicks;
  EntryHistory? _history;
  List<EntryTransfer> _transfers = [];
  Map<int, EntryGwPicks> _picksCache = {};

  bool _isLoading = false;
  bool _isStreamerMode = false;
  bool _initDone = false;
  bool _skippedOnboarding = false;
  String? _error;
  DateTime? _lastUpdated;

  // Live scoring state
  Map<int, LiveElementStats> _liveStats = {};
  int? _liveGw;
  bool _gwHasStarted = false;

  // Getters
  int? get entryId => _entryId;
  FplEntry? get entry => _entry;
  EntryGwPicks? get currentPicks => _currentPicks;
  EntryHistory? get history => _history;
  List<EntryTransfer> get transfers => _transfers;
  bool get isLoading => _isLoading;
  bool get hasEntry => _entryId != null && _entry != null;
  bool get initDone => _initDone;
  bool get skippedOnboarding => _skippedOnboarding;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isStreamerMode => _isStreamerMode;
  Map<int, LiveElementStats> get liveStats => _liveStats;

  // ── Initialisation ────────────────────────────────────────────────────────────

  Future<void> init() async {
    _isStreamerMode = await _storage.getStreamerMode();
    final savedId = await _storage.getEntryId();
    if (savedId != null) {
      await loadEntry(savedId);
    }
    _initDone = true;
    notifyListeners();
  }

  // ── Entry Loading ─────────────────────────────────────────────────────────────

  Future<bool> loadEntry(int entryId, {bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entryId = entryId;
      await _storage.saveEntryId(entryId);

      _entry = await _service.fetchFplEntry(entryId, forceRefresh: forceRefresh);
      _lastUpdated = DateTime.now();

      // Save profile
      await _storage.saveProfile({
        'entryId': entryId,
        'name': _entry!.name,
        'playerName': _entry!.fullName,
        'addedAt': DateTime.now().toIso8601String(),
      });

      // Load current GW picks
      final currentGw = _entry!.currentEvent;
      if (currentGw > 0) {
        try {
          _currentPicks = await _service.fetchFplEntryPicks(
            entryId,
            currentGw,
            forceRefresh: forceRefresh,
          );
          _picksCache[currentGw] = _currentPicks!;
        } catch (_) {
          // Non-fatal
        }
      }

      // Load history (background)
      _loadHistoryAndTransfers(entryId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadHistoryAndTransfers(int entryId) async {
    try {
      _history = await _service.fetchEntryHistory(entryId);
      notifyListeners();
    } catch (_) {}
    try {
      _transfers = await _service.fetchEntryTransfers(entryId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refresh() async {
    if (_entryId == null) return;
    await loadEntry(_entryId!, forceRefresh: true);
  }

  // ── Picks for a specific GW ───────────────────────────────────────────────────

  Future<EntryGwPicks?> getPicksForGw(int gw) async {
    if (_picksCache.containsKey(gw)) return _picksCache[gw];
    if (_entryId == null) return null;
    try {
      final picks = await _service.fetchFplEntryPicks(_entryId!, gw);
      _picksCache[gw] = picks;
      notifyListeners();
      return picks;
    } catch (_) {
      return null;
    }
  }

  // ── Live Scoring ──────────────────────────────────────────────────────────────

  Future<void> loadLiveData(
    int gw, {
    required List<Gameweek> gameweeks,
    required Map<int, int> playerPositions,
  }) async {
    try {
      _liveStats = await _service.fetchLiveGameweekData(gw);
      _liveGw = gw;

      // Determine if GW has started
      final gwFixtures = gameweeks.where((g) => g.id == gw).toList();
      _gwHasStarted = _liveStats.values.any((s) => s.minutes > 0);

      notifyListeners();
    } catch (_) {}
  }

  /// Calculates live total points for the current picks.
  int get livePoints {
    if (_currentPicks == null || _liveStats.isEmpty) return 0;

    final picks = _currentPicks!;
    final captainPick = picks.captain;
    final vicePick = picks.viceCaptain;

    if (captainPick == null) return 0;

    final captainStats = liveStatsFor(captainPick.element) ??
        LivePlayerStats(playerId: captainPick.element, minutes: 0, rawPoints: 0);
    final viceStats = vicePick != null
        ? liveStatsFor(vicePick.element) ??
            LivePlayerStats(playerId: vicePick.element, minutes: 0, rawPoints: 0)
        : LivePlayerStats(playerId: 0, minutes: 0, rawPoints: 0);

    final captainResult = resolveCaptain(
      captainStats: captainStats,
      viceCaptainStats: viceStats,
      gwHasStarted: _gwHasStarted,
    );

    final isTripleCaptain = picks.activeChipName == ChipNames.tripleCaptain;
    final isBenchBoost = picks.activeChipName == ChipNames.benchBoost;

    int total = 0;
    final playerIds = isBenchBoost
        ? picks.picks.map((p) => p.element)
        : picks.startingPicks.map((p) => p.element);

    for (final id in playerIds) {
      final live = _liveStats[id];
      if (live == null) continue;
      int pts = live.totalPoints;
      if (id == captainResult.captainId) {
        pts += isTripleCaptain ? pts * 2 : pts;
      }
      total += pts;
    }

    return total + picks.eventTransfersCost; // hits are negative
  }

  /// Returns auto-sub predictions based on current live data.
  AutoSubResult? get predictedAutoSubs {
    if (_currentPicks == null || _liveStats.isEmpty) return null;
    // Build squad slots from picks
    // We need player positions — this would normally come from FplProvider
    // Return null if we don't have enough data
    return null;
  }

  AutoSubResult predictAutoSubsWithPositions(
    Map<int, int> playerPositions, // playerId → elementType
  ) {
    if (_currentPicks == null) {
      return const AutoSubResult(subs: {}, unresolved: []);
    }

    final picks = _currentPicks!.picks;
    final slots = picks.map((p) {
      final pos = playerPositions[p.element] ?? 3;
      return SquadSlot(
        playerId: p.element,
        position: pos,
        slotIndex: p.position - 1, // API position is 1-based
      );
    }).toList();

    final liveForRules = _liveStats.map((id, stats) => MapEntry(
          id,
          LivePlayerStats(
            playerId: id,
            minutes: stats.minutes,
            rawPoints: stats.totalPoints,
          ),
        ));

    return applyAutoSubs(
      squad: slots,
      liveStats: liveForRules,
      gwHasStarted: _gwHasStarted,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  LivePlayerStats? liveStatsFor(int playerId) {
    final live = _liveStats[playerId];
    if (live == null) return null;
    return LivePlayerStats(
      playerId: playerId,
      minutes: live.minutes,
      rawPoints: live.totalPoints,
    );
  }

  LiveElementStats? getLiveElement(int playerId) => _liveStats[playerId];

  /// Points on bench (live) for the current GW.
  int get liveBenchPoints {
    if (_currentPicks == null || _liveStats.isEmpty) return 0;
    return _currentPicks!.benchPicks.fold(0, (sum, p) {
      final live = _liveStats[p.element];
      return sum + (live?.totalPoints ?? 0);
    });
  }

  // ── Season Stats ──────────────────────────────────────────────────────────────

  int get totalHitsThisSeason {
    return _history?.current
            .fold(0, (sum, gw) => sum + (gw.eventTransfersCost ~/ 4)) ??
        0;
  }

  int get totalPointsOnBench {
    return _history?.current
            .fold(0, (sum, gw) => sum + gw.pointsOnBench) ??
        0;
  }

  List<EntryChipPlay> get usedChips => _history?.chips ?? [];

  bool isChipAvailable(String chipName) {
    if (_currentPicks?.activeChipName == chipName) return false;
    return !usedChips.any((c) => c.name == chipName);
  }

  // ── Free Transfers ────────────────────────────────────────────────────────────

  /// Current free transfers available, reading from entry history.
  int get currentFreeTransfers {
    if (_history == null || _history!.current.isEmpty) return 1;
    // The last completed GW's transfers determine rollover
    final lastGw = _history!.current.last;
    return bankFreeTransfers(
      currentFreeTransfers: 1, // simplified: start with 1
      transfersMadeThisWeek: lastGw.eventTransfers,
    );
  }

  // ── Profiles ──────────────────────────────────────────────────────────────────

  Future<void> switchToProfile(int entryId) async {
    await loadEntry(entryId, forceRefresh: false);
  }

  void clearEntry() {
    _entryId = null;
    _entry = null;
    _currentPicks = null;
    _history = null;
    _transfers = [];
    _picksCache = {};
    _error = null;
    _storage.clearEntryId();
    notifyListeners();
  }

  void skipOnboarding() {
    _skippedOnboarding = true;
    notifyListeners();
  }

  // ── Streamer Mode ─────────────────────────────────────────────────────────────

  Future<void> setStreamerMode(bool enabled) async {
    _isStreamerMode = enabled;
    await _storage.setStreamerMode(enabled);
    notifyListeners();
  }

  String get displayEntryId => _isStreamerMode ? '••••••' : (_entryId?.toString() ?? '');
  String get displayTeamName => _isStreamerMode ? '••••••••' : (_entry?.name ?? '');
  String get displayManagerName => _isStreamerMode ? '••••••••' : (_entry?.fullName ?? '');
}
