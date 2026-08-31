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
  // Slot layout:
  //   0        = Starting GK
  //   1-10     = Starting outfield (any position; grouped on pitch by player.elementType)
  //   11       = Bench GK
  //   12-14    = Bench outfield (any position)
  final List<Player?> _slots = List.filled(15, null);

  int? _captainIdx;
  int? _viceCaptainIdx;
  final _nameController = TextEditingController();
  bool _isSaving = false;

  // Auto-compute formation from current starting outfield players
  String get _autoFormation {
    final starters = _slots.sublist(1, 11).whereType<Player>().toList();
    final d = starters.where((p) => p.elementType == 2).length;
    final m = starters.where((p) => p.elementType == 3).length;
    final f = starters.where((p) => p.elementType == 4).length;
    if (d == 0 && m == 0 && f == 0) return '?-?-?';
    return '$d-$m-$f';
  }

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

  int get _spent => _slots.fold(0, (sum, p) => sum + (p?.nowCost ?? 0));

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

  // Slot 0 = starting GK, slot 11 = bench GK.
  // Slots 1-10 = any starting outfield, slots 12-14 = any bench outfield.
  int _positionForSlot(int slotIndex) {
    if (slotIndex == 0 || slotIndex == 11) return 1; // GK
    return 0; // any outfield
  }

  // Next empty slot for a given position in the starting XI (slots 0-10)
  int? _nextStartingSlot(int elementType) {
    if (elementType == 1) {
      return _slots[0] == null ? 0 : null;
    }
    for (int i = 1; i <= 10; i++) {
      if (_slots[i] == null) return i;
    }
    return null;
  }

  // Next empty slot for a given position on the bench (slots 11-14)
  int? _nextBenchSlot(int elementType) {
    if (elementType == 1) {
      return _slots[11] == null ? 11 : null;
    }
    for (int i = 12; i <= 14; i++) {
      if (_slots[i] == null) return i;
    }
    return null;
  }

  void _onSlotTap(int slotIndex, FplProvider fplProvider) {
    final pos = _positionForSlot(slotIndex);
    _showPlayerPicker(slotIndex, pos, fplProvider);
  }

  // Sub Out: move a starting outfield player to bench
  void _subOut(int startingSlotIndex) {
    final player = _slots[startingSlotIndex];
    if (player == null || startingSlotIndex < 1 || startingSlotIndex > 10) {
      return;
    }

    // Find empty bench outfield slot
    final emptyBenchSlot = _nextBenchSlot(player.elementType);
    if (emptyBenchSlot != null) {
      setState(() {
        _slots[emptyBenchSlot] = player;
        _slots[startingSlotIndex] = null;
        if (_captainIdx == startingSlotIndex) {
          _captainIdx = emptyBenchSlot;
        }
        if (_viceCaptainIdx == startingSlotIndex) {
          _viceCaptainIdx = emptyBenchSlot;
        }
      });
    } else {
      // All bench outfield slots full – ask which bench player to swap with
      _showSwapPicker(startingSlotIndex, benchToClear: true);
    }
  }

  // Sub In: move a bench outfield player to starting
  void _subIn(int benchSlotIndex) {
    final player = _slots[benchSlotIndex];
    if (player == null || benchSlotIndex < 12 || benchSlotIndex > 14) return;

    // Find empty starting outfield slot
    final emptyStartSlot = _nextStartingSlot(player.elementType);
    if (emptyStartSlot != null) {
      setState(() {
        _slots[emptyStartSlot] = player;
        _slots[benchSlotIndex] = null;
        if (_captainIdx == benchSlotIndex) _captainIdx = emptyStartSlot;
        if (_viceCaptainIdx == benchSlotIndex) _viceCaptainIdx = emptyStartSlot;
      });
    } else {
      // Starting XI is full – ask which starting player to swap with
      _showSwapPicker(benchSlotIndex, benchToClear: false);
    }
  }

  // Sub GK: swap starting GK and bench GK
  void _subGk() {
    final startGk = _slots[0];
    final benchGk = _slots[11];
    if (startGk == null && benchGk == null) return;
    setState(() {
      _slots[0] = benchGk;
      _slots[11] = startGk;
      if (_captainIdx == 0) {
        _captainIdx = 11;
      } else if (_captainIdx == 11) {
        _captainIdx = 0;
      }
      if (_viceCaptainIdx == 0) {
        _viceCaptainIdx = 11;
      } else if (_viceCaptainIdx == 11) {
        _viceCaptainIdx = 0;
      }
    });
  }

  void _showSwapPicker(int fromSlot, {required bool benchToClear}) {
    final fromPlayer = _slots[fromSlot]!;
    // If benchToClear=true: from is starting, pick bench outfield slot to swap with
    // If benchToClear=false: from is bench, pick starting outfield slot to swap with
    final swapSlots = benchToClear
        ? [12, 13, 14].where((i) => _slots[i] != null).toList()
        : List.generate(
            10,
            (i) => i + 1,
          ).where((i) => _slots[i] != null).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                benchToClear
                    ? 'Swap ${fromPlayer.webName} with bench player:'
                    : 'Swap ${fromPlayer.webName} with starting player:',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...swapSlots.map((toSlot) {
                final toPlayer = _slots[toSlot]!;
                final posColor = getPositionColor(toPlayer.elementType);
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.of(context).cardMedium,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      toPlayer.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.person),
                    ),
                  ),
                  title: Text(
                    toPlayer.webName,
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${PositionConstants.positionNames[toPlayer.elementType] ?? ''} · ${formatPrice(toPlayer.nowCost)}',
                    style: TextStyle(color: posColor, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _slots[toSlot] = fromPlayer;
                      _slots[fromSlot] = toPlayer;
                      if (_captainIdx == fromSlot) {
                        _captainIdx = toSlot;
                      } else if (_captainIdx == toSlot) {
                        _captainIdx = fromSlot;
                      }
                      if (_viceCaptainIdx == fromSlot) {
                        _viceCaptainIdx = toSlot;
                      } else if (_viceCaptainIdx == toSlot) {
                        _viceCaptainIdx = fromSlot;
                      }
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlayerPicker(int slotIndex, int position, FplProvider fplProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlayerPickerSheet(
        position: position,
        remaining:
            _remaining +
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
      backgroundColor: AppColors.of(context).cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SlotOptionsSheet(
        player: _slots[slotIndex]!,
        slotIndex: slotIndex,
        isCaptain: _captainIdx == slotIndex,
        isViceCaptain: _viceCaptainIdx == slotIndex,
        isStartingOutfield: slotIndex >= 1 && slotIndex <= 10,
        isBenchOutfield: slotIndex >= 12 && slotIndex <= 14,
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
        onSubOut: () {
          Navigator.pop(context);
          _subOut(slotIndex);
        },
        onSubIn: () {
          Navigator.pop(context);
          _subIn(slotIndex);
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
    final filledSlots = _slots
        .asMap()
        .entries
        .where((e) => e.value != null)
        .toList();
    if (filledSlots.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all 11 starting positions first.'),
          backgroundColor: AppColors.of(context).error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final slots = _slots
          .asMap()
          .entries
          .map((e) {
            final p = e.value;
            if (p == null) return null;
            return UserTeamSlot(
              playerId: p.id,
              isStarting: e.key < 11,
              slotIndex: e.key,
            );
          })
          .whereType<UserTeamSlot>()
          .toList();

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
        formation: _autoFormation,
        createdAt: widget.existingTeam?.createdAt ?? DateTime.now(),
      );

      final provider = context.read<UserTeamsProvider>();
      if (widget.existingTeam != null) {
        await provider.updateTeam(team);
      } else {
        await provider.addTeam(team);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Team "${team.name}" saved!'),
            backgroundColor: AppColors.of(context).primary.withAlpha(200),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, fplProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            backgroundColor: AppColors.of(context).secondary,
            title: SizedBox(
              height: 40,
              child: TextField(
                controller: _nameController,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: 'Team Name',
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            actions: [
              // Formation badge (auto-computed, read-only)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.of(context).primary.withAlpha(80),
                  ),
                ),
                child: Text(
                  _autoFormation,
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: _isSaving ? null : _saveTeam,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          color: AppColors.of(context).primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
      },
    );
  }

  Widget _buildBudgetBar() {
    final pct = (_remaining / _kBudget).clamp(0.0, 1.0);
    final color = _remaining < 0
        ? AppColors.of(context).error
        : _remaining < 50
        ? AppColors.of(context).warning
        : AppColors.of(context).primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    Text(
                      'Budget Remaining',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      formatPrice(_remaining),
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withAlpha(25),
                    color: color,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Spent',
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                formatPrice(_spent),
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPitch(FplProvider fplProvider) {
    // Group starting slots (1-10) by player position
    final fwdSlots = <int>[];
    final midSlots = <int>[];
    final defSlots = <int>[];
    // Empty outfield slots – display in their own "empty" row
    final emptyOutfieldSlots = <int>[];

    for (int i = 1; i <= 10; i++) {
      final p = _slots[i];
      if (p == null) {
        emptyOutfieldSlots.add(i);
      } else {
        switch (p.elementType) {
          case 4:
            fwdSlots.add(i);
          case 3:
            midSlots.add(i);
          default:
            defSlots.add(i);
        }
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.of(context).pitchGreen,
            AppColors.of(context).pitchGreenDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.of(context).primary.withAlpha(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          if (fwdSlots.isNotEmpty)
            _buildPitchRow(
              fwdSlots,
              fplProvider,
              PositionConstants.positionColors[4]!,
            ),
          if (fwdSlots.isNotEmpty && midSlots.isNotEmpty)
            const SizedBox(height: 10),
          if (midSlots.isNotEmpty)
            _buildPitchRow(
              midSlots,
              fplProvider,
              PositionConstants.positionColors[3]!,
            ),
          if (midSlots.isNotEmpty && defSlots.isNotEmpty)
            const SizedBox(height: 10),
          if (defSlots.isNotEmpty)
            _buildPitchRow(
              defSlots,
              fplProvider,
              PositionConstants.positionColors[2]!,
            ),
          if (defSlots.isNotEmpty) const SizedBox(height: 10),
          _buildPitchRow(
            [0],
            fplProvider,
            PositionConstants.positionColors[1]!,
          ),
          const SizedBox(height: 14),
          // Dividing line
          Container(
            width: double.infinity,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          // Empty slots hint
          if (emptyOutfieldSlots.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppColors.of(context).textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tap a slot to add a player  •  ${emptyOutfieldSlots.length} outfield slot${emptyOutfieldSlots.length == 1 ? '' : 's'} remaining',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildEmptyOutfieldRow(emptyOutfieldSlots, fplProvider),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildPitchRow(
    List<int> slotIndices,
    FplProvider fplProvider,
    Color posColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth / slotIndices.length).clamp(
          60.0,
          84.0,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: slotIndices.map((idx) {
            final player = _slots[idx];
            return SizedBox(
              width: itemWidth,
              child: _BuilderSlot(
                player: player,
                posColor: posColor,
                posLabel: player == null
                    ? (idx == 0 ? 'GK' : 'ADD')
                    : (PositionConstants.positionNames[player.elementType] ??
                          ''),
                isCaptain: _captainIdx == idx,
                isViceCaptain: _viceCaptainIdx == idx,
                isStartingOutfield: idx >= 1 && idx <= 10,
                onTap: () => _onSlotTap(idx, fplProvider),
                onLongPress: () => _onSlotLongPress(idx),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyOutfieldRow(List<int> emptySlots, FplProvider fplProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = emptySlots.length.clamp(1, 5);
        final itemWidth = (constraints.maxWidth / count).clamp(60.0, 84.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emptySlots.take(5).map((idx) {
            return SizedBox(
              width: itemWidth,
              child: _BuilderSlot(
                player: null,
                posColor: AppColors.of(context).textSecondary,
                posLabel: 'ADD',
                onTap: () => _onSlotTap(idx, fplProvider),
                onLongPress: () {},
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBench(FplProvider fplProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_vert_rounded,
                color: AppColors.of(context).textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Substitutes',
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // GK sub button
              if (_slots[0] != null || _slots[11] != null)
                GestureDetector(
                  onTap: _subGk,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.of(context).primary.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_vert_rounded,
                          color: AppColors.of(context).primary,
                          size: 12,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'GK Swap',
                          style: TextStyle(
                            color: AppColors.of(context).primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth / 4).clamp(60.0, 84.0);
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
                          : AppColors.of(context).textSecondary,
                      posLabel: idx == 11
                          ? 'GK'
                          : (player != null
                                ? (PositionConstants.positionNames[player
                                          .elementType] ??
                                      'OUT')
                                : 'OUT'),
                      isSub: true,
                      isBenchOutfield: idx >= 12,
                      onTap: () => _onSlotTap(idx, fplProvider),
                      onLongPress: () => _onSlotLongPress(idx),
                    ),
                  );
                }).toList(),
              );
            },
          ),
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
  final bool isStartingOutfield;
  final bool isBenchOutfield;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BuilderSlot({
    required this.player,
    required this.posColor,
    required this.posLabel,
    this.isSub = false,
    this.isCaptain = false,
    this.isViceCaptain = false,
    this.isStartingOutfield = false,
    this.isBenchOutfield = false,
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
                  borderRadius: BorderRadius.circular(8),
                  color: player != null
                      ? AppColors.of(context).cardDark
                      : AppColors.of(context).cardDark.withAlpha(180),
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
                        placeholder: (_, _) => Icon(
                          Icons.person,
                          color: AppColors.of(context).textSecondary,
                          size: size * 0.5,
                        ),
                        errorWidget: (_, _, _) => Icon(
                          Icons.person,
                          color: AppColors.of(context).textSecondary,
                          size: size * 0.5,
                        ),
                      )
                    : Icon(
                        Icons.add,
                        color: posColor.withAlpha(180),
                        size: size * 0.45,
                      ),
              ),
              if (isCaptain)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.of(context).warning,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.of(context).secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isViceCaptain)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.of(context).accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'V',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.of(context).secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              // Sub-out badge on starting outfield players
              if (player != null && isStartingOutfield)
                Positioned(
                  bottom: -2,
                  left: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.of(context).accent.withAlpha(220),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Sub-in badge on bench outfield players
              if (player != null && isBenchOutfield)
                Positioned(
                  bottom: -2,
                  left: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.of(context).primary.withAlpha(220),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 9,
                        color: AppColors.of(context).secondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          if (player != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(4),
              ),
              constraints: const BoxConstraints(maxWidth: 72),
              child: Text(
                player!.webName.length > 9
                    ? player!.webName.substring(
                        0,
                        player!.webName.length.clamp(0, 8),
                      )
                    : player!.webName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.of(context).primary.withAlpha(200),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                formatPrice(player!.nowCost),
                style: TextStyle(
                  color: AppColors.of(context).secondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: posColor.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                posLabel,
                style: TextStyle(
                  color: posColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
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
      if (widget.position == 0 && p.elementType == 1) {
        return false; // no GK for outfield bench
      }
      if (p.nowCost > widget.remaining) return false;
      if ((widget.teamCounts[p.teamId] ?? 0) >= 3) return false;
      return true;
    }).toList();

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      players = players
          .where(
            (p) =>
                p.webName.toLowerCase().contains(q) ||
                p.firstName.toLowerCase().contains(q) ||
                p.secondName.toLowerCase().contains(q),
          )
          .toList();
    }

    switch (_sort) {
      case 'price':
        players.sort((a, b) => b.nowCost.compareTo(a.nowCost));
      case 'form':
        players.sort((a, b) => b.formValue.compareTo(a.formValue));
      default:
        players.sort(
          (a, b) => widget.fplProvider
              .computePlayerScore(b)
              .compareTo(widget.fplProvider.computePlayerScore(a)),
        );
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
        decoration: BoxDecoration(
          color: AppColors.of(context).cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Pick $posName',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Budget: ${formatPrice(widget.remaining)}',
                    style: TextStyle(
                      color: AppColors.of(context).primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.of(context).textSecondary,
                            size: 18,
                          ),
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
            Divider(height: 1, color: AppColors.of(context).divider),
            Expanded(
              child: candidates.isEmpty
                  ? Center(
                      child: Text(
                        'No players match filters',
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: candidates.length,
                      itemBuilder: (_, i) => _PickerPlayerRow(
                        player: candidates[i],
                        team: widget.fplProvider.getTeamById(
                          candidates[i].teamId,
                        ),
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
              ? AppColors.of(context).primary.withAlpha(51)
              : AppColors.of(context).cardMedium,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.of(context).primary
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.of(context).primary
                : AppColors.of(context).textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PickerPlayerRow extends StatelessWidget {
  final Player player;
  final dynamic team;
  final VoidCallback onTap;

  const _PickerPlayerRow({
    required this.player,
    required this.team,
    required this.onTap,
  });

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
                borderRadius: BorderRadius.circular(8),
                color: AppColors.of(context).cardMedium,
                border: Border.all(color: posColor, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: player.photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => Icon(
                  Icons.person,
                  color: AppColors.of(context).textSecondary,
                  size: 20,
                ),
                errorWidget: (_, _, _) => Icon(
                  Icons.person,
                  color: AppColors.of(context).textSecondary,
                  size: 20,
                ),
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
                        child: Text(
                          player.webName,
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        team?.shortName ?? '',
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPrice(player.nowCost),
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Form: ${player.form}',
                  style: TextStyle(
                    color: AppColors.of(context).accent,
                    fontSize: 11,
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

// ─── Slot Options Bottom Sheet ────────────────────────────────────────────────

class _SlotOptionsSheet extends StatelessWidget {
  final Player player;
  final int slotIndex;
  final bool isCaptain;
  final bool isViceCaptain;
  final bool isStartingOutfield;
  final bool isBenchOutfield;
  final VoidCallback onSetCaptain;
  final VoidCallback onSetViceCaptain;
  final VoidCallback onSubOut;
  final VoidCallback onSubIn;
  final VoidCallback onRemove;

  const _SlotOptionsSheet({
    required this.player,
    required this.slotIndex,
    required this.isCaptain,
    required this.isViceCaptain,
    this.isStartingOutfield = false,
    this.isBenchOutfield = false,
    required this.onSetCaptain,
    required this.onSetViceCaptain,
    required this.onSubOut,
    required this.onSubIn,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final posColor = getPositionColor(player.elementType);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.of(context).divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.of(context).cardMedium,
                    border: Border.all(color: posColor, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: player.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const Icon(Icons.person, size: 22),
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.person, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.webName,
                        style: TextStyle(
                          color: AppColors.of(context).textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${PositionConstants.positionNames[player.elementType] ?? ''} · ${formatPrice(player.nowCost)}',
                        style: TextStyle(color: posColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.of(context).divider),
            const SizedBox(height: 4),
            // Sub Out (starting outfield only)
            if (isStartingOutfield)
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  'Sub Out  →  Move to Bench',
                  style: TextStyle(color: AppColors.of(context).accent),
                ),
                subtitle: Text(
                  'Send to substitutes',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 11,
                  ),
                ),
                onTap: onSubOut,
              ),
            // Sub In (bench outfield only)
            if (isBenchOutfield)
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: AppColors.of(context).secondary,
                    size: 16,
                  ),
                ),
                title: Text(
                  'Sub In  →  Move to Starting',
                  style: TextStyle(color: AppColors.of(context).primary),
                ),
                subtitle: Text(
                  'Bring into starting XI',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 11,
                  ),
                ),
                onTap: onSubIn,
              ),
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.of(context).warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'C',
                    style: TextStyle(
                      color: AppColors.of(context).secondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              title: Text(
                isCaptain ? 'Captain (already set)' : 'Set as Captain',
                style: TextStyle(
                  color: isCaptain
                      ? AppColors.of(context).textSecondary
                      : AppColors.of(context).textPrimary,
                ),
              ),
              onTap: isCaptain ? null : onSetCaptain,
            ),
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.of(context).accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      color: AppColors.of(context).secondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              title: Text(
                isViceCaptain
                    ? 'Vice-Captain (already set)'
                    : 'Set as Vice-Captain',
                style: TextStyle(
                  color: isViceCaptain
                      ? AppColors.of(context).textSecondary
                      : AppColors.of(context).textPrimary,
                ),
              ),
              onTap: isViceCaptain ? null : onSetViceCaptain,
            ),
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.of(context).error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.remove, color: Colors.white, size: 16),
              ),
              title: Text(
                'Remove Player',
                style: TextStyle(color: AppColors.of(context).error),
              ),
              onTap: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
