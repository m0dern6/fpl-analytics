import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../services/fpl_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

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
    final saved = prefs.getString(_prefKey);
    if (saved != null && saved.isNotEmpty) {
      _controller.text = saved;
      await _fetchTeam(autoLoad: true);
    }
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
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Change Team ID',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Form(
          key: editKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your team ID from:\nfantasy.premierleague.com/entry/{id}/...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: editController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. 1234567',
                  prefixIcon: Icon(
                    Icons.tag_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Please enter a team ID';
                  if (int.tryParse(v.trim()) == null)
                    return 'Team ID must be a number';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (editKey.currentState!.validate()) {
                Navigator.pop(ctx);
                _controller.text = editController.text;
                await _fetchTeam();
              }
            },
            child: const Text(
              'Load Team',
              style: TextStyle(
                color: AppColors.primary,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My FPL Team'),
        backgroundColor: AppColors.secondary,
        actions: [
          if (_hasTeamLoaded)
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Change team',
              onPressed: _showEditDialog,
            ),
          if (_hasTeamLoaded)
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Refresh',
              onPressed: () => _fetchTeam(autoLoad: true),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (!_hasTeamLoaded) {
      return _buildInitialForm();
    }
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
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.manage_accounts_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Look up your FPL team',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the team ID from your FPL URL:\nfantasy.premierleague.com/entry/{id}/...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1234567',
                      prefixIcon: Icon(
                        Icons.tag_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Please enter a team ID';
                      if (int.tryParse(v.trim()) == null)
                        return 'Team ID must be a number';
                      return null;
                    },
                    onFieldSubmitted: (_) => _fetchTeam(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _loading ? null : _fetchTeam,
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
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 20),
          _buildPitchView(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Unified My FPL Team Summary Card ──────────────────────────────────────
  Widget _buildSummaryCard() {
    final e = _entry!;
    final fplProvider = context.read<FplProvider>();
    final gwInfo = fplProvider.currentGameweek;

    final teamName = e['name'] as String? ?? '';
    final overallPoints = e['summary_overall_points'] as int? ?? 0;
    final overallRank = e['summary_overall_rank'] as int?;
    final eventPoints = e['summary_event_points'] as int? ?? 0;

    final avgScore = gwInfo?.averageEntryScore ?? 0;
    final highScore = gwInfo?.highestScore ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: [
          Text(
            teamName.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
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
                      AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _summaryMiniStat(
                      'RANK',
                      overallRank != null ? _formatRank(overallRank) : '–',
                      AppColors.accent,
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
                      '$eventPoints',
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
                    _summaryMiniStat('AVG', '$avgScore', AppColors.textPrimary),
                    const SizedBox(height: 10),
                    _summaryMiniStat(
                      'HIGH',
                      '$highScore',
                      AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Pitch view ────────────────────────────────────────────────────────────
  Widget _buildPitchView() {
    final picksRaw = _picks?['picks'] as List<dynamic>?;
    if (picksRaw == null || picksRaw.isEmpty) return const SizedBox.shrink();

    final fplProvider = context.read<FplProvider>();

    final starting =
        picksRaw
            .where((p) => (p as Map<String, dynamic>)['position'] as int <= 11)
            .map((p) => p as Map<String, dynamic>)
            .toList()
          ..sort(
            (a, b) => (a['position'] as int).compareTo(b['position'] as int),
          );

    final bench =
        picksRaw
            .where((p) => (p as Map<String, dynamic>)['position'] as int > 11)
            .map((p) => p as Map<String, dynamic>)
            .toList()
          ..sort(
            (a, b) => (a['position'] as int).compareTo(b['position'] as int),
          );

    final gkPicks = starting.where((p) {
      final player = fplProvider.getPlayerById(p['element'] as int);
      return player?.elementType == 1;
    }).toList();
    final defPicks = starting.where((p) {
      final player = fplProvider.getPlayerById(p['element'] as int);
      return player?.elementType == 2;
    }).toList();
    final midPicks = starting.where((p) {
      final player = fplProvider.getPlayerById(p['element'] as int);
      return player?.elementType == 3;
    }).toList();
    final fwdPicks = starting.where((p) {
      final player = fplProvider.getPlayerById(p['element'] as int);
      return player?.elementType == 4;
    }).toList();
    final activeChip = _picks?['active_chip'] as String?;

    // Perspective tilt for 3D effect
    final pitchContent = Stack(
      children: [
        // Pitch background painting
        Positioned.fill(child: CustomPaint(painter: _FplPitchPainter())),
        // Player rows
        Column(
          children: [
            const SizedBox(height: 20), // space for top goal
            _buildPitchRow(gkPicks, fplProvider, isStarting: true),
            const SizedBox(height: 6),
            _buildPitchRow(defPicks, fplProvider, isStarting: true),
            const SizedBox(height: 6),
            _buildPitchRow(midPicks, fplProvider, isStarting: true),
            const SizedBox(height: 6),
            _buildPitchRow(fwdPicks, fplProvider, isStarting: true),
            const SizedBox(height: 10),
            _buildBenchDivider(activeChip == 'bboost'),
            const SizedBox(height: 8),
            _buildPitchRow(bench, fplProvider, isStarting: false),
            const SizedBox(height: 20), // space for bottom goal
          ],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTheme.sectionTitle(context, 'Pitch View'),
        const SizedBox(
          height: 32,
        ), // Increased spacing so title isn't hidden by 3D tilt
        // Perspective 3D tilt
        Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0006)
            ..rotateX(0.12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: pitchContent,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPitchRow(
    List<Map<String, dynamic>> picks,
    FplProvider provider, {
    required bool isStarting,
  }) {
    if (picks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: picks.map((pick) {
          final playerId = pick['element'] as int;
          final player = provider.getPlayerById(playerId);
          final posLabel = player != null
              ? getPositionShort(player.elementType)
              : '';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isStarting && posLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    posLabel,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              _PitchPlayerCard(
                pick: pick,
                provider: provider,
                isStarting: isStarting,
                gwId: _gwNumber ?? 1,
                activeChip: _picks?['active_chip'] as String?,
                onTap: () => _showPlayerPointsSheet(context, pick, provider),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBenchDivider(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF34D399).withAlpha(40)
            : Colors.black.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? const Color(0xFF34D399).withAlpha(120)
              : Colors.white.withAlpha(25),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF34D399).withAlpha(40),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? Icons.bolt_rounded : Icons.chair_rounded,
            color: isActive ? const Color(0xFF34D399) : Colors.white38,
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'BENCH BOOST ACTIVE' : 'SUBSTITUTES',
            style: TextStyle(
              color: isActive ? const Color(0xFF34D399) : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: isActive ? 1 : 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Player points breakdown sheet ─────────────────────────────────────────
  void _showPlayerPointsSheet(
    BuildContext context,
    Map<String, dynamic> pick,
    FplProvider provider,
  ) {
    final playerId = pick['element'] as int;
    final isCaptain = pick['is_captain'] as bool? ?? false;
    final isViceCaptain = pick['is_vice_captain'] as bool? ?? false;
    final multiplier = pick['multiplier'] as int? ?? 1;
    final isBench = (pick['position'] as int) > 11;

    final player = provider.getPlayerById(playerId);
    final live = provider.getLiveStatsForPlayer(playerId);
    final rawPts = live?['total_points'] as int? ?? 0;
    final effectivePts = isBench ? rawPts : rawPts * multiplier;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlayerPointsSheet(
        player: player,
        live: live,
        effectivePts: effectivePts,
        isCaptain: isCaptain,
        isViceCaptain: isViceCaptain,
        multiplier: multiplier,
        isBench: isBench,
        provider: provider,
      ),
    );
  }

  String _formatRank(int rank) {
    if (rank >= 1000000) return '${(rank / 1000000).toStringAsFixed(1)}M';
    if (rank >= 1000) return '${(rank / 1000).toStringAsFixed(0)}k';
    return rank.toString();
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

// ─── Pitch Painter ─────────────────────────────────────────────────────────────

class _FplPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Alternating stripe background ──────────────────────────────────
    const stripe1 = Color(0xFF2FA84E); // lighter green
    const stripe2 = Color(0xFF35B857); // slightly brighter stripe
    final nStripes = 10;
    final stripeH = h / nStripes;
    for (int i = 0; i < nStripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH, w, stripeH),
        Paint()..color = i.isEven ? stripe1 : stripe2,
      );
    }

    // ── 2. Line paint ──────────────────────────────────────────────────────
    final lp = Paint()
      ..color = Colors.white.withAlpha(210)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final spotPaint = Paint()
      ..color = Colors.white.withAlpha(210)
      ..style = PaintingStyle.fill;

    const border = 10.0;
    final innerW = w - 2 * border;
    final innerH = h - 2 * border;

    // Helper to map 0-1 coords into pitch interior
    double px(double nx) => border + nx * innerW;
    double py(double ny) => border + ny * innerH;

    // ── 3. Outer boundary ─────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(border, border, innerW, innerH), lp);

    // ── 4. Center line ────────────────────────────────────────────────────
    canvas.drawLine(
      Offset(border, py(0.5)),
      Offset(border + innerW, py(0.5)),
      lp,
    );

    // ── 5. Center circle + spot ───────────────────────────────────────────
    final ccRadius = innerW * 0.14;
    canvas.drawCircle(Offset(px(0.5), py(0.5)), ccRadius, lp);
    canvas.drawCircle(Offset(px(0.5), py(0.5)), 3.0, spotPaint);

    // ── 6. TOP half markings ───────────────────────────────────────────────
    // Penalty area top (40.32m × 16.5m → ~60% × ~16% of pitch)
    final tPAW = innerW * 0.60;
    final tPAH = innerH * 0.175;
    canvas.drawRect(Rect.fromLTWH(px(0.5) - tPAW / 2, border, tPAW, tPAH), lp);

    // Goal area top (18.32m × 5.5m → ~28% × ~6%)
    final tGAW = innerW * 0.30;
    final tGAH = innerH * 0.065;
    canvas.drawRect(Rect.fromLTWH(px(0.5) - tGAW / 2, border, tGAW, tGAH), lp);

    // Top goal post — U-shaped frame (two posts + crossbar), no fill
    final goalW = innerW * 0.13;
    const goalDepth = 12.0;
    final goalLp = Paint()
      ..color = Colors.white.withAlpha(230)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final tGoalLeft = px(0.5) - goalW / 2;
    final tGoalRight = px(0.5) + goalW / 2;
    final tGoalCrossbar = border;
    final tGoalTop = border - goalDepth;
    // Left post
    canvas.drawLine(
      Offset(tGoalLeft, tGoalCrossbar),
      Offset(tGoalLeft, tGoalTop),
      goalLp,
    );
    // Right post
    canvas.drawLine(
      Offset(tGoalRight, tGoalCrossbar),
      Offset(tGoalRight, tGoalTop),
      goalLp,
    );
    // Crossbar (top)
    canvas.drawLine(
      Offset(tGoalLeft, tGoalTop),
      Offset(tGoalRight, tGoalTop),
      goalLp,
    );

    // Top penalty spot (11m / 105m ≈ 10.5% from top)
    const tSpotNy = 0.115;
    canvas.drawCircle(Offset(px(0.5), py(tSpotNy)), 2.5, spotPaint);

    // Top penalty arc (D) — protrudes below the PA line
    // Spot at (cx, cy), arc radius = center circle radius
    // Only draw the part below the PA bottom line
    final tArcCenter = Offset(px(0.5), py(tSpotNy));
    final arcR = ccRadius;
    final tPABottom = border + tPAH; // y of PA bottom
    // Intersection angle: sin(θ) = (tPABottom - tArcCenter.dy) / arcR
    final tSinTheta = (tPABottom - tArcCenter.dy).clamp(-arcR, arcR) / arcR;
    final tTheta = math.asin(tSinTheta.toDouble());
    // Draw arc from (π/2 - tTheta ... π/2 + tTheta) — the part below PA line
    if (tTheta < math.pi / 2) {
      final arcStartAngle = math.pi / 2 - tTheta - 0.02;
      final arcSweep = math.pi - (math.pi / 2 - tTheta) * 2 + 0.04;
      if (arcSweep > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: tArcCenter, radius: arcR),
          arcStartAngle,
          arcSweep,
          false,
          lp,
        );
      }
    }

    // ── 7. BOTTOM half markings (mirror of top) ────────────────────────────
    // Penalty area bottom
    canvas.drawRect(
      Rect.fromLTWH(px(0.5) - tPAW / 2, border + innerH - tPAH, tPAW, tPAH),
      lp,
    );

    // Goal area bottom
    canvas.drawRect(
      Rect.fromLTWH(px(0.5) - tGAW / 2, border + innerH - tGAH, tGAW, tGAH),
      lp,
    );

    // Bottom goal post — U-shaped frame, no fill
    final bGoalLeft = px(0.5) - goalW / 2;
    final bGoalRight = px(0.5) + goalW / 2;
    final bGoalCrossbar = border + innerH;
    final bGoalBottom = border + innerH + goalDepth;
    // Left post
    canvas.drawLine(
      Offset(bGoalLeft, bGoalCrossbar),
      Offset(bGoalLeft, bGoalBottom),
      goalLp,
    );
    // Right post
    canvas.drawLine(
      Offset(bGoalRight, bGoalCrossbar),
      Offset(bGoalRight, bGoalBottom),
      goalLp,
    );
    // Crossbar (top of goal frame)
    canvas.drawLine(
      Offset(bGoalLeft, bGoalBottom),
      Offset(bGoalRight, bGoalBottom),
      goalLp,
    );

    // Bottom penalty spot
    const bSpotNy = 1.0 - tSpotNy;
    canvas.drawCircle(Offset(px(0.5), py(bSpotNy)), 2.5, spotPaint);

    // Bottom penalty D (mirror: above the PA top line)
    final bArcCenter = Offset(px(0.5), py(bSpotNy));
    final bPATop = border + innerH - tPAH; // y of bottom PA top
    final bSinTheta = (bArcCenter.dy - bPATop).clamp(-arcR, arcR) / arcR;
    final bTheta = math.asin(bSinTheta.toDouble());
    if (bTheta < math.pi / 2) {
      final arcStartAngle = -math.pi / 2 - bTheta - 0.02 + math.pi;
      final arcSweep = math.pi - (math.pi / 2 - bTheta) * 2 + 0.04;
      if (arcSweep > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: bArcCenter, radius: arcR),
          arcStartAngle,
          arcSweep,
          false,
          lp,
        );
      }
    }

    // ── 8. Corner arcs ─────────────────────────────────────────────────────
    final cr = innerW * 0.030;
    final cornerLp = Paint()
      ..color = Colors.white.withAlpha(200)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(border, border),
        width: cr * 2,
        height: cr * 2,
      ),
      0,
      math.pi / 2,
      false,
      cornerLp,
    );
    // Top-right
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(border + innerW, border),
        width: cr * 2,
        height: cr * 2,
      ),
      math.pi / 2,
      math.pi / 2,
      false,
      cornerLp,
    );
    // Bottom-left
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(border, border + innerH),
        width: cr * 2,
        height: cr * 2,
      ),
      -math.pi / 2,
      math.pi / 2,
      false,
      cornerLp,
    );
    // Bottom-right
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(border + innerW, border + innerH),
        width: cr * 2,
        height: cr * 2,
      ),
      math.pi,
      math.pi / 2,
      false,
      cornerLp,
    );

    // ── 9. Subtle vignette at edges ────────────────────────────────────────
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withAlpha(60)],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Player Card (Vertical Rectangle) ─────────────────────────────────────────

enum _CardState { captain, viceCaptain, topPerformer, good, regular, bench }

class _PitchPlayerCard extends StatelessWidget {
  final Map<String, dynamic> pick;
  final FplProvider provider;
  final bool isStarting;
  final int gwId;
  final String? activeChip;
  final VoidCallback onTap;

  const _PitchPlayerCard({
    required this.pick,
    required this.provider,
    required this.isStarting,
    required this.gwId,
    this.activeChip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final playerId = pick['element'] as int;
    final isCaptain = pick['is_captain'] as bool? ?? false;
    final isViceCaptain = pick['is_vice_captain'] as bool? ?? false;
    final multiplier = pick['multiplier'] as int? ?? 1;
    final isBench = (pick['position'] as int) > 11;

    final player = provider.getPlayerById(playerId);
    final live = provider.getLiveStatsForPlayer(playerId);
    final rawPts = live?['total_points'] as int? ?? 0;
    // Fix: bench players have multiplier=0 — show raw points
    final effectivePts = isBench ? rawPts : rawPts * multiplier;

    final posColor = player != null
        ? getPositionColor(player.elementType)
        : AppColors.textSecondary;

    // Determine card state
    final _CardState state;
    if (isCaptain) {
      state = _CardState.captain;
    } else if (isViceCaptain) {
      state = _CardState.viceCaptain;
    } else if (!isBench && effectivePts >= 10) {
      state = _CardState.topPerformer;
    } else if (!isBench && effectivePts >= 6) {
      state = _CardState.good;
    } else if (isBench) {
      state = _CardState.bench;
    } else {
      state = _CardState.regular;
    }

    // State-based visuals
    Color borderColor;
    List<BoxShadow> shadows;
    Gradient? cardGradient;

    switch (state) {
      case _CardState.captain:
        borderColor = const Color(0xFFFFD700);
        shadows = [];
        cardGradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2008), Color(0xFF1A1505)],
        );
      case _CardState.viceCaptain:
        borderColor = AppColors.accent;
        shadows = [];
      case _CardState.topPerformer:
        borderColor = AppColors.primary;
        shadows = [
          BoxShadow(
            color: AppColors.primary.withAlpha(150),
            blurRadius: 14,
            spreadRadius: 1,
          ),
          BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 28),
        ];
        cardGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withAlpha(30), AppColors.cardDark],
        );
      case _CardState.good:
        borderColor = const Color(0xFF34D399);
        shadows = [
          BoxShadow(
            color: const Color(0xFF34D399).withAlpha(90),
            blurRadius: 8,
          ),
        ];
        cardGradient = null;
      case _CardState.bench:
        borderColor = Colors.white.withAlpha(40);
        shadows = [];
        cardGradient = null;
      case _CardState.regular:
        borderColor = posColor.withAlpha(160);
        shadows = [BoxShadow(color: posColor.withAlpha(50), blurRadius: 6)];
        cardGradient = null;
    }

    final borderWidth =
        (state == _CardState.captain ||
            state == _CardState.viceCaptain ||
            state == _CardState.topPerformer ||
            (activeChip == 'bboost' && !isStarting))
        ? 2.5
        : 1.5;

    // Bench Boost effect: Highlight bench players
    if (activeChip == 'bboost' && !isStarting) {
      borderColor = const Color(0xFF34D399);
      shadows = [
        BoxShadow(
          color: const Color(0xFF34D399).withAlpha(100),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];
    }

    const cardWidth = 60.0;
    const cardHeight = 64.0;
    const badgeRadius = 9.0; // badge is 18px diameter, so half = 9

    // Photo-only card wrapped in Stack(clip.none) so badge can overflow
    final photoCard = Stack(
      clipBehavior: Clip.none,
      children: [
        // Image container — no name strip inside
        Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: shadows,
            color: AppColors.cardDark,
            gradient: cardGradient,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Player photo
              if (player != null)
                CachedNetworkImage(
                  imageUrl: player.photoUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  placeholder: (_, __) => Center(
                    child: Icon(Icons.person, color: posColor, size: 26),
                  ),
                  errorWidget: (_, __, ___) => Center(
                    child: Icon(Icons.person, color: posColor, size: 26),
                  ),
                )
              else
                Center(child: Icon(Icons.person, color: posColor, size: 26)),

              // Captain / Vice-Captain badge inside the box (Top Left)
              if (isCaptain)
                Positioned(
                  top: 4,
                  left: 4,
                  child: _buildBadge('C', isTriple: activeChip == '3xc'),
                )
              else if (isViceCaptain)
                Positioned(top: 4, left: 4, child: _buildBadge('V')),

              // // Star for top performer (inside card, top-right)
              // if (state == _CardState.topPerformer)
              //   const Positioned(
              //     top: 4,
              //     right: 4,
              //     child: Icon(
              //       Icons.star_rounded,
              //       color: Color(0xFFFFD700),
              //       size: 13,
              //       shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
              //     ),
              //   ),
            ],
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo card — badge overflows freely (clip.none on outer Stack)
            photoCard,
            // Name box — same width, perfectly aligned left
            Container(
              width: cardWidth,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(isBench ? 120 : 180),
              ),
              child: Text(
                player?.webName ?? '?',
                style: TextStyle(
                  color: isBench ? Colors.white : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Points box — same width as card, flush below name
            Container(
              width: cardWidth,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: _ptsBadgeColor(state, effectivePts),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
                // boxShadow:
                //     state == _CardState.captain ||
                //         state == _CardState.topPerformer
                //     ? [
                //         BoxShadow(
                //           color: _ptsBadgeColor(
                //             state,
                //             effectivePts,
                //           ).withAlpha(120),
                //           blurRadius: 6,
                //         ),
                //       ]
                //     : null,
              ),
              child: Text(
                _getStatusText(player),
                style: TextStyle(
                  color: _ptsBadgeTextColor(state),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(Player? player) {
    if (player == null) return '?';

    final fixtures =
        provider
            .getFixturesForGameweek(gwId)
            .where(
              (f) =>
                  f.homeTeamId == player.teamId ||
                  f.awayTeamId == player.teamId,
            )
            .toList()
          ..sort(
            (a, b) => (a.kickoffTime ?? '').compareTo(b.kickoffTime ?? ''),
          );

    if (fixtures.isEmpty) return '--';

    final live = provider.getLiveStatsForPlayer(player.id);
    final rawPts = live?['total_points'] as int? ?? 0;
    final isBench = (pick['position'] as int) > 11;
    final multiplier = pick['multiplier'] as int? ?? 1;

    // If active chip is bench boost, bench players also get multiplier 1
    int effectivePts = rawPts;
    if (!isBench) {
      effectivePts = rawPts * multiplier;
    } else if (activeChip == 'bboost') {
      effectivePts = rawPts;
    }

    // Check match status
    bool anyStarted = fixtures.any((f) => f.started ?? false);
    bool allFinished = fixtures.every((f) => f.finished);

    if (!anyStarted) {
      // Show opponents
      return fixtures
          .map((f) {
            final isHome = f.homeTeamId == player.teamId;
            final oppId = isHome ? f.awayTeamId : f.homeTeamId;
            final opp = provider.getTeamById(oppId);
            final shortName = opp?.shortName ?? 'OPP';
            return '$shortName(${isHome ? 'H' : 'A'})';
          })
          .join(',');
    }

    if (allFinished) {
      return '$effectivePts pts';
    }

    // Some started/finished, some yet to play
    final pending = fixtures.where((f) => !(f.started ?? false)).toList();
    if (pending.isEmpty) {
      return '$effectivePts pts';
    }

    final pendingStr = pending
        .map((f) {
          final isHome = f.homeTeamId == player.teamId;
          final oppId = isHome ? f.awayTeamId : f.homeTeamId;
          final opp = provider.getTeamById(oppId);
          final shortName = opp?.shortName ?? 'OPP';
          return '$shortName(${isHome ? 'H' : 'A'})';
        })
        .join(',');

    return '$effectivePts pts,$pendingStr';
  }

  Widget _buildBadge(String letter, {bool isTriple = false}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isTriple ? Colors.white : Colors.black,
        shape: BoxShape.circle,
        border: Border.all(
          color: isTriple ? Colors.black : Colors.white,
          width: 0.8,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            color: isTriple ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Color _ptsBadgeColor(_CardState state, int pts) {
    switch (state) {
      case _CardState.captain:
        return AppColors.accent;
      case _CardState.viceCaptain:
        return AppColors.primary;
      case _CardState.topPerformer:
        return AppColors.primary;
      case _CardState.good:
        return const Color(0xFF34D399);
      case _CardState.bench:
        return AppColors.primary.withAlpha(90);
      case _CardState.regular:
        return AppColors.primary.withAlpha(160);
    }
    return AppColors.primary.withAlpha(160);
  }

  Color _ptsBadgeTextColor(_CardState state) {
    switch (state) {
      case _CardState.bench:
        return Colors.black;
      default:
        return Colors.black;
    }
  }
}

// ─── Player Points Bottom Sheet ───────────────────────────────────────────────

class _PlayerPointsSheet extends StatelessWidget {
  final Player? player;
  final Map<String, dynamic>? live;
  final int effectivePts;
  final bool isCaptain;
  final bool isViceCaptain;
  final int multiplier;
  final bool isBench;
  final FplProvider provider;

  const _PlayerPointsSheet({
    required this.player,
    required this.live,
    required this.effectivePts,
    required this.isCaptain,
    required this.isViceCaptain,
    required this.multiplier,
    required this.isBench,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final posColor = player != null
        ? getPositionColor(player!.elementType)
        : AppColors.textSecondary;
    final team = player != null ? provider.getTeamById(player!.teamId) : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardMedium,
                  border: Border.all(color: posColor.withAlpha(120), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: player != null
                    ? CachedNetworkImage(
                        imageUrl: player!.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Icon(Icons.person, color: posColor, size: 28),
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.person, color: posColor, size: 28),
                      )
                    : const Icon(
                        Icons.person,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          player?.webName ?? 'Unknown',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isCaptain) ...[
                          const SizedBox(width: 8),
                          _badge('C', const Color(0xFFFFD700)),
                        ] else if (isViceCaptain) ...[
                          const SizedBox(width: 8),
                          _badge('V', AppColors.accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: posColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: posColor.withAlpha(120)),
                          ),
                          child: Text(
                            player != null
                                ? getPositionShort(player!.elementType)
                                : '–',
                            style: TextStyle(
                              color: posColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          team?.name ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (isBench) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '(Bench)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$effectivePts',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'pts',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          if (live != null) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'POINTS BREAKDOWN',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildBreakdown(),
            if (isCaptain && multiplier > 1) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFFFD700),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Captain ×$multiplier multiplier applied',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            const Text(
              'No live data available for this player.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBreakdown() {
    final minutes = live?['minutes'] as int? ?? 0;
    final goals = live?['goals_scored'] as int? ?? 0;
    final assists = live?['assists'] as int? ?? 0;
    final cleanSheets = live?['clean_sheets'] as int? ?? 0;
    final goalsConceded = live?['goals_conceded'] as int? ?? 0;
    final ownGoals = live?['own_goals'] as int? ?? 0;
    final penaltiesSaved = live?['penalties_saved'] as int? ?? 0;
    final penaltiesMissed = live?['penalties_missed'] as int? ?? 0;
    final yellowCards = live?['yellow_cards'] as int? ?? 0;
    final redCards = live?['red_cards'] as int? ?? 0;
    final saves = live?['saves'] as int? ?? 0;
    final bonus = live?['bonus'] as int? ?? 0;
    final pos = player?.elementType ?? 0;

    int minutePts = minutes >= 60
        ? 2
        : minutes > 0
        ? 1
        : 0;

    int goalPts = 0;
    if (pos == 1 || pos == 2) {
      goalPts = goals * 6;
    } else if (pos == 3) {
      goalPts = goals * 5;
    } else {
      goalPts = goals * 4;
    }

    final assistPts = assists * 3;

    int csPts = 0;
    if (cleanSheets > 0) {
      if (pos == 1 || pos == 2) {
        csPts = cleanSheets * 4;
      } else if (pos == 3) {
        csPts = cleanSheets * 1;
      }
    }

    int gcPts = 0;
    if (pos == 1 || pos == 2) {
      gcPts = -(goalsConceded ~/ 2);
    }

    final items = <_BreakdownItem>[
      _BreakdownItem(
        Icons.timer_outlined,
        'Minutes played ($minutes)',
        minutePts,
      ),
      if (goals > 0)
        _BreakdownItem(
          Icons.sports_soccer_rounded,
          'Goals scored ($goals)',
          goalPts,
        ),
      if (assists > 0)
        _BreakdownItem(
          Icons.assistant_rounded,
          'Assists ($assists)',
          assistPts,
        ),
      if (cleanSheets > 0 && csPts != 0)
        _BreakdownItem(Icons.shield_rounded, 'Clean sheet', csPts),
      if (goalsConceded > 0 && gcPts != 0)
        _BreakdownItem(
          Icons.sports_soccer_outlined,
          'Goals conceded ($goalsConceded)',
          gcPts,
        ),
      if (ownGoals > 0)
        _BreakdownItem(
          Icons.undo_rounded,
          'Own goals ($ownGoals)',
          ownGoals * -2,
        ),
      if (penaltiesSaved > 0)
        _BreakdownItem(
          Icons.pan_tool_rounded,
          'Penalties saved ($penaltiesSaved)',
          penaltiesSaved * 5,
        ),
      if (penaltiesMissed > 0)
        _BreakdownItem(
          Icons.close_rounded,
          'Penalties missed ($penaltiesMissed)',
          penaltiesMissed * -2,
        ),
      if (yellowCards > 0)
        _BreakdownItem(Icons.square_rounded, 'Yellow card', yellowCards * -1),
      if (redCards > 0)
        _BreakdownItem(Icons.square_rounded, 'Red card', redCards * -3),
      if (saves > 0)
        _BreakdownItem(Icons.back_hand_rounded, 'Saves ($saves)', saves ~/ 3),
      if (bonus > 0)
        _BreakdownItem(Icons.add_circle_rounded, 'Bonus points', bonus),
    ];

    return Column(
      children: items.map((item) {
        final isPos = item.points > 0;
        final isNeg = item.points < 0;
        final color = isNeg
            ? AppColors.error
            : isPos
            ? AppColors.primary
            : AppColors.textSecondary;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(item.icon, color: color, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                item.points >= 0 ? '+${item.points}' : '${item.points}',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _badge(String letter, Color color) {
    return CircleAvatar(
      backgroundColor: color,
      radius: 10,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: AppColors.cardDark,
        ),
      ),
    );
  }
}

class _BreakdownItem {
  final IconData icon;
  final String label;
  final int points;
  const _BreakdownItem(this.icon, this.label, this.points);
}
