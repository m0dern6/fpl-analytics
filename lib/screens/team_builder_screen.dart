import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/fpl_provider.dart';
import '../providers/user_teams_provider.dart';
import '../models/player.dart';
import '../models/user_team.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/loading_widget.dart';

const int _kBudget = 1000; // £100.0m in tenths

class TeamBuilderScreen extends StatefulWidget {
  final UserTeam? existingTeam;

  const TeamBuilderScreen({super.key, this.existingTeam});

  @override
  State<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}

class _TeamBuilderScreenState extends State<TeamBuilderScreen> {
  // Null means slot is empty; index 0–10 = starting, 11–14 = bench
  final List<Player?> _slots = List.filled(15, null);
  // position requirement per slot index
  // 0 = GK, 1-4 = DEF, 5-8 = MID, 9-10 = FWD  (for 4-4-2 base)
  // We track by position counts dynamically instead.

  String _formation = '4-3-3';
  int? _captainIdx;
  int? _viceCaptainIdx;
  final _nameController = TextEditingController();
  bool _isSaving = false;

  // Formation configs: [def, mid, fwd]
  static const Map<String, List<int>> _formations = {
    '4-3-3': [4, 3, 3],
    '4-4-2': [4, 4, 2],
    '3-5-2': [3, 5, 2],
    '5-3-2': [5, 3, 2],
    '3-4-3': [3, 4, 3],
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingTeam != null) {
      _loadExistingTeam();
    } else {
      _nameController.text = 'My Team';
    }
  }

  void _loadExistingTeam() {
    final team = widget.existingTeam!;
    _nameController.text = team.name;
    _formation = team.formation;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fplProvider = context.read<FplProvider>();
      for (final slot in team.slots) {
        final player = fplProvider.getPlayerById(slot.playerId);
        if (player != null && slot.slotIndex < 15) {
          setState(() {
            _slots[slot.slotIndex] = player;
            if (slot.playerId == team.captainId) {
              _captainIdx = slot.slotIndex;
            }
            if (slot.playerId == team.viceCaptainId) {
              _viceCaptainIdx = slot.slotIndex;
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _spent =>
      _slots.fold(0, (sum, p) => sum + (p?.nowCost ?? 0));

  int get _remaining => _kBudget - _spent;

  Set<int> get _pickedIds =>
      _slots.whereType<Player>().map((p) => p.id).toSet();

  Map<int, int> get _teamCounts {
    final counts = <int, int>{};
    for (final p in _slots.whereType<Player>()) {
      counts[p.teamId] = (counts[p.teamId] ?? 0) + 1;
    }
    return counts;
  }

  int _positionForSlot(int slotIndex) {
    if (slotIndex == 0) return 1; // GK starting
    if (slotIndex == 11) return 1; // GK bench
    final parts = _formations[_formation] ?? [4, 3, 3];
    final defCount = parts[0];
    final midCount = parts[1];
    final fwdCount = parts[2];
    if (slotIndex >= 1 && slotIndex < 1 + defCount) return 2;
    if (slotIndex >= 1 + defCount && slotIndex < 1 + defCount + midCount) {
      return 3;
    }
    if (slotIndex >= 1 + defCount + midCount &&
        slotIndex < 1 + defCount + midCount + fwdCount) return 4;
    // bench slots 12-14: any outfield
    return 0; // any outfield
  }

  String _posLabelForSlot(int slotIndex) {
    final pos = _positionForSlot(slotIndex);
    return PositionConstants.positionNames[pos] ?? 'ANY';
  }

  void _onSlotTap(int slotIndex, FplProvider fplProvider) {
    final pos = _positionForSlot(slotIndex);
    _showPlayerPicker(slotIndex, pos, fplProvider);
  }

  void _showPlayerPicker(
      int slotIndex, int position, FplProvider fplProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlayerPickerSheet(
        position: position,
        remaining: _remaining +
            (_slots[slotIndex]?.nowCost ?? 0), // free up current player cost
        pickedIds: _pickedIds
          ..remove(_slots[slotIndex]?.id), // allow re-picking same slot
        teamCounts: Map.from(_teamCounts)
          ..update(
            _slots[slotIndex]?.teamId ?? -1,
            (v) => v - 1,
            ifAbsent: () => 0,
          ),
        fplProvider: fplProvider,
        onSelected: (player) {
          setState(() {
            _slots[slotIndex] = player;
            // reset captain/vc if removed
            if (_captainIdx == slotIndex && player == null) {
              _captainIdx = null;
            }
            if (_viceCaptainIdx == slotIndex && player == null) {
              _viceCaptainIdx = null;
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onSlotLongPress(int slotIndex) {
    if (_slots[slotIndex] == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SlotOptionsSheet(
        player: _slots[slotIndex]!,
        isCaptain: _captainIdx == slotIndex,
        isViceCaptain: _viceCaptainIdx == slotIndex,
        onSetCaptain: () {
          setState(() {
            _captainIdx = slotIndex;
            if (_viceCaptainIdx == slotIndex) _viceCaptainIdx = null;
          });
          Navigator.pop(context);
        },
        onSetViceCaptain: () {
          setState(() {
            _viceCaptainIdx = slotIndex;
            if (_captainIdx == slotIndex) _captainIdx = null;
          });
          Navigator.pop(context);
        },
        onRemove: () {
          setState(() {
            if (_captainIdx == slotIndex) _captainIdx = null;
            if (_viceCaptainIdx == slotIndex) _viceCaptainIdx = null;
            _slots[slotIndex] = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _saveTeam() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameController.text = 'My Team';
    }
    final filledSlots =
        _slots.asMap().entries.where((e) => e.value != null).toList();
    if (filledSlots.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill all 11 starting positions first.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final slots = _slots.asMap().entries.map((e) {
        final p = e.value;
        if (p == null) return null;
        return UserTeamSlot(
          playerId: p.id,
          isStarting: e.key < 11,
          slotIndex: e.key,
        );
      }).whereType<UserTeamSlot>().toList();

      final captainId = _captainIdx != null
          ? (_slots[_captainIdx!]?.id ?? 0)
          : (filledSlots.isNotEmpty ? filledSlots.first.value!.id : 0);
      final vcId = _viceCaptainIdx != null
          ? (_slots[_viceCaptainIdx!]?.id ?? 0)
          : 0;

      final team = UserTeam(
        id: widget.existingTeam?.id ?? '',
        name: _nameController.text.trim().isEmpty
            ? 'My Team'
            : _nameController.text.trim(),
        slots: slots,
        captainId: captainId,
        viceCaptainId: vcId,
        formation: _formation,
        createdAt: widget.existingTeam?.createdAt ?? DateTime.now(),
      );

      final provider = context.read<UserTeamsProvider>();
      if (widget.existingTeam != null) {
        await provider.updateTeam(team);
      } else {
        await provider.addTeam(team);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Team "${team.name}" saved!'),
          backgroundColor: AppColors.primary.withAlpha(200),
        ));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(builder: (context, fplProvider, _) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          title: SizedBox(
            height: 40,
            child: TextField(
              controller: _nameController,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Team Name',
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.tune, color: AppColors.textPrimary),
              color: AppColors.cardDark,
              onSelected: (f) => setState(() => _formation = f),
              itemBuilder: (_) => _formations.keys
                  .map((f) => PopupMenuItem(
                        value: f,
                        child: Text(f,
                            style: TextStyle(
                                color: _formation == f
                                    ? AppColors.primary
                                    : AppColors.textPrimary)),
                      ))
                  .toList(),
            ),
            TextButton(
              onPressed: _isSaving ? null : _saveTeam,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        body: fplProvider.isLoading
            ? const LoadingListWidget()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildBudgetBar(),
                    _buildPitch(fplProvider),
                    _buildBench(fplProvider),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      );
    });
  }

  Widget _buildBudgetBar() {
    final pct = (_remaining / _kBudget).clamp(0.0, 1.0);
    final color = _remaining < 0
        ? AppColors.error
        : _remaining < 50
            ? AppColors.warning
            : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: AppTheme.purpleGradient(borderRadius: BorderRadius.zero),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Budget Remaining',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    Text(formatPrice(_remaining),
                        style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withAlpha(30),
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Spent',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              Text(formatPrice(_spent),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPitch(FplProvider fplProvider) {
    final parts = _formations[_formation] ?? [4, 3, 3];
    final defCount = parts[0];
    final midCount = parts[1];
    final fwdCount = parts[2];

    // starting slots: 0=GK, 1..defCount=DEF, ..mid..=MID, ..fwd..=FWD
    final gkSlots = [0];
    final defSlots = List.generate(defCount, (i) => 1 + i);
    final midSlots = List.generate(midCount, (i) => 1 + defCount + i);
    final fwdSlots = List.generate(fwdCount, (i) => 1 + defCount + midCount + i);

    return Container(
      margin: const EdgeInsets.all(12),
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
          const SizedBox(height: 12),
          _buildPitchRow(fwdSlots, fplProvider, PositionConstants.positionColors[4]!),
          const SizedBox(height: 10),
          _buildPitchRow(midSlots, fplProvider, PositionConstants.positionColors[3]!),
          const SizedBox(height: 10),
          _buildPitchRow(defSlots, fplProvider, PositionConstants.positionColors[2]!),
          const SizedBox(height: 10),
          _buildPitchRow(gkSlots, fplProvider, PositionConstants.positionColors[1]!),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPitchRow(
      List<int> slotIndices, FplProvider fplProvider, Color posColor) {
    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth / slotIndices.length).clamp(60.0, 80.0);
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: slotIndices.map((idx) {
          final player = _slots[idx];
          return SizedBox(
            width: itemWidth,
            child: _BuilderSlot(
              player: player,
              posColor: posColor,
              posLabel: _posLabelForSlot(idx),
              isCaptain: _captainIdx == idx,
              isViceCaptain: _viceCaptainIdx == idx,
              onTap: () => _onSlotTap(idx, fplProvider),
              onLongPress: () => _onSlotLongPress(idx),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildBench(FplProvider fplProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
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
            final itemWidth = (constraints.maxWidth / 4).clamp(60.0, 80.0);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [11, 12, 13, 14].map((idx) {
                final player = _slots[idx];
                return SizedBox(
                  width: itemWidth,
                  child: _BuilderSlot(
                    player: player,
                    posColor: player != null
                        ? getPositionColor(player.elementType)
                        : AppColors.textSecondary,
                    posLabel: idx == 11 ? 'GK' : 'OUT',
                    isSub: true,
                    onTap: () => _onSlotTap(idx, fplProvider),
                    onLongPress: () => _onSlotLongPress(idx),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Pitch Slot Widget ────────────────────────────────────────────────────────

class _BuilderSlot extends StatelessWidget {
  final Player? player;
  final Color posColor;
  final String posLabel;
  final bool isSub;
  final bool isCaptain;
  final bool isViceCaptain;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BuilderSlot({
    required this.player,
    required this.posColor,
    required this.posLabel,
    this.isSub = false,
    this.isCaptain = false,
    this.isViceCaptain = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSub ? 44.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
                  color: player != null
                      ? AppColors.cardDark
                      : AppColors.cardDark.withAlpha(180),
                  border: Border.all(
                    color: player != null ? posColor : posColor.withAlpha(100),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: player != null
                    ? CachedNetworkImage(
                        imageUrl: player!.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Icon(Icons.person,
                            color: AppColors.textSecondary,
                            size: size * 0.5),
                        errorWidget: (_, __, ___) => Icon(Icons.person,
                            color: AppColors.textSecondary,
                            size: size * 0.5),
                      )
                    : Icon(Icons.add,
                        color: posColor.withAlpha(180), size: size * 0.45),
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
          if (player != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153),
                borderRadius: BorderRadius.circular(4),
              ),
              constraints: const BoxConstraints(maxWidth: 72),
              child: Text(
                player!.webName.length > 9
                    ? player!.webName.substring(0, 8)
                    : player!.webName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(204),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                formatPrice(player!.nowCost),
                style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ] else ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: posColor.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                posLabel,
                style: TextStyle(
                    color: posColor, fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Player Picker Bottom Sheet ───────────────────────────────────────────────

class _PlayerPickerSheet extends StatefulWidget {
  final int position; // 0 = any outfield
  final int remaining;
  final Set<int> pickedIds;
  final Map<int, int> teamCounts;
  final FplProvider fplProvider;
  final void Function(Player?) onSelected;

  const _PlayerPickerSheet({
    required this.position,
    required this.remaining,
    required this.pickedIds,
    required this.teamCounts,
    required this.fplProvider,
    required this.onSelected,
  });

  @override
  State<_PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<_PlayerPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _sort = 'score'; // 'score', 'price', 'form'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Player> get _candidates {
    var players = widget.fplProvider.players.where((p) {
      if (widget.pickedIds.contains(p.id)) return false;
      if (widget.position != 0 && p.elementType != widget.position) {
        return false;
      }
      if (widget.position == 0 && p.elementType == 1) return false; // no GK for outfield bench
      if (p.nowCost > widget.remaining) return false;
      if ((widget.teamCounts[p.teamId] ?? 0) >= 3) return false;
      return true;
    }).toList();

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      players = players
          .where((p) =>
              p.webName.toLowerCase().contains(q) ||
              p.firstName.toLowerCase().contains(q) ||
              p.secondName.toLowerCase().contains(q))
          .toList();
    }

    switch (_sort) {
      case 'price':
        players.sort((a, b) => b.nowCost.compareTo(a.nowCost));
      case 'form':
        players.sort((a, b) => b.formValue.compareTo(a.formValue));
      default:
        players.sort((a, b) => widget.fplProvider
            .computePlayerScore(b)
            .compareTo(widget.fplProvider.computePlayerScore(a)));
    }
    return players;
  }

  @override
  Widget build(BuildContext context) {
    final posName = widget.position == 0
        ? 'Outfield'
        : (PositionConstants.positionFullNames[widget.position] ?? 'Player');
    final candidates = _candidates;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text('Pick $posName',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('Budget: ${formatPrice(widget.remaining)}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _sortChip('score', 'Smart Score'),
                  const SizedBox(width: 8),
                  _sortChip('form', 'Form'),
                  const SizedBox(width: 8),
                  _sortChip('price', 'Price'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: candidates.isEmpty
                  ? const Center(
                      child: Text('No players match filters',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: candidates.length,
                      itemBuilder: (_, i) =>
                          _PickerPlayerRow(
                            player: candidates[i],
                            team: widget.fplProvider
                                .getTeamById(candidates[i].teamId),
                            onTap: () => widget.onSelected(candidates[i]),
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String value, String label) {
    final selected = _sort == value;
    return GestureDetector(
      onTap: () => setState(() => _sort = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(51)
              : AppColors.cardMedium,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _PickerPlayerRow extends StatelessWidget {
  final Player player;
  final dynamic team;
  final VoidCallback onTap;

  const _PickerPlayerRow(
      {required this.player, required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final posColor = getPositionColor(player.elementType);
    final statusColor = getStatusColor(player.status);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardMedium,
                border: Border.all(color: posColor, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: player.photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Icon(Icons.person,
                    color: AppColors.textSecondary, size: 20),
                errorWidget: (_, __, ___) => const Icon(Icons.person,
                    color: AppColors.textSecondary, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(player.webName,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: posColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                            PositionConstants.positionNames[player.elementType] ??
                                '',
                            style: TextStyle(
                                color: posColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 4),
                      Text(team?.shortName ?? '',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatPrice(player.nowCost),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text('Form: ${player.form}',
                    style: const TextStyle(
                        color: AppColors.accent, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slot Options Bottom Sheet ────────────────────────────────────────────────

class _SlotOptionsSheet extends StatelessWidget {
  final Player player;
  final bool isCaptain;
  final bool isViceCaptain;
  final VoidCallback onSetCaptain;
  final VoidCallback onSetViceCaptain;
  final VoidCallback onRemove;

  const _SlotOptionsSheet({
    required this.player,
    required this.isCaptain,
    required this.isViceCaptain,
    required this.onSetCaptain,
    required this.onSetViceCaptain,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(player.webName,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(formatPrice(player.nowCost),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.warning,
                radius: 16,
                child: Text('C',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ),
              title: Text(
                  isCaptain ? 'Captain (already set)' : 'Set as Captain',
                  style: TextStyle(
                      color: isCaptain
                          ? AppColors.textSecondary
                          : AppColors.textPrimary)),
              onTap: isCaptain ? null : onSetCaptain,
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.accent,
                radius: 16,
                child: Text('V',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ),
              title: Text(
                  isViceCaptain
                      ? 'Vice-Captain (already set)'
                      : 'Set as Vice-Captain',
                  style: TextStyle(
                      color: isViceCaptain
                          ? AppColors.textSecondary
                          : AppColors.textPrimary)),
              onTap: isViceCaptain ? null : onSetViceCaptain,
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.error,
                radius: 16,
                child: Icon(Icons.remove, color: Colors.white, size: 16),
              ),
              title: const Text('Remove Player',
                  style: TextStyle(color: AppColors.error)),
              onTap: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
