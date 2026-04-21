import 'package:flutter/foundation.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/gameweek.dart';
import '../models/fixture.dart';
import '../models/player_history.dart';
import '../models/element_type.dart';
import '../services/fpl_service.dart';

class FplProvider extends ChangeNotifier {
  final FplService _service = FplService();

  List<Player> _players = [];
  List<Team> _teams = [];
  List<Gameweek> _gameweeks = [];
  List<Fixture> _fixtures = [];
  List<ElementType> _elementTypes = [];
  Map<int, PlayerSummary> _playerSummaries = {};
  Map<int, Map<String, dynamic>> _liveData = {};
  Map<int, List<Player>> _dreamTeams = {};
  Map<int, Map<int, int>> _dreamTeamPoints = {}; // gw -> { playerId: gwPoints }

  bool _isLoading = false;
  bool _isLoadingFixtures = false;
  String? _error;
  Gameweek? _currentGameweek;

  List<Player> get players => _players;
  List<Team> get teams => _teams;
  List<Gameweek> get gameweeks => _gameweeks;
  List<Fixture> get fixtures => _fixtures;
  List<ElementType> get elementTypes => _elementTypes;
  bool get isLoading => _isLoading;
  bool get isLoadingFixtures => _isLoadingFixtures;
  String? get error => _error;
  Gameweek? get currentGameweek => _currentGameweek;

