import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/fpl_provider.dart';
import '../services/fpl_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'fpl_pitch_screen.dart';
import 'league_detail_screen.dart';

class FplTeamScreen extends StatefulWidget {
  const FplTeamScreen({super.key});

  @override
  State<FplTeamScreen> createState() => _FplTeamScreenState();
}

class _FplTeamScreenState extends State<FplTeamScreen> {
  static const String _prefKey = 'fpl_entry_team_id';

  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _service = FplService();

  bool _loading = false;
  String? _error;
  bool _hasTeamLoaded = false;
  List<int> _hiddenLeagues = [];

  Map<String, dynamic>? _entry;
  Map<String, dynamic>? _picks;
  int? _gwNumber;

  @override
  void initState() {
    super.initState();
    _loadSavedIdAndFetch();
  }

  Future<void> _loadSavedIdAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final hidden = prefs.getStringList('hidden_leagues') ?? [];
    _hiddenLeagues = hidden.map(int.parse).toList();

    final saved = prefs.getString(_prefKey);
    if (saved != null && saved.isNotEmpty) {
      _controller.text = saved;
      await _fetchTeam(autoLoad: true);
    }
  }

  Future<void> _hideLeague(int id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hiddenLeagues.add(id);
    });
    await prefs.setStringList(
      'hidden_leagues',
      _hiddenLeagues.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _unhideLeagues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hidden_leagues');
    setState(() {
      _hiddenLeagues = [];
    });
  }

  Future<void> _saveId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, id);
  }

  Future<void> _fetchTeam({bool autoLoad = false}) async {
    if (!autoLoad && !_formKey.currentState!.validate()) return;
    final id = int.tryParse(_controller.text.trim());
    if (id == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _entry = null;
      _picks = null;
      _hasTeamLoaded = false;
    });

    try {
      await _saveId(_controller.text.trim());
      if (!mounted) return;
      final fplProvider = context.read<FplProvider>();
      final gw = fplProvider.currentGameweek?.id ?? 1;

      final results = await Future.wait([
        _service.fetchFplEntry(id),
        _service.fetchFplEntryPicks(id, gw),
      ]);

      if (mounted) {
        await fplProvider.loadLiveGwData(gw);
      }

      if (!mounted) return;
      setState(() {
        _entry = results[0];
        _picks = results[1];
        _gwNumber = gw;
        _loading = false;
        _hasTeamLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasTeamLoaded = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showEditDialog() {
    final editController = TextEditingController(text: _controller.text);
    final editKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Change Team ID',
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Form(
          key: editKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your team ID from:\nfantasy.premierleague.com/entry/{id}/...',
                style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: editController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. 1234567',
                  prefixIcon: Icon(
                    Icons.tag_rounded,
                    color: AppColors.of(context).textSecondary,
                    size: 18,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Please enter a team ID';
                  return null;
                },
                onChanged: (val) {
                  // Replaced auto load with a manual confirmation to avoid unintentional reloads while typing.
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.of(context).textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (editKey.currentState!.validate()) {
                Navigator.pop(ctx);
                _controller.text = editController.text;
                await _saveId(editController.text);
                await _fetchTeam(autoLoad: true);
              }
            },
            child: Text(
              'Load Team',
              style: TextStyle(
                color: AppColors.of(context).primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: const Text('My FPL Team'),
        backgroundColor: AppColors.of(context).secondary,
        actions: [
          if (_hasTeamLoaded && _hiddenLeagues.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.visibility_rounded,
                color: AppColors.of(context).textSecondary,
              ),
              onPressed: _unhideLeagues,
              tooltip: 'Restore hidden leagues',
            ),
          if (_hasTeamLoaded)
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                color: AppColors.of(context).textSecondary,
              ),
              onPressed: _showEditDialog,
            ),
          if (_hasTeamLoaded)
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: AppColors.of(context).textSecondary,
              ),
              onPressed: () => _fetchTeam(autoLoad: true),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading)
      return Center(
        child: CircularProgressIndicator(color: AppColors.of(context).primary),
      );
    if (!_hasTeamLoaded) return _buildInitialForm();
    return _buildTeamView();
  }

  Widget _buildInitialForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildFormCard(),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.gradientCard(context: context, ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.manage_accounts_rounded,
                  color: AppColors.of(context).primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Look up your FPL team',
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(color: AppColors.of(context).textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. 1234567',
                      prefixIcon: Icon(
                        Icons.tag_rounded,
                        color: AppColors.of(context).textSecondary,
                        size: 18,
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a team ID'
                        : null,
                    onFieldSubmitted: (_) => _fetchTeam(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.of(context).primary,
                    foregroundColor: AppColors.of(context).secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _loading ? null : () => _fetchTeam(),
                  child: const Text(
                    'Go',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).error.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.of(context).error.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.of(context).error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: AppColors.of(context).error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamView() {
    final fplProvider = context.read<FplProvider>();
    final gwInfo = fplProvider.currentGameweek;

    return RefreshIndicator(
      onRefresh: () => _fetchTeam(autoLoad: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (gwInfo != null) _buildGameweekBox(gwInfo),
            const SizedBox(height: 16),
            _buildSummaryCard(),
            const SizedBox(height: 20),
            _buildLeaguesCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGameweekBox(dynamic gw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.purpleGradient(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gw.name.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Deadline: ${formatDateTime(gw.deadlineTime)}',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.of(context).primary.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.of(context).primary.withAlpha(100)),
            ),
            child: Text(
              gw.finished ? 'Finished' : (gw.isCurrent ? 'Live' : 'Upcoming'),
              style: TextStyle(
                color: AppColors.of(context).primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final e = _entry!;
    final fplProvider = context.read<FplProvider>();
    final gwInfo = fplProvider.currentGameweek;
    final teamName = e['name'] as String? ?? '';
    final staticEventPoints = e['summary_event_points'] as int? ?? 0;
    final staticOverallPoints = e['summary_overall_points'] as int? ?? 0;
    final overallRank = e['summary_overall_rank'] as int?;
    final liveEventPoints = _calculateLivePoints(fplProvider);
    final overallPoints =
        staticOverallPoints - staticEventPoints + liveEventPoints;
    final avgScore = gwInfo?.averageEntryScore ?? 0;
    final highScore = gwInfo?.highestScore ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FplPitchScreen(picks: _picks!, gwNumber: _gwNumber ?? 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppTheme.gradientCard(context: context, ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  teamName.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.of(context).textSecondary,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _summaryMiniStat(
                        'TOTAL',
                        '$overallPoints',
                        AppColors.of(context).primary,
                      ),
                      const SizedBox(height: 10),
                      _summaryMiniStat(
                        'RANK',
                        overallRank != null ? _formatRank(overallRank) : '–',
                        AppColors.of(context).accent,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF34D399).withAlpha(80),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$liveEventPoints',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'GW$_gwNumber PTS',
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (_picks?['active_chip'] != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatChipName(_picks!['active_chip'] as String),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _summaryMiniStat(
                        'AVG',
                        '$avgScore',
                        AppColors.of(context).textPrimary,
                      ),
                      const SizedBox(height: 10),
                      _summaryMiniStat(
                        'HIGH',
                        '$highScore',
                        AppColors.of(context).textPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Click to view pitch',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguesCard() {
    final leagues = _entry?['leagues']?['classic'] as List<dynamic>?;
    if (leagues == null || leagues.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppTheme.sectionTitle(context, 'Leagues'),
            if (_hiddenLeagues.isNotEmpty)
              TextButton(
                onPressed: _unhideLeagues,
                child: Text(
                  'Unhide all',
                  style: TextStyle(color: AppColors.of(context).primary, fontSize: 11),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...leagues.where((l) => !_hiddenLeagues.contains(l['id'])).map((l) {
          final id = l['id'] as int;
          final rank = l['entry_rank'] as int? ?? 0;
          final lastRank = l['entry_last_rank'] as int? ?? 0;
          final diff = lastRank - rank;
          Widget rankIcon;
          Color rankColor;
          if (diff > 0) {
            rankIcon = const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.green,
              size: 14,
            );
            rankColor = Colors.green;
          } else if (diff < 0) {
            rankIcon = const Icon(
              Icons.arrow_downward_rounded,
              color: Colors.red,
              size: 14,
            );
            rankColor = Colors.red;
          } else {
            rankIcon = Icon(
              Icons.remove_rounded,
              color: AppColors.of(context).textSecondary,
              size: 14,
            );
            rankColor = AppColors.of(context).textSecondary;
          }

          return Dismissible(
            key: Key('league_$id'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.of(context).error.withAlpha(40),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.visibility_off_rounded,
                color: AppColors.of(context).error,
              ),
            ),
            onDismissed: (_) => _hideLeague(id),
            child: GestureDetector(
              onTap: () {
                final myEntryId = int.tryParse(_controller.text.trim());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LeagueDetailScreen(
                      leagueId: id,
                      leagueName: l['name'] as String? ?? 'League',
                      userEntryId: myEntryId,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.gradientCard(context: context, ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l['name'] as String? ?? 'League',
                        style: TextStyle(
                          color: AppColors.of(context).textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatNumber(rank),
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            rankIcon,
                            const SizedBox(width: 2),
                            Text(
                              diff == 0 ? 'No change' : '${diff.abs()}',
                              style: TextStyle(
                                color: rankColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _summaryMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  String _formatRank(int rank) {
    if (rank >= 1000000) return '${(rank / 1000000).toStringAsFixed(1)}M';
    if (rank >= 1000) return '${(rank / 1000).toStringAsFixed(0)}k';
    return rank.toString();
  }

  int _calculateLivePoints(FplProvider provider) {
    if (_picks == null || _picks!['picks'] == null) return 0;
    final picksList = _picks!['picks'] as List<dynamic>;
    final activeChip = _picks!['active_chip'] as String?;
    int total = 0;
    for (final pick in picksList) {
      final isBench = (pick['position'] as int) > 11;
      if (!isBench || activeChip == 'bboost') {
        final playerId = pick['element'] as int;
        final live = provider.getLiveStatsForPlayer(playerId);
        final rawPts = live?['total_points'] as int? ?? 0;
        final multiplier = pick['multiplier'] as int? ?? 1;
        total += (rawPts * multiplier);
      }
    }
    return total;
  }

  String _formatChipName(String chip) {
    switch (chip) {
      case 'bboost':
        return 'BENCH BOOST';
      case '3xc':
        return 'TRIPLE CAPTAIN';
      case 'freehit':
        return 'FREE HIT';
      case 'wildcard':
        return 'WILDCARD';
      default:
        return chip.toUpperCase();
    }
  }
}
