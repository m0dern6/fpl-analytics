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

  Map<String, List<Player>> getBestTeam() {
    const budget = 1000; // £100m in tenths

    final gks = List<Player>.from(getPlayersByPosition(1))
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    final defs = List<Player>.from(getPlayersByPosition(2))
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    final mids = List<Player>.from(getPlayersByPosition(3))
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    final fwds = List<Player>.from(getPlayersByPosition(4))
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    List<Player> picked = [];
    int spent = 0;

    // Pick 2 GKs
    int gkCount = 0;
    for (final p in gks) {
      if (gkCount < 2 && spent + p.nowCost <= budget - (5 - 0) * 40) {
        picked.add(p);
        spent += p.nowCost;
        gkCount++;
      }
      if (gkCount == 2) break;
    }

    // Pick 5 DEFs
    int defCount = 0;
    for (final p in defs) {
      if (defCount < 5) {
        picked.add(p);
        spent += p.nowCost;
        defCount++;
      }
      if (defCount == 5) break;
    }

    // Pick 5 MIDs
    int midCount = 0;
    for (final p in mids) {
      if (midCount < 5) {
        picked.add(p);
        spent += p.nowCost;
        midCount++;
      }
      if (midCount == 5) break;
    }

    // Pick 3 FWDs
    int fwdCount = 0;
    for (final p in fwds) {
      if (fwdCount < 3) {
        picked.add(p);
        spent += p.nowCost;
        fwdCount++;
      }
      if (fwdCount == 3) break;
    }

    // Handle budget overflow by swapping out expensive players with cheaper alternatives
    while (spent > budget && picked.isNotEmpty) {
      // Find and replace the most expensive player that has a cheaper alternative
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
      final cheaper = posPlayers.lastWhere(
        (p) => !pickedIds.contains(p.id) && p.nowCost < expensive.nowCost,
        orElse: () => expensive,
      );
      if (cheaper.id == expensive.id) break;
      spent -= expensive.nowCost;
      spent += cheaper.nowCost;
      picked.remove(expensive);
      picked.add(cheaper);
    }

    final startingGks = picked.where((p) => p.elementType == 1).take(1).toList();
    final startingDefs = picked.where((p) => p.elementType == 2).take(4).toList();
    final startingMids = picked.where((p) => p.elementType == 3).take(4).toList();
    final startingFwds = picked.where((p) => p.elementType == 4).take(3).toList();

    final starting = [...startingGks, ...startingDefs, ...startingMids, ...startingFwds];
    final subs = picked.where((p) => !starting.contains(p)).toList();

    return {
      'starting': starting,
      'subs': subs,
      'all': picked,
    };
  }

  Future<void> refresh() => loadAllData(forceRefresh: true);
}