  Future<void> loadAllData({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bootstrapData = await _service.fetchBootstrapData(forceRefresh: forceRefresh);
      _players = bootstrapData['players'] as List<Player>;
      _teams = bootstrapData['teams'] as List<Team>;
      _gameweeks = bootstrapData['events'] as List<Gameweek>;
      _elementTypes = bootstrapData['elementTypes'] as List<ElementType>;

      _currentGameweek = _gameweeks.firstWhere(
        (gw) => gw.isCurrent,
        orElse: () => _gameweeks.firstWhere(
          (gw) => gw.isNext,
          orElse: () => _gameweeks.last,
        ),
      );

      await _loadFixtures();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFixtures() async {
    _isLoadingFixtures = true;
    notifyListeners();
    try {
      _fixtures = await _service.fetchAllFixtures();
    } catch (_) {
      // Non-fatal: fixtures not essential
    } finally {
      _isLoadingFixtures = false;
      notifyListeners();
    }
  }

  Future<PlayerSummary?> loadPlayerSummary(int playerId) async {
    if (_playerSummaries.containsKey(playerId)) {
      return _playerSummaries[playerId];
    }
    try {
      final summary = await _service.fetchPlayerSummary(playerId);
      _playerSummaries[playerId] = summary;
      notifyListeners();
      return summary;
    } catch (e) {
      return null;
    }
  }

  Future<void> loadLiveGwData(int gw) async {
    try {
      _liveData = await _service.fetchLiveGameweekData(gw);
      notifyListeners();
    } catch (_) {}
  }

  Map<String, dynamic>? getLiveStatsForPlayer(int playerId) {
    return _liveData[playerId];
  }

  PlayerSummary? getPlayerSummary(int playerId) => _playerSummaries[playerId];

  Future<void> loadDreamTeam(int gw) async {
    if (_dreamTeams.containsKey(gw)) return;
    try {
      final pointsMap = await _service.fetchDreamTeam(gw);
      final dreamTeamPlayers = pointsMap.keys
          .map((id) => getPlayerById(id))
          .whereType<Player>()
          .toList();
      _dreamTeams[gw] = dreamTeamPlayers;
      _dreamTeamPoints[gw] = pointsMap;
      notifyListeners();
    } catch (_) {}
  }

  List<Player> getDreamTeam(int gw) => _dreamTeams[gw] ?? [];

  /// Returns the gameweek points for a player in a specific dream-team GW.
  /// Falls back to [Player.eventPoints] if not available.
  int getDreamTeamPlayerPoints(int gw, int playerId) {
    return _dreamTeamPoints[gw]?[playerId] ?? 0;
  }

  Team? getTeamById(int teamId) {
    try {
      return _teams.firstWhere((t) => t.id == teamId);
    } catch (_) {
      return null;
    }
  }

  Player? getPlayerById(int playerId) {
    try {
      return _players.firstWhere((p) => p.id == playerId);
    } catch (_) {
      return null;
    }
  }

  List<Player> getPlayersByPosition(int elementType) =>
      _players.where((p) => p.elementType == elementType).toList();

  List<Player> getTopTransfersIn({int limit = 10}) {
    final sorted = List<Player>.from(_players)
      ..sort((a, b) => b.transfersInEvent.compareTo(a.transfersInEvent));
    return sorted.take(limit).toList();
  }

  List<Player> getTopTransfersOut({int limit = 10}) {
    final sorted = List<Player>.from(_players)
      ..sort((a, b) => b.transfersOutEvent.compareTo(a.transfersOutEvent));
    return sorted.take(limit).toList();
  }

  List<Player> getTopBonusPlayers({int limit = 10}) {
    final sorted = List<Player>.from(_players)
      ..sort((a, b) => b.bonus.compareTo(a.bonus));
    return sorted.take(limit).toList();
  }

  List<Player> searchPlayers(String query) {
    if (query.isEmpty) return _players;
    final q = query.toLowerCase();
    return _players
        .where((p) =>
            p.webName.toLowerCase().contains(q) ||
            p.firstName.toLowerCase().contains(q) ||
            p.secondName.toLowerCase().contains(q))
        .toList();
  }

  List<Player> getTopScorersByPoints({int limit = 10}) {
    final sorted = List<Player>.from(_players)
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return sorted.take(limit).toList();
  }

  List<Player> getTopScorersByGoals({int limit = 10}) {
    final sorted = List<Player>.from(_players)
      ..sort((a, b) => b.goals.compareTo(a.goals));
    return sorted.take(limit).toList();
  }

  List<Player> getTopScorersByAssists({int limit = 10}) {
    final sorted = List<Player>.from(_players)
      ..sort((a, b) => b.assists.compareTo(a.assists));
    return sorted.take(limit).toList();
  }

  List<Player> getTopScorersByCleanSheets({int limit = 10}) {
    final sorted = List<Player>.from(_players)
      ..sort((a, b) => b.cleanSheets.compareTo(a.cleanSheets));
    return sorted.take(limit).toList();
  }

  List<Player> getTopScorersByICT({int limit = 10}) {
    final sorted = List<Player>.from(_players)
      ..sort((a, b) => b.ictValue.compareTo(a.ictValue));
    return sorted.take(limit).toList();
  }

  List<Player> getTopScorersByForm({int limit = 10}) {
    final sorted = List<Player>.from(_players)
      ..sort((a, b) => b.formValue.compareTo(a.formValue));
    return sorted.take(limit).toList();
  }

  List<Fixture> getFixturesForTeam(int teamId) =>
      _fixtures.where((f) => f.homeTeamId == teamId || f.awayTeamId == teamId).toList();

  List<Fixture> getFixturesForGameweek(int gw) =>
      _fixtures.where((f) => f.event == gw).toList();

  List<Fixture> getUpcomingFixtures({int limit = 10}) {
    final now = DateTime.now();
    return _fixtures
        .where((f) => !f.finished && f.kickoffTime != null && DateTime.tryParse(f.kickoffTime!)?.isAfter(now) == true)
        .take(limit)
        .toList();
  }

  /// Returns the next-gameweek fixture difficulty (1–5) for [teamId].
  /// Defaults to 3 (medium) if no fixture is found.
  int getNextFixtureDifficulty(int teamId) {
    final gwId = _currentGameweek?.id ?? 1;
    final gwFixtures = getFixturesForGameweek(gwId);
    for (final f in gwFixtures) {
      if (f.homeTeamId == teamId) return f.teamHDifficulty;
      if (f.awayTeamId == teamId) return f.teamADifficulty;
    }
    return 3;
  }

  /// Composite score combining form, ICT, PPG, value, fixture difficulty
  /// and availability to rank players for the upcoming gameweek.
  double computePlayerScore(Player p) {
    return _computeScore(p, mode: AiPickMode.bestXi);
  }

  /// Mode-aware scoring used by the AI Picks feature.
  double _computeScore(Player p, {required AiPickMode mode}) {
    double score = 0;

    // Season total points (baseline)
    score += p.totalPoints * 0.3;

    // Recent form – most predictive of next-GW output
    score += p.formValue * 12.0;

    // Points per game
    score += p.ppgValue * 6.0;

    // ICT index
    score += p.ictValue * 0.25;

    // Value (pts per million) – less important for Free Hit
    if (mode != AiPickMode.freeHit) {
      score += p.valueSeasonValue * 1.5;
    }

    // xG contribution (proxy: expectedGoalsStr)
    final xg = double.tryParse(p.expectedGoalsStr) ?? 0;
    final xa = double.tryParse(p.expectedAssistsStr) ?? 0;
    score += xg * 8.0 + xa * 5.0;

    // Fixture difficulty weighting
    if (mode == AiPickMode.wildcard) {
      // Wildcard: average difficulty over next 5 GWs
      final gwId = _currentGameweek?.id ?? 1;
      double totalDiff = 0;
      int count = 0;
      for (int gw = gwId; gw <= gwId + 4 && gw <= 38; gw++) {
        final gwFixtures = getFixturesForGameweek(gw);
        for (final f in gwFixtures) {
          if (f.homeTeamId == p.teamId) {
            totalDiff += f.teamHDifficulty;
            count++;
            break;
          } else if (f.awayTeamId == p.teamId) {
            totalDiff += f.teamADifficulty;
            count++;
            break;
          }
        }
      }
      final avgDiff = count > 0 ? totalDiff / count : 3.0;
      score += (6 - avgDiff) * 4.0;
    } else {
      final diff = getNextFixtureDifficulty(p.teamId);
      score += (6 - diff) * 4.0;
    }

    // Triple Captain: boost highest-scoring players further
    if (mode == AiPickMode.tripleCaptain) {
      score += p.totalPoints * 0.5;
      score += p.formValue * 6.0;
    }

    // Availability penalty
    if (p.chanceOfPlayingNextRound != null) {
      score *= (p.chanceOfPlayingNextRound! / 100.0);
    } else if (p.status != 'a') {
      score *= 0.5;
    }

    // Transfer momentum (normalised, capped)
    score += (p.transfersInEvent / 100000.0).clamp(0.0, 3.0);

    return score;
  }

  Map<String, List<Player>> getBestTeam() {
    return computeAiTeam(AiPickMode.bestXi);
  }

  /// Compute AI team for a given chip/mode.
  /// Free Hit has no budget cap; others use £100m.
  Map<String, List<Player>> computeAiTeam(AiPickMode mode) {
    // Free Hit has no budget restriction; all other modes use £100m (1000 in tenths)
    final budget = mode == AiPickMode.freeHit ? 0x7FFFFFFF : 1000;

    List<Player> ranked(int pos) => (List<Player>.from(getPlayersByPosition(pos))
      ..sort((a, b) => _computeScore(b, mode: mode)
          .compareTo(_computeScore(a, mode: mode))));

    final gks = ranked(1);
    final defs = ranked(2);
    final mids = ranked(3);
    final fwds = ranked(4);

    final List<Player> picked = [];
    int spent = 0;
    final teamCount = <int, int>{};

    bool canPickFromTeam(int teamId) => (teamCount[teamId] ?? 0) < 3;

    void pickPlayer(Player p) {
      picked.add(p);
      spent += p.nowCost;
      teamCount[p.teamId] = (teamCount[p.teamId] ?? 0) + 1;
    }

    void pickN(List<Player> pool, int n) {
      int count = 0;
      for (final p in pool) {
        if (count >= n) break;
        if (canPickFromTeam(p.teamId)) { pickPlayer(p); count++; }
      }
    }

    pickN(gks, 2);
    pickN(defs, 5);
    pickN(mids, 5);
    pickN(fwds, 3);

    // Handle budget overflow by swapping expensive players with cheaper ones
    while (spent > budget && picked.isNotEmpty) {
      picked.sort((a, b) => b.nowCost.compareTo(a.nowCost));
      final expensive = picked.first;
      final posPlayers = switch (expensive.elementType) {
        1 => gks,
        2 => defs,
        3 => mids,
        4 => fwds,
        _ => <Player>[]
      };
      final pickedIds = picked.map((p) => p.id).toSet();
      teamCount[expensive.teamId] = (teamCount[expensive.teamId] ?? 1) - 1;
      final cheaper = posPlayers.lastWhere(
        (p) => !pickedIds.contains(p.id) && p.nowCost < expensive.nowCost,
        orElse: () => expensive,
      );
      if (cheaper.id == expensive.id) {
        teamCount[expensive.teamId] = (teamCount[expensive.teamId] ?? 0) + 1;
        break;
      }
      spent -= expensive.nowCost;
      spent += cheaper.nowCost;
      picked.remove(expensive);
      picked.add(cheaper);
      teamCount[cheaper.teamId] = (teamCount[cheaper.teamId] ?? 0) + 1;
    }

    final startingGks = picked.where((p) => p.elementType == 1).take(1).toList();
    final startingDefs = picked.where((p) => p.elementType == 2).take(4).toList();
    final startingMids = picked.where((p) => p.elementType == 3).take(4).toList();
    final startingFwds = picked.where((p) => p.elementType == 4).take(3).toList();

    final starting = [...startingGks, ...startingDefs, ...startingMids, ...startingFwds];
    final subs = picked.where((p) => !starting.contains(p)).toList();

    // Captain: highest score among starting 11
    Player? captain;
    Player? viceCaptain;
    if (starting.isNotEmpty) {
      final sorted = List<Player>.from(starting)
        ..sort((a, b) => _computeScore(b, mode: mode)
            .compareTo(_computeScore(a, mode: mode)));
      captain = sorted.isNotEmpty ? sorted.first : null;
      viceCaptain = sorted.length > 1 ? sorted[1] : null;
    }

    return {
      'starting': starting,
      'subs': subs,
      'all': picked,
      if (captain != null) 'captain': [captain],
      if (viceCaptain != null) 'viceCaptain': [viceCaptain],
    };
  }

  Future<void> refresh() => loadAllData(forceRefresh: true);
}

enum AiPickMode {
  bestXi,
  wildcard,
  freeHit,
  tripleCaptain,
  benchBoost,
}
