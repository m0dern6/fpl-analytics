import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_team.dart';

/// Disk-based cache entry with TTL metadata.
class _CacheEntry {
  final String data;
  final DateTime cachedAt;

  _CacheEntry({required this.data, required this.cachedAt});

  factory _CacheEntry.fromJson(Map<String, dynamic> json) => _CacheEntry(
        data: json['data'] as String,
        cachedAt: DateTime.parse(json['cachedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'data': data,
        'cachedAt': cachedAt.toIso8601String(),
      };
}

class LocalStorageService {
  static const String _teamsKey = 'user_teams_v1';
  static const String _cachePrefix = 'cache_v1_';
  static const String _entryIdKey = 'fpl_entry_id';
  static const String _savedProfilesKey = 'fpl_saved_profiles_v1';
  static const String _watchlistKey = 'fpl_watchlist_v1';
  static const String _streamerModeKey = 'fpl_streamer_mode';
  static const String _playerSnapshotsKey = 'fpl_player_snapshots_v1';
  static const String _recentPlayersKey = 'fpl_recent_players_v1';

  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  Future<List<UserTeam>> getTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_teamsKey) ?? [];
    return raw
        .map((s) {
          try {
            return UserTeam.fromJsonString(s);
          } catch (e, st) {
            debugPrint('LocalStorageService: failed to parse team: $e\n$st');
            return null;
          }
        })
        .whereType<UserTeam>()
        .toList();
  }

  Future<void> saveTeam(UserTeam team) async {
    final prefs = await SharedPreferences.getInstance();
    final teams = await getTeams();
    final idx = teams.indexWhere((t) => t.id == team.id);
    if (idx >= 0) {
      teams[idx] = team;
    } else {
      teams.add(team);
    }
    await prefs.setStringList(
        _teamsKey, teams.map((t) => t.toJsonString()).toList());
  }

  Future<void> deleteTeam(String teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final teams = await getTeams();
    teams.removeWhere((t) => t.id == teamId);
    await prefs.setStringList(
        _teamsKey, teams.map((t) => t.toJsonString()).toList());
  }

  Future<void> updateTeam(UserTeam team) => saveTeam(team);

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_teamsKey);
  }

  // ── Generic TTL Cache ────────────────────────────────────────────────────────

  String _cacheKey(String key) => '$_cachePrefix$key';

  /// Stores [data] under [key] with a timestamp.
  Future<void> setCache(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = _CacheEntry(data: data, cachedAt: DateTime.now());
    await prefs.setString(_cacheKey(key), jsonEncode(entry.toJson()));
  }

  /// Returns cached data if it exists and is within [ttl]; otherwise null.
  Future<String?> getCache(String key, Duration ttl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(key));
      if (raw == null) return null;
      final entry = _CacheEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (DateTime.now().difference(entry.cachedAt) > ttl) return null;
      return entry.data;
    } catch (_) {
      return null;
    }
  }

  /// Returns cached data regardless of TTL (for offline fallback).
  Future<({String? data, DateTime? cachedAt})> getCacheWithMeta(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(key));
      if (raw == null) return (data: null, cachedAt: null);
      final entry = _CacheEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return (data: entry.data, cachedAt: entry.cachedAt);
    } catch (_) {
      return (data: null, cachedAt: null);
    }
  }

  Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(key));
  }

  // ── Entry ID ──────────────────────────────────────────────────────────────────

  Future<int?> getEntryId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_entryIdKey);
  }

  Future<void> saveEntryId(int entryId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_entryIdKey, entryId);
  }

  Future<void> clearEntryId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entryIdKey);
  }

  // ── Saved Profiles ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSavedProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_savedProfilesKey) ?? [];
      return raw
          .map((s) {
            try {
              return jsonDecode(s) as Map<String, dynamic>;
            } catch (_) {
              return null;
            }
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getSavedProfiles();
    final entryId = profile['entryId'] as int;
    final idx = profiles.indexWhere((p) => p['entryId'] == entryId);
    if (idx >= 0) {
      profiles[idx] = profile;
    } else {
      profiles.add(profile);
    }
    await prefs.setStringList(
        _savedProfilesKey, profiles.map(jsonEncode).toList());
  }

  Future<void> deleteProfile(int entryId) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getSavedProfiles();
    profiles.removeWhere((p) => p['entryId'] == entryId);
    await prefs.setStringList(
        _savedProfilesKey, profiles.map(jsonEncode).toList());
  }

  // ── Watchlist ─────────────────────────────────────────────────────────────────

  Future<List<int>> getWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_watchlistKey) ?? [];
    return raw.map((s) => int.tryParse(s) ?? -1).where((i) => i > 0).toList();
  }

  Future<void> toggleWatchlist(int playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getWatchlist();
    if (list.contains(playerId)) {
      list.remove(playerId);
    } else {
      list.add(playerId);
    }
    await prefs.setStringList(
        _watchlistKey, list.map((i) => i.toString()).toList());
  }

  Future<bool> isInWatchlist(int playerId) async {
    final list = await getWatchlist();
    return list.contains(playerId);
  }

  // ── Streamer Mode ─────────────────────────────────────────────────────────────

  Future<bool> getStreamerMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_streamerModeKey) ?? false;
  }

  Future<void> setStreamerMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_streamerModeKey, enabled);
  }

  // ── Recently Viewed Players ───────────────────────────────────────────────────

  Future<List<int>> getRecentlyViewedPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_recentPlayersKey) ?? [];
    return raw.map((s) => int.tryParse(s) ?? -1).where((i) => i > 0).toList();
  }

  Future<void> addRecentlyViewedPlayer(int playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getRecentlyViewedPlayers();
    list.remove(playerId); // ensure no duplicates
    list.insert(0, playerId);
    final trimmed = list.take(20).toList(); // keep last 20
    await prefs.setStringList(
        _recentPlayersKey, trimmed.map((i) => i.toString()).toList());
  }

  // ── Player Price Snapshots ────────────────────────────────────────────────────

  /// Stores today's price snapshot as {playerId: price}.
  Future<void> savePriceSnapshot(Map<int, int> prices) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = '${_playerSnapshotsKey}_$today';
    await prefs.setString(key, jsonEncode(prices.map(
      (k, v) => MapEntry(k.toString(), v),
    )));
  }

  /// Returns price snapshot for a given date string (YYYY-MM-DD), or null.
  Future<Map<int, int>?> getPriceSnapshot(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_playerSnapshotsKey}_$date';
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  /// Returns yesterday's price snapshot.
  Future<Map<int, int>?> getYesterdayPriceSnapshot() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1))
        .toIso8601String().substring(0, 10);
    return getPriceSnapshot(yesterday);
  }
}
