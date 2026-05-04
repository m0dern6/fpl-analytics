import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/player.dart';
import '../models/team.dart';
import '../models/gameweek.dart';
import '../models/fixture.dart';
import '../models/player_history.dart';
import '../models/element_type.dart';
import '../models/entry.dart';
import '../utils/constants.dart';
import 'local_storage_service.dart';

class FplService {
  static final FplService _instance = FplService._internal();
  factory FplService() => _instance;
  FplService._internal();

  final LocalStorageService _storage = LocalStorageService();

  Map<String, dynamic>? _bootstrapCache;
  DateTime? _bootstrapCacheTime;
  Map<int, Map<String, dynamic>>? _liveCache;
  int? _liveCacheGw;
  DateTime? _liveCacheTime;

  static const Duration _bootstrapMemTtl = Duration(minutes: 5);
  static const Duration _bootstrapDiskTtl = Duration(hours: 1);
  static const Duration _fixtureDiskTtl = Duration(minutes: 30);
  static const Duration _playerSummaryDiskTtl = Duration(minutes: 15);
  static const Duration _picksDiskTtl = Duration(minutes: 10);
  static const Duration _liveTtl = Duration(minutes: 2);
  static const Duration _leagueDiskTtl = Duration(minutes: 10);

  static const Map<String, String> _headers = {
    'User-Agent': 'FPL Analytics App',
  };

