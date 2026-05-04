import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/fpl_provider.dart';
import '../providers/fpl_entry_provider.dart';
import '../models/player.dart';
import '../models/entry.dart';
import '../logic/fpl_rules.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';
import 'player_detail_screen.dart';

class TransferPlannerScreen extends StatefulWidget {
  const TransferPlannerScreen({super.key});

  @override
  State<TransferPlannerScreen> createState() => _TransferPlannerScreenState();
}

class _TransferPlannerScreenState extends State<TransferPlannerScreen> {
  // Track pending transfers: outgoing player ID → incoming player ID
  final Map<int, int?> _pendingOuts = {}; // out → in (null if no replacement chosen)
  final Set<int> _lockedPlayers = {};

  @override
  Widget build(BuildContext context) {
    return Consumer2<FplProvider, FplEntryProvider>(
      builder: (context, fplProvider, entryProvider, _) {
        final picks = entryProvider.currentPicks;

        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            backgroundColor: AppColors.of(context).secondary,
            title: const Text('Transfer Planner'),
            actions: [
              if (_pendingOuts.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _pendingOuts.clear()),
                  child: Text(
                    'Reset',
                    style: TextStyle(color: AppColors.of(context).error),
                  ),
                ),
            ],
          ),
          body: picks == null
              ? _buildNoEntry(context, entryProvider)
              : _buildPlanner(context, fplProvider, entryProvider, picks),
        );
      },
    );
  }

  Widget _buildNoEntry(BuildContext context, FplEntryProvider entryProvider) {
    if (!entryProvider.hasEntry) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz_rounded,
                  color: AppColors.of(context).primary, size: 64),
              const SizedBox(height: 20),
              Text(
                'Link your FPL team',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Link your FPL Entry ID to use the Transfer Planner.',
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: LoadingWidget(height: 300));
  }

  Widget _buildPlanner(
    BuildContext context,
    FplProvider fplProvider,
    FplEntryProvider entryProvider,
    EntryGwPicks picks,
  ) {
    final freeTransfers = entryProvider.currentFreeTransfers;
    final outCount = _pendingOuts.length;
    final hitPoints = calculateHits(
      transfersMade: outCount,
      freeTransfers: freeTransfers,
    );

    // Compute team value with sell prices
    final totalSellValue = picks.picks.fold<int>(0, (sum, p) => sum + p.sellingPrice);
    final bank = picks.bank;

    return Column(
      children: [
        _TransferSummaryBar(
          freeTransfers: freeTransfers,
          pendingTransfers: outCount,
          hitPoints: hitPoints,
          bank: bank,
          teamValue: totalSellValue,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildModelNote(context),
              const SizedBox(height: 12),
              _buildSectionHeader(context, 'Starting XI'),
              ...picks.startingPicks.map((pick) => _buildPlayerRow(
                    context,
                    pick,
                    fplProvider,
                    entryProvider,
                  )),
              const SizedBox(height: 8),
              _buildSectionHeader(context, 'Bench'),
              ...picks.benchPicks.map((pick) => _buildPlayerRow(
                    context,
                    pick,
                    fplProvider,
                    entryProvider,
                    isBench: true,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.of(context).primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(
    BuildContext context,
    EntryPick pick,
    FplProvider fplProvider,
    FplEntryProvider entryProvider, {
    bool isBench = false,
  }) {
    final player = fplProvider.getPlayerById(pick.element);
    if (player == null) return const SizedBox.shrink();

    final isLocked = _lockedPlayers.contains(pick.element);
    final isOut = _pendingOuts.containsKey(pick.element);
    final incomingId = _pendingOuts[pick.element];
    final incomingPlayer = incomingId != null ? fplProvider.getPlayerById(incomingId) : null;

    final sellPrice = calculateSellPrice(
      purchasePrice: pick.purchasePrice,
      currentPrice: player.nowCost,
    );
    final profitLoss = sellPrice - pick.purchasePrice;

    return GestureDetector(
      onLongPress: () {
        setState(() {
          if (isLocked) {
            _lockedPlayers.remove(pick.element);
          } else {
            _lockedPlayers.add(pick.element);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOut
              ? AppColors.of(context).error.withAlpha(15)
              : isBench
                  ? AppColors.of(context).cardMedium
                  : AppColors.of(context).cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocked
                ? AppColors.of(context).primary.withAlpha(80)
                : isOut
                    ? AppColors.of(context).error.withAlpha(60)
                    : AppColors.of(context).divider,
            width: isLocked ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CachedNetworkImage(
                  imageUrl: player.photoUrl,
                  width: 36,
                  height: 36,
                  imageBuilder: (_, img) => ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image(image: img, fit: BoxFit.cover),
                  ),
                  errorWidget: (_, __, ___) => CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.of(context).cardMedium,
                    child: Icon(Icons.person,
                        color: AppColors.of(context).textSecondary, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            player.webName,
                            style: TextStyle(
                              color: AppColors.of(context).textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration:
                                  isOut ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (isLocked) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.lock_rounded,
                                color: AppColors.of(context).primary, size: 12),
                          ],
                          if (pick.isCaptain) ...[
                            const SizedBox(width: 4),
                            _positionBadge('C', AppColors.of(context).primary),
                          ] else if (pick.isViceCaptain) ...[
                            const SizedBox(width: 4),
                            _positionBadge('V', AppColors.of(context).accent),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            formatPrice(player.nowCost),
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            ' · Sell: ${formatPrice(sellPrice)}',
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          if (profitLoss != 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${profitLoss > 0 ? '+' : ''}${formatPrice(profitLoss)}',
                              style: TextStyle(
                                color: profitLoss > 0
                                    ? AppColors.of(context).primary
                                    : AppColors.of(context).error,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isLocked)
                  IconButton(
                    icon: Icon(
                      isOut ? Icons.close_rounded : Icons.swap_horiz_rounded,
                      color: isOut
                          ? AppColors.of(context).error
                          : AppColors.of(context).textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      if (isOut) {
                        setState(() => _pendingOuts.remove(pick.element));
                      } else {
                        _showReplacementSheet(
                          context,
                          player,
                          pick,
                          fplProvider,
                        );
                      }
                    },
                  ),
              ],
            ),
            if (isOut && incomingPlayer != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 46),
                  Icon(Icons.arrow_upward_rounded,
                      color: AppColors.of(context).primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${incomingPlayer.webName} · ${formatPrice(incomingPlayer.nowCost)}',
                    style: TextStyle(
                      color: AppColors.of(context).primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReplacementSheet(
    BuildContext context,
    Player outPlayer,
    EntryPick pick,
    FplProvider fplProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReplacementSheet(
        outPlayer: outPlayer,
        pick: pick,
        fplProvider: fplProvider,
        onSelect: (incomingPlayer) {
          setState(() {
            _pendingOuts[pick.element] = incomingPlayer.id;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _positionBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildModelNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardMedium,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.of(context).divider),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.of(context).textSecondary, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sell prices use the official FPL formula (half-profit, rounded down). Long-press a player to lock them.',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transfer Summary Bar ───────────────────────────────────────────────────────

class _TransferSummaryBar extends StatelessWidget {
  final int freeTransfers;
  final int pendingTransfers;
  final int hitPoints;
  final int bank;
  final int teamValue;

  const _TransferSummaryBar({
    required this.freeTransfers,
    required this.pendingTransfers,
    required this.hitPoints,
    required this.bank,
    required this.teamValue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasHit = hitPoints < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardDark,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          _Stat(
            label: 'Free Transfers',
            value: '$freeTransfers',
            color: colors.primary,
          ),
          _Stat(
            label: 'Transfers',
            value: '$pendingTransfers',
            color: pendingTransfers > freeTransfers
                ? colors.error
                : colors.textPrimary,
          ),
          _Stat(
            label: 'Hit Cost',
            value: hasHit ? '$hitPoints pts' : '0 pts',
            color: hasHit ? colors.error : colors.primary,
          ),
          _Stat(
            label: 'Bank',
            value: formatPrice(bank),
            color: colors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Replacement Picker Sheet ───────────────────────────────────────────────────

class _ReplacementSheet extends StatefulWidget {
  final Player outPlayer;
  final EntryPick pick;
  final FplProvider fplProvider;
  final void Function(Player) onSelect;

  const _ReplacementSheet({
    required this.outPlayer,
    required this.pick,
    required this.fplProvider,
    required this.onSelect,
  });

  @override
  State<_ReplacementSheet> createState() => _ReplacementSheetState();
}

class _ReplacementSheetState extends State<_ReplacementSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  String _sort = 'form';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Player> _getOptions() {
    final maxBudget = widget.pick.sellingPrice;
    var pool = widget.fplProvider.players
        .where((p) =>
            p.id != widget.outPlayer.id &&
            p.elementType == widget.outPlayer.elementType &&
            p.nowCost <= maxBudget)
        .toList();

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      pool = pool
          .where((p) =>
              p.webName.toLowerCase().contains(q) ||
              p.secondName.toLowerCase().contains(q))
          .toList();
    }

    switch (_sort) {
      case 'form':
        pool.sort((a, b) => b.formValue.compareTo(a.formValue));
        break;
      case 'pts':
        pool.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        break;
      case 'value':
        pool.sort((a, b) => b.valueSeasonValue.compareTo(a.valueSeasonValue));
        break;
      case 'price':
        pool.sort((a, b) => b.nowCost.compareTo(a.nowCost));
        break;
    }

    return pool.take(50).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final options = _getOptions();
    final maxBudget = widget.pick.sellingPrice;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Replace ${widget.outPlayer.webName}',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Budget: ${formatPrice(maxBudget)} · ${getPositionShort(widget.outPlayer.elementType)}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search players…',
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _SortChip(
                          label: 'Form',
                          value: 'form',
                          current: _sort,
                          onTap: () => setState(() => _sort = 'form'),
                        ),
                        _SortChip(
                          label: 'Points',
                          value: 'pts',
                          current: _sort,
                          onTap: () => setState(() => _sort = 'pts'),
                        ),
                        _SortChip(
                          label: 'Value',
                          value: 'value',
                          current: _sort,
                          onTap: () => setState(() => _sort = 'value'),
                        ),
                        _SortChip(
                          label: 'Price',
                          value: 'price',
                          current: _sort,
                          onTap: () => setState(() => _sort = 'price'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: options.length,
                itemBuilder: (_, i) => _ReplacementOption(
                  player: options[i],
                  fplProvider: widget.fplProvider,
                  onSelect: widget.onSelect,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == current;
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colors.primary.withAlpha(30) : colors.cardMedium,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? colors.primary : colors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? colors.primary : colors.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ReplacementOption extends StatelessWidget {
  final Player player;
  final FplProvider fplProvider;
  final void Function(Player) onSelect;

  const _ReplacementOption({
    required this.player,
    required this.fplProvider,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final team = fplProvider.getTeamById(player.teamId);
    final projectedPts = fplProvider.computePlayerScore(player);

    return GestureDetector(
      onTap: () => onSelect(player),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            CachedNetworkImage(
              imageUrl: player.photoUrl,
              width: 36,
              height: 36,
              imageBuilder: (_, img) => ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image(image: img, fit: BoxFit.cover),
              ),
              errorWidget: (_, __, ___) => CircleAvatar(
                radius: 18,
                backgroundColor: colors.cardMedium,
                child:
                    Icon(Icons.person, color: colors.textSecondary, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.webName,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${team?.shortName ?? ''} · ${formatPrice(player.nowCost)} · Form: ${player.form}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  player.totalPoints.toString(),
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'pts',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
