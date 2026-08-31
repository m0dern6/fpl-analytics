import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/fpl_provider.dart';
import '../services/fpl_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'fpl_pitch_screen.dart';
import 'league_detail_screen.dart';

enum _TeamTab { overview, leagues, chips, history }

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

  _TeamTab _currentTab = _TeamTab.overview;
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          'Change FPL Team ID',
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
                'Enter your team ID from your team URL:\nfantasy.premierleague.com/entry/{id}/...',
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 12,
                ),
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
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a team ID';
                  }
                  return null;
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
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: const Text('My FPL Team'),
            backgroundColor: AppColors.of(context).secondary,
            actions: [
              if (_hasTeamLoaded && _hiddenLeagues.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.visibility_rounded),
                  onPressed: _unhideLeagues,
                  tooltip: 'Restore hidden leagues',
                ),
              if (_hasTeamLoaded)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: _showEditDialog,
                  tooltip: 'Change Team ID',
                ),
              if (_hasTeamLoaded)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    final gw = provider.currentGameweek?.id ?? 1;
                    provider.loadLiveGwData(gw);
                    _fetchTeam(autoLoad: true);
                  },
                  tooltip: 'Refresh Team & Points',
                ),
            ],
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(FplProvider provider) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.of(context).primary),
            const SizedBox(height: 16),
            Text(
              'Fetching team & live points...',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
    if (!_hasTeamLoaded || _entry == null) return _buildInitialForm();
    return _buildTeamView(provider);
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
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_soccer_rounded,
                  color: AppColors.of(context).primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Load your FPL Team',
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Enter your Entry ID to track live points & leagues',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                    foregroundColor: const Color(0xFF0C0720),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _loading ? null : () => _fetchTeam(),
                  child: const Text(
                    'Load',
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
          Icon(
            Icons.error_outline,
            color: AppColors.of(context).error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: AppColors.of(context).error,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main Team View ─────────────────────────────────────────────────────────

  Widget _buildTeamView(FplProvider provider) {
    final gwInfo = provider.currentGameweek;
    final e = _entry!;
    final managerName = '${e['player_first_name'] ?? ''} ${e['player_last_name'] ?? ''}'.trim();
    final teamName = e['name'] as String? ?? 'My Team';
    final overallRank = e['summary_overall_rank'] as int?;
    final overallPoints = e['summary_overall_points'] as int? ?? 0;

    final rawPicks = (_picks?['picks'] as List?)
            ?.map((p) => p as Map<String, dynamic>)
            .toList() ??
        [];
    final activeChip = _picks?['active_chip'] as String?;

    // Real-time synchronized live points
    final liveGwPoints = provider.calculateLiveTeamPoints(
      rawPicks,
      gw: _gwNumber,
      activeChip: activeChip,
    );

    return RefreshIndicator(
      onRefresh: () => _fetchTeam(autoLoad: true),
      color: AppColors.of(context).primary,
      backgroundColor: AppColors.of(context).cardDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manager Profile Card
            _buildManagerHeaderCard(managerName, teamName, overallRank, overallPoints, e),
            const SizedBox(height: 14),

            // Live Gameweek Score & Pitch Entrance Card
            _buildLiveScoreCard(provider, gwInfo, liveGwPoints, rawPicks, activeChip),
            const SizedBox(height: 16),

            // Segmented Navigation Bar
            _buildSegmentedNav(),
            const SizedBox(height: 16),

            // Tab Content
            if (_currentTab == _TeamTab.overview)
              _buildOverviewTab(e, rawPicks, provider)
            else if (_currentTab == _TeamTab.leagues)
              _buildLeaguesTab()
            else if (_currentTab == _TeamTab.chips)
              _buildChipsTab()
            else if (_currentTab == _TeamTab.history)
              _buildHistoryTab(e),
          ],
        ),
      ),
    );
  }

  // ── Manager Header ─────────────────────────────────────────────────────────

  Widget _buildManagerHeaderCard(
    String managerName,
    String teamName,
    int? overallRank,
    int overallPoints,
    Map<String, dynamic> entry,
  ) {
    final value = (entry['last_deadline_value'] as int? ?? 1000) / 10.0;
    final bank = (entry['last_deadline_bank'] as int? ?? 0) / 10.0;
    final totalTransfers = entry['last_deadline_total_transfers'] as int? ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF160D36),
                  AppColors.of(context).cardDark,
                ]
              : [
                  AppColors.of(context).accent.withAlpha(18),
                  AppColors.of(context).cardDark,
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.of(context).accent.withAlpha(isDark ? 70 : 100),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      managerName,
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Overall Points Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.of(context).primary.withAlpha(80),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      formatNumber(overallPoints),
                      style: TextStyle(
                        color: AppColors.of(context).primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'TOTAL PTS',
                      style: TextStyle(
                        color: AppColors.of(context).primary.withAlpha(200),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.of(context).divider, height: 1),
          const SizedBox(height: 12),
          // Rank, Value, Bank Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _headerStatItem(
                'Overall Rank',
                overallRank != null ? _formatRank(overallRank) : '–',
                Icons.emoji_events_outlined,
                const Color(0xFFFBBF24),
              ),
              _headerStatItem(
                'Squad Value',
                '£${value.toStringAsFixed(1)}m',
                Icons.account_balance_wallet_outlined,
                const Color(0xFF34D399),
              ),
              _headerStatItem(
                'In Bank',
                '£${bank.toStringAsFixed(1)}m',
                Icons.savings_outlined,
                const Color(0xFF60A5FA),
              ),
              _headerStatItem(
                'Transfers',
                '$totalTransfers',
                Icons.swap_horiz_rounded,
                AppColors.of(context).accent,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _headerStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ── Live Gameweek Score Card ───────────────────────────────────────────────

  Widget _buildLiveScoreCard(
    FplProvider provider,
    dynamic gwInfo,
    int liveGwPoints,
    List<Map<String, dynamic>> rawPicks,
    String? activeChip,
  ) {
    final avgScore = gwInfo?.averageEntryScore ?? 0;
    final highScore = gwInfo?.highestScore ?? 0;

    return InkWell(
      onTap: () {
        if (_picks != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FplPitchScreen(
                picks: _picks!,
                gwNumber: _gwNumber ?? 1,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.of(context).primary.withAlpha(25),
              AppColors.of(context).cardDark,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.of(context).primary.withAlpha(100),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.of(context).primary.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.of(context).primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'GW$_gwNumber LIVE HUB',
                      style: TextStyle(
                        color: AppColors.of(context).primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Pitch View',
                      style: TextStyle(
                        color: AppColors.of(context).primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.of(context).primary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Live score big pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.of(context).primary.withAlpha(120),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$liveGwPoints',
                        style: TextStyle(
                          color: AppColors.of(context).primary,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'LIVE PTS',
                        style: TextStyle(
                          color: AppColors.of(context).primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Benchmark comparison
                Expanded(
                  child: Column(
                    children: [
                      _benchmarkRow('GW Average', '$avgScore pts', liveGwPoints >= avgScore),
                      const SizedBox(height: 8),
                      _benchmarkRow('GW High', '$highScore pts', null),
                      if (activeChip != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24).withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFBBF24)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flash_on_rounded, size: 12, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 4),
                              Text(
                                'Active: ${activeChip.toUpperCase()}',
                                style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _benchmarkRow(String label, String value, bool? isAbove) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 12,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isAbove != null) ...[
              const SizedBox(width: 4),
              Icon(
                isAbove ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 13,
                color: isAbove ? AppColors.of(context).primary : AppColors.of(context).error,
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Segmented Navigation ───────────────────────────────────────────────────

  Widget _buildSegmentedNav() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _navTabItem('Overview', _TeamTab.overview, Icons.dashboard_outlined),
          _navTabItem('Leagues', _TeamTab.leagues, Icons.emoji_events_outlined),
          _navTabItem('Chips', _TeamTab.chips, Icons.style_outlined),
          _navTabItem('History', _TeamTab.history, Icons.history_rounded),
        ],
      ),
    );
  }

  Widget _navTabItem(String title, _TeamTab tab, IconData icon) {
    final isSelected = _currentTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.of(context).primary.withAlpha(30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isSelected
                  ? AppColors.of(context).primary
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? AppColors.of(context).primary
                    : AppColors.of(context).textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.of(context).primary
                      : AppColors.of(context).textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Overview ────────────────────────────────────────────────────────

  Widget _buildOverviewTab(
    Map<String, dynamic> entry,
    List<Map<String, dynamic>> rawPicks,
    FplProvider provider,
  ) {
    final benchPoints = _calculateBenchPoints(rawPicks, provider);
    final transferCost = _picks?['entry_history']?['event_transfers_cost'] as int? ?? 0;
    final transfersMade = _picks?['entry_history']?['event_transfers'] as int? ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _overviewStatCard(
                'Bench Points',
                '$benchPoints pts',
                'Unused on bench',
                Icons.chair_outlined,
                const Color(0xFF60A5FA),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _overviewStatCard(
                'GW Transfers',
                '$transfersMade made',
                transferCost > 0 ? '-$transferCost pts hit' : 'Free / No hit',
                Icons.swap_horiz_rounded,
                transferCost > 0 ? AppColors.of(context).error : AppColors.of(context).primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.gradientCard(context: context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Squad Summary',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '15 Players',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _squadPositionCountRow(rawPicks, provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _overviewStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.of(context).divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _squadPositionCountRow(List<Map<String, dynamic>> rawPicks, FplProvider provider) {
    int gks = 0, defs = 0, mids = 0, fwds = 0;
    for (final p in rawPicks) {
      final player = provider.getPlayerById(p['element'] as int? ?? 0);
      if (player?.elementType == 1) gks++;
      if (player?.elementType == 2) defs++;
      if (player?.elementType == 3) mids++;
      if (player?.elementType == 4) fwds++;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _posPill('$gks GKs', const Color(0xFF34D399)),
        _posPill('$defs DEFs', const Color(0xFF60A5FA)),
        _posPill('$mids MIDs', const Color(0xFFFBBF24)),
        _posPill('$fwds FWDs', const Color(0xFFF97316)),
      ],
    );
  }

  Widget _posPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  int _calculateBenchPoints(List<Map<String, dynamic>> rawPicks, FplProvider provider) {
    int sum = 0;
    for (final p in rawPicks) {
      final pos = p['position'] as int? ?? 1;
      if (pos > 11) {
        final elementId = p['element'] as int? ?? 0;
        final live = provider.getLiveStatsForPlayer(elementId, gw: _gwNumber);
        final pts = live?['total_points'] as int? ??
            provider.getPlayerPointsForGameweek(elementId, _gwNumber ?? 1);
        sum += pts;
      }
    }
    return sum;
  }

  // ── Tab 2: Leagues ─────────────────────────────────────────────────────────

  Widget _buildLeaguesTab() {
    final leagues = _entry?['leagues']?['classic'] as List<dynamic>?;
    final h2hLeagues = _entry?['leagues']?['h2h'] as List<dynamic>?;

    if ((leagues == null || leagues.isEmpty) && (h2hLeagues == null || h2hLeagues.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No leagues joined for this team',
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
        ),
      );
    }

    final allLeagues = [
      ...?leagues,
      ...?h2hLeagues,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Classic & Mini-Leagues',
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_hiddenLeagues.isNotEmpty)
              GestureDetector(
                onTap: _unhideLeagues,
                child: Text(
                  'Restore (${_hiddenLeagues.length})',
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...allLeagues.where((l) => !_hiddenLeagues.contains(l['id'])).map((l) {
          final id = l['id'] as int;
          final rank = l['entry_rank'] as int? ?? 0;
          final lastRank = l['entry_last_rank'] as int? ?? 0;
          final diff = lastRank > 0 ? (lastRank - rank) : 0;

          Widget rankIcon;
          Color rankColor;
          if (diff > 0) {
            rankIcon = const Icon(Icons.arrow_upward_rounded, color: Color(0xFF34D399), size: 14);
            rankColor = const Color(0xFF34D399);
          } else if (diff < 0) {
            rankIcon = const Icon(Icons.arrow_downward_rounded, color: Color(0xFFEF4444), size: 14);
            rankColor = const Color(0xFFEF4444);
          } else {
            rankIcon = Icon(Icons.remove_rounded, color: AppColors.of(context).textSecondary, size: 14);
            rankColor = AppColors.of(context).textSecondary;
          }

          return Dismissible(
            key: Key('league_$id'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.of(context).error.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.visibility_off_rounded, color: AppColors.of(context).error),
            ),
            onDismissed: (_) => _hideLeague(id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
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
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.gradientCard(context: context),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l['name'] as String? ?? 'League',
                              style: TextStyle(
                                color: AppColors.of(context).textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (lastRank > 0)
                              Text(
                                'Prev Rank: ${formatNumber(lastRank)}',
                                style: TextStyle(
                                  color: AppColors.of(context).textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
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
                                    diff != 0 ? '${diff.abs()}' : '–',
                                    style: TextStyle(
                                      color: rankColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.of(context).textSecondary,
                            size: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Tab 3: Chips ───────────────────────────────────────────────────────────

  Widget _buildChipsTab() {
    final chipsList = [
      {'name': 'Wildcard 1', 'key': 'wildcard_1', 'desc': 'Unlimited free transfers (1st half)'},
      {'name': 'Wildcard 2', 'key': 'wildcard_2', 'desc': 'Unlimited free transfers (2nd half)'},
      {'name': 'Free Hit', 'key': 'freehit', 'desc': 'Unlimited transfers for 1 gameweek'},
      {'name': 'Triple Captain', 'key': '3xc', 'desc': 'Captain points tripled'},
      {'name': 'Bench Boost', 'key': 'bboost', 'desc': 'Bench players score points'},
      {'name': 'Mystery Chip', 'key': 'mystery', 'desc': 'Special FPL chip'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FPL Chips Tracker',
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...chipsList.map((c) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.of(context).cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.of(context).divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.flash_on_rounded,
                    color: AppColors.of(context).primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['name']!,
                        style: TextStyle(
                          color: AppColors.of(context).textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        c['desc']!,
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AVAILABLE',
                    style: TextStyle(
                      color: AppColors.of(context).primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Tab 4: History ─────────────────────────────────────────────────────────

  Widget _buildHistoryTab(Map<String, dynamic> entry) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _service.fetchFplEntryHistory(entry['id'] as int),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.of(context).primary),
            ),
          );
        }

        final history = snapshot.data?['current'] as List<dynamic>? ?? [];
        if (history.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No gameweek history available yet',
                style: TextStyle(color: AppColors.of(context).textSecondary),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Season Performance History',
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.of(context).cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.of(context).divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: AppColors.of(context).cardMedium,
                    child: const Row(
                      children: [
                        SizedBox(width: 40, child: Text('GW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
                        Expanded(child: Text('Points', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
                        Expanded(child: Text('Rank', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
                        SizedBox(width: 45, child: Text('Bench', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
                      ],
                    ),
                  ),
                  // History Rows
                  ...history.reversed.map((h) {
                    final gw = h['event'];
                    final pts = h['points'];
                    final rank = h['overall_rank'];
                    final bench = h['points_on_bench'];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.of(context).divider, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              'GW$gw',
                              style: TextStyle(
                                color: AppColors.of(context).primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '$pts pts',
                              style: TextStyle(
                                color: AppColors.of(context).textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rank != null ? formatNumber(rank) : '–',
                              style: TextStyle(
                                color: AppColors.of(context).textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 45,
                            child: Text(
                              '$bench pts',
                              style: TextStyle(
                                color: AppColors.of(context).textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatRank(int rank) {
    if (rank >= 1000000) {
      return '${(rank / 1000000).toStringAsFixed(2)}M';
    }
    if (rank >= 1000) {
      return '${(rank / 1000).toStringAsFixed(1)}k';
    }
    return '$rank';
  }
}
