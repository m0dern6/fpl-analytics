import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_team.dart';

class LocalStorageService {
  static const String _teamsKey = 'user_teams_v1';

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
          } catch (_) {
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
}
