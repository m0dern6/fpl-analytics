import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_team.dart';
import '../services/local_storage_service.dart';

class UserTeamsProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final _uuid = const Uuid();

  List<UserTeam> _teams = [];
  bool _isLoading = false;

  List<UserTeam> get teams => _teams;
  bool get isLoading => _isLoading;
  bool get hasTeams => _teams.isNotEmpty;

  Future<void> loadTeams() async {
    _isLoading = true;
    notifyListeners();
    try {
      _teams = await _storage.getTeams();
    } catch (_) {
      _teams = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserTeam> addTeam(UserTeam team) async {
    final newTeam = team.copyWith(id: _uuid.v4());
    await _storage.saveTeam(newTeam);
    _teams = [..._teams, newTeam];
    notifyListeners();
    return newTeam;
  }

  Future<void> updateTeam(UserTeam team) async {
    await _storage.updateTeam(team);
    final idx = _teams.indexWhere((t) => t.id == team.id);
    if (idx >= 0) {
      _teams = List.from(_teams)..[idx] = team;
    } else {
      _teams = [..._teams, team];
    }
    notifyListeners();
  }

  Future<void> deleteTeam(String teamId) async {
    await _storage.deleteTeam(teamId);
    _teams = _teams.where((t) => t.id != teamId).toList();
    notifyListeners();
  }

  String generateId() => _uuid.v4();
}
