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

  void clearCache() {
    _bootstrapCache = null;
    _bootstrapCacheTime = null;
  }
}