  Future<http.Response> _get(String url) async {
    return http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 30));
  }

  // ── Bootstrap Static ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchBootstrapData({bool forceRefresh = false}) async {
    // In-memory cache
    if (!forceRefresh &&
        _bootstrapCache != null &&
        _bootstrapCacheTime != null &&
        DateTime.now().difference(_bootstrapCacheTime!) < _bootstrapMemTtl) {
      return _bootstrapCache!;
    }

    // Disk cache
    if (!forceRefresh) {
      final cached = await _storage.getCache('bootstrap', _bootstrapDiskTtl);
      if (cached != null) {
        return _parseBootstrap(jsonDecode(cached) as Map<String, dynamic>);
      }
    }

    // Network
    final response = await _get(ApiConstants.bootstrapStatic);

    if (response.statusCode != 200) {
      // Offline fallback: try disk regardless of TTL
      final meta = await _storage.getCacheWithMeta('bootstrap');
      if (meta.data != null) {
        return _parseBootstrap(
            jsonDecode(meta.data!) as Map<String, dynamic>,
            offlineCachedAt: meta.cachedAt);
      }
      throw Exception('Failed to load bootstrap data: ${response.statusCode}');
    }

    await _storage.setCache('bootstrap', response.body);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Save price snapshot for daily tracking
    final prices = <int, int>{};
    for (final e in (data['elements'] as List<dynamic>)) {
      final m = e as Map<String, dynamic>;
      prices[m['id'] as int] = m['now_cost'] as int;
    }
    await _storage.savePriceSnapshot(prices);

    return _parseBootstrap(data);
  }

  Map<String, dynamic> _parseBootstrap(
    Map<String, dynamic> data, {
    DateTime? offlineCachedAt,
  }) {
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

    final result = {
      'players': players,
      'teams': teams,
      'events': gameweeks,
      'elementTypes': elementTypes,
      'gameSettings': data['game_settings'],
      if (offlineCachedAt != null) 'offlineCachedAt': offlineCachedAt,
    };

    _bootstrapCache = result;
    _bootstrapCacheTime = DateTime.now();
    return result;
  }

  // ── Fixtures ──────────────────────────────────────────────────────────────────

  Future<List<Fixture>> fetchAllFixtures({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _storage.getCache('fixtures_all', _fixtureDiskTtl);
      if (cached != null) {
        final data = jsonDecode(cached) as List<dynamic>;
        return data.map((e) => Fixture.fromJson(e as Map<String, dynamic>)).toList();
      }
    }

    final response = await _get(ApiConstants.fixtures);

    if (response.statusCode != 200) {
      final meta = await _storage.getCacheWithMeta('fixtures_all');
      if (meta.data != null) {
        final data = jsonDecode(meta.data!) as List<dynamic>;
        return data.map((e) => Fixture.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to load fixtures: ${response.statusCode}');
    }

    await _storage.setCache('fixtures_all', response.body);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Fixture.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Fixture>> fetchFixturesForGameweek(int gw) async {
    final cacheKey = 'fixtures_gw_$gw';
    final cached = await _storage.getCache(cacheKey, _fixtureDiskTtl);
    if (cached != null) {
      final data = jsonDecode(cached) as List<dynamic>;
      return data.map((e) => Fixture.fromJson(e as Map<String, dynamic>)).toList();
    }

    final response = await _get(ApiConstants.fixturesForGw(gw));
    if (response.statusCode != 200) {
      throw Exception('Failed to load GW$gw fixtures: ${response.statusCode}');
    }

    await _storage.setCache(cacheKey, response.body);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Fixture.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Player Summary ────────────────────────────────────────────────────────────

  Future<PlayerSummary> fetchPlayerSummary(int playerId) async {
    final cacheKey = 'player_summary_$playerId';
    final cached = await _storage.getCache(cacheKey, _playerSummaryDiskTtl);
    if (cached != null) {
      return PlayerSummary.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    }

    final response = await _get(ApiConstants.elementSummary(playerId));
    if (response.statusCode != 200) {
      throw Exception('Failed to load player summary: ${response.statusCode}');
    }

    await _storage.setCache(cacheKey, response.body);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PlayerSummary.fromJson(data);
  }

  // ── Live Gameweek ─────────────────────────────────────────────────────────────

  Future<Map<int, LiveElementStats>> fetchLiveGameweekData(int gw) async {
    // In-memory cache for live data (short TTL)
    if (_liveCache != null &&
        _liveCacheGw == gw &&
        _liveCacheTime != null &&
        DateTime.now().difference(_liveCacheTime!) < _liveTtl) {
      return _liveCache!.map((k, v) => MapEntry(k, LiveElementStats.fromJson(v)));
    }

    final response = await _get(ApiConstants.liveGw(gw));
    if (response.statusCode != 200) {
      throw Exception('Failed to load live GW data: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>;

    final raw = <int, Map<String, dynamic>>{};
    for (final element in elements) {
      final map = element as Map<String, dynamic>;
      raw[map['id'] as int] = map;
    }

    _liveCache = raw;
    _liveCacheGw = gw;
    _liveCacheTime = DateTime.now();

    return raw.map((k, v) => MapEntry(k, LiveElementStats.fromJson(v)));
  }

  // ── Dream Team ────────────────────────────────────────────────────────────────

  Future<Map<int, int>> fetchDreamTeam(int gw) async {
    final response = await _get(ApiConstants.dreamTeam(gw));
    if (response.statusCode != 200) {
      throw Exception('Failed to load dream team: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final squad = data['team'] as List<dynamic>;
    final Map<int, int> result = {};
    for (final entry in squad) {
      final map = entry as Map<String, dynamic>;
      result[map['element'] as int] = map['points'] as int? ?? 0;
    }
    return result;
  }

  // ── FPL Entry ─────────────────────────────────────────────────────────────────

  Future<FplEntry> fetchFplEntry(int entryId, {bool forceRefresh = false}) async {
    final cacheKey = 'entry_$entryId';
    if (!forceRefresh) {
      final cached = await _storage.getCache(cacheKey, _picksDiskTtl);
      if (cached != null) {
        return FplEntry.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
    }

    final response = await _get(ApiConstants.fplEntry(entryId));
    if (response.statusCode != 200) {
      final meta = await _storage.getCacheWithMeta(cacheKey);
      if (meta.data != null) {
        return FplEntry.fromJson(jsonDecode(meta.data!) as Map<String, dynamic>);
      }
      throw Exception('Failed to load FPL entry: ${response.statusCode}');
    }

    await _storage.setCache(cacheKey, response.body);
    return FplEntry.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<EntryGwPicks> fetchFplEntryPicks(
    int entryId,
    int gw, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'picks_${entryId}_$gw';
    if (!forceRefresh) {
      final cached = await _storage.getCache(cacheKey, _picksDiskTtl);
      if (cached != null) {
        return EntryGwPicks.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
    }

    final response = await _get(ApiConstants.fplEntryPicks(entryId, gw));
    if (response.statusCode != 200) {
      final meta = await _storage.getCacheWithMeta(cacheKey);
      if (meta.data != null) {
        return EntryGwPicks.fromJson(jsonDecode(meta.data!) as Map<String, dynamic>);
      }
      throw Exception('Failed to load entry picks: ${response.statusCode}');
    }

    await _storage.setCache(cacheKey, response.body);
    return EntryGwPicks.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<EntryHistory> fetchEntryHistory(
    int entryId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'history_$entryId';
    if (!forceRefresh) {
      final cached = await _storage.getCache(cacheKey, _picksDiskTtl);
      if (cached != null) {
        return EntryHistory.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
    }

    final response = await _get(ApiConstants.fplEntryHistory(entryId));
    if (response.statusCode != 200) {
      final meta = await _storage.getCacheWithMeta(cacheKey);
      if (meta.data != null) {
        return EntryHistory.fromJson(jsonDecode(meta.data!) as Map<String, dynamic>);
      }
      throw Exception('Failed to load entry history: ${response.statusCode}');
    }

    await _storage.setCache(cacheKey, response.body);
    return EntryHistory.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<EntryTransfer>> fetchEntryTransfers(int entryId) async {
    final cacheKey = 'transfers_$entryId';
    final cached = await _storage.getCache(cacheKey, _picksDiskTtl);
    if (cached != null) {
      final list = jsonDecode(cached) as List<dynamic>;
      return list.map((e) => EntryTransfer.fromJson(e as Map<String, dynamic>)).toList();
    }

    final response = await _get(ApiConstants.fplEntryTransfers(entryId));
    if (response.statusCode != 200) {
      throw Exception('Failed to load transfers: ${response.statusCode}');
    }

    await _storage.setCache(cacheKey, response.body);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => EntryTransfer.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Leagues ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchLeagueStandings(
    int leagueId, {
    int page = 1,
  }) async {
    final cacheKey = 'league_classic_${leagueId}_p$page';
    final cached = await _storage.getCache(cacheKey, _leagueDiskTtl);
    if (cached != null) {
      return jsonDecode(cached) as Map<String, dynamic>;
    }

    final response = await _get(ApiConstants.leagueStandings(leagueId, page: page));
    if (response.statusCode != 200) {
      throw Exception('Failed to load league standings: ${response.statusCode}');
    }

    await _storage.setCache(cacheKey, response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchH2HLeagueStandings(
    int leagueId, {
    int page = 1,
  }) async {
    final cacheKey = 'league_h2h_${leagueId}_p$page';
    final cached = await _storage.getCache(cacheKey, _leagueDiskTtl);
    if (cached != null) {
      return jsonDecode(cached) as Map<String, dynamic>;
    }

    final response = await _get(ApiConstants.h2hLeagueStandings(leagueId, page: page));
    if (response.statusCode != 200) {
      throw Exception('Failed to load H2H standings: ${response.statusCode}');
    }

    await _storage.setCache(cacheKey, response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void clearCache() {
    _bootstrapCache = null;
    _bootstrapCacheTime = null;
    _liveCache = null;
    _liveCacheGw = null;
    _liveCacheTime = null;
  }
}

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
