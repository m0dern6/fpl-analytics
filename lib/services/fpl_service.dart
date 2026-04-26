import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/player.dart';
import '../models/team.dart';
import '../models/gameweek.dart';
import '../models/fixture.dart';
import '../models/player_history.dart';
import '../models/element_type.dart';
import '../utils/constants.dart';

class FplService {
  static final FplService _instance = FplService._internal();
  factory FplService() => _instance;
  FplService._internal();

  Map<String, dynamic>? _bootstrapCache;
  DateTime? _bootstrapCacheTime;

  final Map<int, Map<String, dynamic>> _entryCache = {};
  final Map<String, Map<String, dynamic>> _picksCache = {};

  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<Map<String, dynamic>> fetchBootstrapData({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _bootstrapCache != null &&
        _bootstrapCacheTime != null &&
        DateTime.now().difference(_bootstrapCacheTime!) < _cacheDuration) {
      return _bootstrapCache!;
    }

    final response = await http.get(
      Uri.parse(ApiConstants.bootstrapStatic),
      headers: {'User-Agent': 'FPL Analytics App'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load bootstrap data: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    final players = (data['elements'] as List<dynamic>)
        .map((e) => Player.fromJson(e as Map<String, dynamic>))
        .toList();

    final teams = (data['teams'] as List<dynamic>)
        .map((e) => Team.fromJson(e as Map<String, dynamic>))
        .toList();

    final gameweeks = (data['events'] as List<dynamic>)
        .map((e) => Gameweek.fromJson(e as Map<String, dynamic>))
        .toList();

    final elementTypes = (data['element_types'] as List<dynamic>)
        .map((e) => ElementType.fromJson(e as Map<String, dynamic>))
        .toList();

    _bootstrapCache = {
      'players': players,
      'teams': teams,
      'events': gameweeks,
      'elementTypes': elementTypes,
      'gameSettings': data['game_settings'],
    };
    _bootstrapCacheTime = DateTime.now();

    return _bootstrapCache!;
  }

  Future<List<Fixture>> fetchAllFixtures() async {
    final response = await http.get(
      Uri.parse(ApiConstants.fixtures),
      headers: {'User-Agent': 'FPL Analytics App'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load fixtures: ${response.statusCode}');
    }

    final data = json.decode(response.body) as List<dynamic>;
    return data.map((e) => Fixture.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Fixture>> fetchFixturesForGameweek(int gw) async {
    final response = await http.get(
      Uri.parse(ApiConstants.fixturesForGw(gw)),
      headers: {'User-Agent': 'FPL Analytics App'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load GW$gw fixtures: ${response.statusCode}');
    }

    final data = json.decode(response.body) as List<dynamic>;
    return data.map((e) => Fixture.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PlayerSummary> fetchPlayerSummary(int playerId) async {
    final response = await http.get(
      Uri.parse(ApiConstants.elementSummary(playerId)),
      headers: {'User-Agent': 'FPL Analytics App'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load player summary: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return PlayerSummary.fromJson(data);
  }

  Future<Map<int, Map<String, dynamic>>> fetchLiveGameweekData(int gw) async {
    final response = await http.get(
      Uri.parse(ApiConstants.liveGw(gw)),
      headers: {'User-Agent': 'FPL Analytics App'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load live GW data: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>;

    final Map<int, Map<String, dynamic>> result = {};
    for (final element in elements) {
      final map = element as Map<String, dynamic>;
      result[map['id'] as int] = map['stats'] as Map<String, dynamic>;
    }
    return result;
  }

  Future<Map<int, int>> fetchDreamTeam(int gw) async {
    final response = await http.get(
      Uri.parse(ApiConstants.dreamTeam(gw)),
      headers: {'User-Agent': 'FPL Analytics App'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load dream team: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final squad = data['team'] as List<dynamic>;
    // Returns a map of { elementId: gwPoints }
    final Map<int, int> result = {};
    for (final entry in squad) {
      final map = entry as Map<String, dynamic>;
      result[map['element'] as int] = map['points'] as int? ?? 0;
    }
    return result;
  }

  Future<Map<String, dynamic>> fetchFplEntry(int entryId) async {
    if (_entryCache.containsKey(entryId)) return _entryCache[entryId]!;

    final response = await http.get(
      Uri.parse(ApiConstants.fplEntry(entryId)),
      headers: {'User-Agent': 'FPL Analytics App'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load FPL entry: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    _entryCache[entryId] = data;
    return data;
  }

  Future<Map<String, dynamic>> fetchFplEntryPicks(int entryId, int gw) async {
    final cacheKey = '${entryId}_$gw';
    if (_picksCache.containsKey(cacheKey)) return _picksCache[cacheKey]!;

    final response = await http.get(
      Uri.parse(ApiConstants.fplEntryPicks(entryId, gw)),
      headers: {'User-Agent': 'FPL Analytics App'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load entry picks: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    _picksCache[cacheKey] = data;
    return data;
  }

  Future<Map<String, dynamic>> fetchLeagueStandings(int leagueId) async {
    final response = await http.get(
      Uri.parse(ApiConstants.leagueStandings(leagueId)),
      headers: {'User-Agent': 'FPL Analytics App'},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load league standings: ${response.statusCode}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  void clearCache() {
    _bootstrapCache = null;
    _bootstrapCacheTime = null;
  }
}
