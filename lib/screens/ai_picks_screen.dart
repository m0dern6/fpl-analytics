import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/fpl_provider.dart';
import '../models/player.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import 'player_detail_screen.dart';

class AiPicksScreen extends StatefulWidget {
  const AiPicksScreen({super.key});

  @override
  State<AiPicksScreen> createState() => _AiPicksScreenState();
}

class _AiPicksScreenState extends State<AiPicksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isAnalysing = false;
  AiPickMode _computedMode = AiPickMode.bestXi;
  Map<String, List<Player>>? _result;

  static const _tabs = [
    _TabInfo('Best XI', Icons.star, AppColors.primary, AiPickMode.bestXi),
    _TabInfo('Wildcard', Icons.shuffle, Color(0xFFB388FF), AiPickMode.wildcard),
    _TabInfo('Free Hit', Icons.refresh, AppColors.accent, AiPickMode.freeHit),
    _TabInfo(
        'Triple Cap', Icons.star_border, AppColors.warning, AiPickMode.tripleCaptain),
    _TabInfo(
        'Bench Boost', Icons.people, AppColors.error, AiPickMode.benchBoost),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _analyse(AiPickMode.bestXi));
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Handled by mode selector; no-op here.
  }

  Future<void> _analyse(AiPickMode mode) async {
    if (!mounted) return;
    setState(() {
      _isAnalysing = true;
      _result = null;
      _computedMode = mode;
    });
    // Simulate a brief "thinking" delay for UX
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final provider = context.read<FplProvider>();
    final result = provider.computeAiTeam(mode);
    if (mounted) {
      setState(() {
        _isAnalysing = false;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(builder: (context, provider, _) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('AI Smart Picks'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ── Mode selector ─────────────────────────────────────────────
            _buildModeSelector(),
            const SizedBox(height: 2),
            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: provider.isLoading
                  ? const LoadingListWidget()
                  : _buildTabBody(context, provider),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildModeSelector() {
    return Container(
      color: AppColors.secondary,
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: _tabs.length,
          itemBuilder: (_, i) {
            final tab = _tabs[i];
            final isSelected = _tabCtrl.index == i;
            return GestureDetector(
              onTap: () {
                if (_tabCtrl.index == i) return;
                _tabCtrl.animateTo(i);
                setState(() {});
                _analyse(tab.mode);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tab.color.withAlpha(28)
                      : AppColors.cardMedium,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? tab.color.withAlpha(160)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon,
                        color: isSelected
                            ? tab.color
                            : AppColors.textSecondary,
                        size: 14),
                    const SizedBox(width: 5),
                    Text(
                      tab.label,
                      style: TextStyle(
                        color: isSelected
                            ? tab.color
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildTabBody(BuildContext context, FplProvider provider) {
    if (_isAnalysing) {
      return _buildAnalysingView();
    }
    if (_result == null || provider.players.isEmpty) {
      return const Center(
          child: Text('No data available',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return _buildResultView(context, provider, _result!, _computedMode);
  }

  Widget _buildAnalysingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(18),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.primary.withAlpha(60), width: 1.5),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            'Analysing players…',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Using form, xG, ICT, fixtures & transfer\ntrends to build the best team.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.cardMedium,
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(BuildContext context, FplProvider provider,
      Map<String, List<Player>> result, AiPickMode mode) {
    final starting = result['starting'] ?? [];
    final subs = result['subs'] ?? [];
    final all = result['all'] ?? [];
    final captain = result['captain']?.firstOrNull;
    final viceCaptain = result['viceCaptain']?.firstOrNull;
    final totalCost = all.fold<int>(0, (s, p) => s + p.nowCost);
    final totalPts = starting.fold<int>(0, (s, p) => s + p.totalPoints);

    final gks = starting.where((p) => p.elementType == 1).toList();
    final defs = starting.where((p) => p.elementType == 2).toList();
    final mids = starting.where((p) => p.elementType == 3).toList();
    final fwds = starting.where((p) => p.elementType == 4).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardDark,
      onRefresh: () => _analyse(mode),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildModeExplanation(mode),
            _buildStats(totalCost, totalPts, captain, mode),
            _buildPitch(context, gks, defs, mids, fwds, captain, viceCaptain,
                provider),
            _buildSubsSection(context, subs, provider),
            _buildCaptainRationale(captain, viceCaptain, provider),
            _buildTopPlayersTable(context, starting, provider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModeExplanation(AiPickMode mode) {
    final info = _modeInfo(mode);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: info.color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: info.color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(info.icon, color: info.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title,
                    style: TextStyle(
                        color: info.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(info.desc,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(
      int totalCost, int totalPts, Player? captain, AiPickMode mode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.purpleGradient(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('Total Cost', formatPrice(totalCost), Icons.attach_money),
          _statItem('Season Pts', '$totalPts', Icons.star),
          if (captain != null)
            _statItem('Captain', captain.webName, Icons.star_border),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildPitch(
    BuildContext context,
    List<Player> gks,
    List<Player> defs,
    List<Player> mids,
    List<Player> fwds,
    Player? captain,
    Player? viceCaptain,
    FplProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a4a1a), Color(0xFF0d2d0d)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(51)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          _pitchRow(context, fwds, captain, viceCaptain,
              PositionConstants.positionColors[4]!, provider),
          const SizedBox(height: 10),
          _pitchRow(context, mids, captain, viceCaptain,
              PositionConstants.positionColors[3]!, provider),
          const SizedBox(height: 10),
          _pitchRow(context, defs, captain, viceCaptain,
              PositionConstants.positionColors[2]!, provider),
          const SizedBox(height: 10),
          _pitchRow(context, gks, captain, viceCaptain,
              PositionConstants.positionColors[1]!, provider),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _pitchRow(
    BuildContext context,
    List<Player> players,
    Player? captain,
    Player? viceCaptain,
    Color posColor,
    FplProvider provider,
  ) {
    if (players.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: players.map((p) {
          final diff = provider.getNextFixtureDifficulty(p.teamId);
          return SizedBox(
            width: (constraints.maxWidth / players.length).clamp(60.0, 80.0),
            child: _AiPitchPlayer(
              player: p,
              posColor: posColor,
              isCaptain: captain?.id == p.id,
              isViceCaptain: viceCaptain?.id == p.id,
              nextFixtureDifficulty: diff,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: p))),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildSubsSection(
      BuildContext context, List<Player> subs, FplProvider provider) {
    if (subs.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.swap_horiz, color: AppColors.textSecondary, size: 16),
              SizedBox(width: 6),
              Text('Substitutes',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: subs.take(4).map((p) {
                final diff = provider.getNextFixtureDifficulty(p.teamId);
                return SizedBox(
                  width: (constraints.maxWidth / 4).clamp(60.0, 80.0),
                  child: _AiPitchPlayer(
                    player: p,
                    posColor: getPositionColor(p.elementType),
                    isSub: true,
                    nextFixtureDifficulty: diff,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PlayerDetailScreen(player: p))),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCaptainRationale(
      Player? captain, Player? viceCaptain, FplProvider provider) {
    if (captain == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.gradientCard(
          colors: [const Color(0xFF1a2a3a), const Color(0xFF0d1a2a)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 16),
              SizedBox(width: 6),
              Text('Captain Pick Rationale',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          _rationaleRow(captain, '⭐ Captain', provider),
          if (viceCaptain != null) ...[
            const SizedBox(height: 8),
            _rationaleRow(viceCaptain, 'Vice Captain', provider),
          ],
        ],
      ),
    );
  }

  Widget _rationaleRow(Player player, String role, FplProvider provider) {
    final diff = provider.getNextFixtureDifficulty(player.teamId);
    final diffColor =
        DifficultyConstants.colors[diff] ?? AppColors.textSecondary;
    final team = provider.getTeamById(player.teamId);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cardMedium,
            border: Border.all(
                color: getPositionColor(player.elementType), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: CachedNetworkImage(
            imageUrl: player.photoUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => const Icon(Icons.person,
                color: AppColors.textSecondary, size: 18),
            errorWidget: (_, __, ___) => const Icon(Icons.person,
                color: AppColors.textSecondary, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player.webName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(
                  '${team?.shortName ?? ''} • Form ${player.form} • ${formatPrice(player.nowCost)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(role,
                style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: diffColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 3),
                Text('FDR $diff',
                    style: TextStyle(color: diffColor, fontSize: 10)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopPlayersTable(
      BuildContext context, List<Player> players, FplProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(Icons.analytics, color: AppColors.accent, size: 16),
                SizedBox(width: 6),
                Text('Player Stats',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: const [
                Expanded(
                    flex: 3,
                    child: Text('Player',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11))),
                Expanded(
                    child: Text('Form',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('xG',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('ICT',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('FDR',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...players.asMap().entries.map((e) {
            final p = e.value;
            final team = provider.getTeamById(p.teamId);
            final diff = provider.getNextFixtureDifficulty(p.teamId);
            final diffColor =
                DifficultyConstants.colors[diff] ?? AppColors.textSecondary;
            final posColor = getPositionColor(p.elementType);
            return InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: p))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 28,
                            decoration: BoxDecoration(
                              color: posColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.webName,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(team?.shortName ?? '',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(p.form,
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    ),
                    Expanded(
                      child: Text(
                          (double.tryParse(p.expectedGoalsStr) ?? 0)
                              .toStringAsFixed(1),
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    Expanded(
                      child: Text(
                          (double.tryParse(p.ictIndex) ?? 0)
                              .toStringAsFixed(0),
                          style: const TextStyle(
                              color: AppColors.warning, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: diffColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('$diff',
                            style: TextStyle(
                                color: diffColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  _ModeInfo _modeInfo(AiPickMode mode) {
    switch (mode) {
      case AiPickMode.wildcard:
        return const _ModeInfo(
          icon: Icons.shuffle,
          color: Color(0xFFB388FF),
          title: 'Wildcard Team',
          desc:
              'Optimised for the best fixture run over the next 5 gameweeks. '
              'Great for a complete squad rebuild.',
        );
      case AiPickMode.freeHit:
        return const _ModeInfo(
          icon: Icons.refresh,
          color: AppColors.accent,
          title: 'Free Hit Team',
          desc:
              'Unlimited budget – picks the absolute best 15 players for this '
              'single gameweek only, ignoring price constraints.',
        );
      case AiPickMode.tripleCaptain:
        return const _ModeInfo(
          icon: Icons.star_border,
          color: AppColors.warning,
          title: 'Triple Captain Suggestion',
          desc:
              'Identifies the player with the highest ceiling for this week. '
              'Pick your captain wisely – their points count 3×.',
        );
      case AiPickMode.benchBoost:
        return const _ModeInfo(
          icon: Icons.people,
          color: AppColors.error,
          title: 'Bench Boost Team',
          desc:
              'All 15 players optimised for maximum expected points. '
              'Use when your bench players also have great fixtures.',
        );
      default:
        return const _ModeInfo(
          icon: Icons.auto_awesome,
          color: AppColors.primary,
          title: 'AI Best XI',
          desc:
              'Smart algorithm using form, xG, xA, ICT index, fixture '
              'difficulty & transfer trends to pick your optimal squad.',
        );
    }
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class _TabInfo {
  final String label;
  final IconData icon;
  final Color color;
  final AiPickMode mode;
  const _TabInfo(this.label, this.icon, this.color, this.mode);
}

class _ModeInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _ModeInfo(
      {required this.icon,
      required this.color,
      required this.title,
      required this.desc});
}

// ─── Pitch Player for AI Screen ───────────────────────────────────────────────

class _AiPitchPlayer extends StatelessWidget {
  final Player player;
  final Color posColor;
  final bool isSub;
  final bool isCaptain;
  final bool isViceCaptain;
  final VoidCallback? onTap;
  final int? nextFixtureDifficulty;

  const _AiPitchPlayer({
    required this.player,
    required this.posColor,
    this.isSub = false,
    this.isCaptain = false,
    this.isViceCaptain = false,
    this.onTap,
    this.nextFixtureDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = nextFixtureDifficulty != null
        ? (DifficultyConstants.colors[nextFixtureDifficulty] ??
            AppColors.textSecondary)
        : null;
    final size = isSub ? 46.0 : 54.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardDark,
                  border: Border.all(color: posColor, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: player.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Icon(Icons.person,
                      color: AppColors.textSecondary, size: size * 0.5),
                  errorWidget: (_, __, ___) => Icon(Icons.person,
                      color: AppColors.textSecondary, size: size * 0.5),
                ),
              ),
              if (diffColor != null)
                Positioned(
                  bottom: 0,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: diffColor,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.cardDark, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${nextFixtureDifficulty}',
                        style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              if (isCaptain)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: AppColors.warning, shape: BoxShape.circle),
                    child: const Center(
                        child: Text('C',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary))),
                  ),
                ),
              if (isViceCaptain)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle),
                    child: const Center(
                        child: Text('V',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary))),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(153),
              borderRadius: BorderRadius.circular(4),
            ),
            constraints: const BoxConstraints(maxWidth: 72),
            child: Text(
              player.webName.length > 9
                  ? player.webName.substring(0, player.webName.length.clamp(0, 8))
                  : player.webName,
              style: const TextStyle(
                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(204),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              player.form,
              style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
