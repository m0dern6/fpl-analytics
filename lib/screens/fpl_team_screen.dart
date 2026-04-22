import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/fpl_provider.dart';
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

  // Loaded data
  Map<String, dynamic>? _entry;
  Map<String, dynamic>? _picks;
  int? _gwNumber;

  @override
  void initState() {
    super.initState();
    _loadSavedId();
  }

  Future<void> _loadSavedId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && saved.isNotEmpty) {
      _controller.text = saved;
    }
  }

  Future<void> _saveId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, id);
  }

  Future<void> _fetchTeam() async {
    if (!_formKey.currentState!.validate()) return;
    final id = int.tryParse(_controller.text.trim());
    if (id == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _entry = null;
      _picks = null;
    });

    try {
      await _saveId(_controller.text.trim());
      final fplProvider = context.read<FplProvider>();
      final gw = fplProvider.currentGameweek?.id ?? 1;

      final results = await Future.wait([
        _service.fetchFplEntry(id),
        _service.fetchFplEntryPicks(id, gw),
      ]);

      // Ensure live GW data is loaded so we can show player points
      if (mounted) {
        await fplProvider.loadLiveGwData(gw);
      }

      if (!mounted) return;
      setState(() {
        _entry = results[0];
        _picks = results[1];
        _gwNumber = gw;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildForm(),
            if (_loading) ...[
              const SizedBox(height: 32),
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ] else if (_error != null) ...[
              const SizedBox(height: 24),
              _buildError(),
            ] else if (_entry != null && _picks != null) ...[
              const SizedBox(height: 24),
              _buildEntryInfo(),
              const SizedBox(height: 20),
              _buildGwHistory(),
              const SizedBox(height: 20),
              _buildPicksList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.manage_accounts_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Look up your FPL team',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter the team ID from your FPL URL:\nfantasy.premierleague.com/entry/{id}/...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1234567',
                      prefixIcon: Icon(Icons.tag_rounded,
                          color: AppColors.textSecondary, size: 18),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a team ID';
                      }
                      if (int.tryParse(v.trim()) == null) {
                        return 'Team ID must be a number';
                      }
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
                        horizontal: 18, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _fetchTeam,
                  child: const Text('Go',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              style:
                  const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryInfo() {
    final e = _entry!;
    final teamName = e['name'] as String? ?? '–';
    final managerFirst = e['player_first_name'] as String? ?? '';
    final managerLast = e['player_last_name'] as String? ?? '';
    final manager =
        '$managerFirst $managerLast'.trim().isEmpty ? '–' : '$managerFirst $managerLast';
    final overallPoints = e['summary_overall_points'] as int? ?? 0;
    final overallRank = e['summary_overall_rank'] as int?;
    final eventPoints = e['summary_event_points'] as int? ?? 0;
    final eventRank = e['summary_event_rank'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTheme.sectionTitle(context, 'Team Overview'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.gradientCard(),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withAlpha(80)),
                    ),
                    child: const Center(
                      child: Icon(Icons.sports_soccer_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          manager,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 14),
              Row(
                children: [
                  _infoTile('Total Points', '$overallPoints pts',
                      AppColors.primary),
                  const SizedBox(width: 10),
                  _infoTile(
                    'Overall Rank',
                    overallRank != null
                        ? _formatRank(overallRank)
                        : '–',
                    AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  _infoTile('GW$_gwNumber Pts', '$eventPoints pts',
                      AppColors.warning),
                  if (eventRank != null) ...[
                    const SizedBox(width: 10),
                    _infoTile('GW Rank', _formatRank(eventRank),
                        const Color(0xFF34D399)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGwHistory() {
    final history = _picks?['entry_history'] as Map<String, dynamic>?;
    if (history == null) return const SizedBox.shrink();

    final points = history['points'] as int? ?? 0;
    final pointsOnBench = history['points_on_bench'] as int? ?? 0;
    final totalPoints = history['total_points'] as int? ?? 0;
    final rank = history['rank'] as int?;
    final transfers = history['event_transfers'] as int? ?? 0;
    final transferCost = history['event_transfers_cost'] as int? ?? 0;
    final activeChip = _picks?['active_chip'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTheme.sectionTitle(context, 'GW$_gwNumber Summary'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.gradientCard(),
          child: Column(
            children: [
              if (activeChip != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(22),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.warning.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _chipLabel(activeChip),
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _gwStatTile('Points', '$points', AppColors.primary),
                  const SizedBox(width: 8),
                  _gwStatTile('On Bench', '$pointsOnBench',
                      AppColors.textSecondary),
                  const SizedBox(width: 8),
                  _gwStatTile('Total', '$totalPoints', AppColors.accent),
                  const SizedBox(width: 8),
                  _gwStatTile(
                    'Rank',
                    rank != null ? _formatRank(rank) : '–',
                    const Color(0xFF34D399),
                  ),
                ],
              ),
              if (transfers > 0 || transferCost > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded,
                        color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$transfers transfer${transfers != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    if (transferCost > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(22),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-$transferCost pts',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _gwStatTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicksList() {
    final picksRaw = _picks?['picks'] as List<dynamic>?;
    if (picksRaw == null || picksRaw.isEmpty) return const SizedBox.shrink();

    final fplProvider = context.read<FplProvider>();

    final startingPicks = picksRaw
        .where((p) => (p as Map<String, dynamic>)['position'] as int <= 11)
        .toList();
    final benchPicks = picksRaw
        .where((p) => (p as Map<String, dynamic>)['position'] as int > 11)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTheme.sectionTitle(context, 'Starting XI'),
        const SizedBox(height: 12),
        _buildPicksGroup(startingPicks, fplProvider),
        const SizedBox(height: 20),
        AppTheme.sectionTitle(context, 'Bench'),
        const SizedBox(height: 12),
        _buildPicksGroup(benchPicks, fplProvider, isBench: true),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPicksGroup(
    List<dynamic> picks,
    FplProvider fplProvider, {
    bool isBench = false,
  }) {
    return Container(
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: picks.asMap().entries.map((entry) {
          final idx = entry.key;
          final pick = entry.value as Map<String, dynamic>;
          final playerId = pick['element'] as int;
          final isCaptain = pick['is_captain'] as bool? ?? false;
          final isViceCaptain = pick['is_vice_captain'] as bool? ?? false;
          final multiplier = pick['multiplier'] as int? ?? 1;

          final player = fplProvider.getPlayerById(playerId);
          final live = fplProvider.getLiveStatsForPlayer(playerId);
          final rawPts = live?['total_points'] as int? ?? 0;
          final pts = rawPts * multiplier;

          final isLast = idx == picks.length - 1;

          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isLast ? Colors.transparent : AppColors.divider,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Position badge
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: player != null
                        ? getPositionColor(player.elementType)
                            .withAlpha(30)
                        : AppColors.cardMedium,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      player != null
                          ? getPositionShort(player.elementType)
                          : '?',
                      style: TextStyle(
                        color: player != null
                            ? getPositionColor(player.elementType)
                            : AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Photo
                Container(
                  width: 36,
                  height: 36,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardMedium,
                  ),
                  child: player != null
                      ? CachedNetworkImage(
                          imageUrl: player.photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Icon(Icons.person,
                              color: AppColors.textSecondary, size: 18),
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.person,
                              color: AppColors.textSecondary,
                              size: 18),
                        )
                      : const Icon(Icons.person,
                          color: AppColors.textSecondary, size: 18),
                ),
                const SizedBox(width: 10),
                // Name + captain badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              player?.webName ?? 'Unknown',
                              style: TextStyle(
                                color: isBench
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCaptain) ...[
                            const SizedBox(width: 5),
                            _captainBadge('C', AppColors.warning),
                          ] else if (isViceCaptain) ...[
                            const SizedBox(width: 5),
                            _captainBadge('V', AppColors.accent),
                          ],
                        ],
                      ),
                      if (player != null)
                        Text(
                          _teamName(player.teamId, fplProvider),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                // Points
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isBench
                        ? AppColors.cardMedium
                        : AppColors.primary.withAlpha(22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isBench
                          ? AppColors.divider
                          : AppColors.primary.withAlpha(80),
                    ),
                  ),
                  child: Text(
                    '$pts pts',
                    style: TextStyle(
                      color: isBench
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _captainBadge(String letter, Color color) {
    return CircleAvatar(
      backgroundColor: color,
      radius: 9,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  String _teamName(int teamId, FplProvider fplProvider) {
    final team = fplProvider.getTeamById(teamId);
    return team?.shortName ?? '–';
  }

  String _formatRank(int rank) {
    if (rank >= 1000000) {
      return '${(rank / 1000000).toStringAsFixed(1)}M';
    }
    if (rank >= 1000) {
      return '${(rank / 1000).toStringAsFixed(0)}k';
    }
    return rank.toString();
  }

  String _chipLabel(String chip) {
    switch (chip) {
      case 'bboost':
        return 'Bench Boost';
      case '3xc':
        return 'Triple Captain';
      case 'freehit':
        return 'Free Hit';
      case 'wildcard':
        return 'Wildcard';
      default:
        return chip;
    }
  }
}
