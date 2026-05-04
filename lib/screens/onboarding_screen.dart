import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/fpl_entry_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';

/// Onboarding / team linking screen.
/// Shown to users who haven't linked their FPL entry.
/// Also accessible from settings to add/switch profiles.
class OnboardingScreen extends StatefulWidget {
  /// If true, shows as a modal sheet (e.g. to add another profile).
  final bool isModal;

  const OnboardingScreen({super.key, this.isModal = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _linkTeam() async {
    if (!_formKey.currentState!.validate()) return;
    final id = int.tryParse(_controller.text.trim());
    if (id == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final provider = context.read<FplEntryProvider>();
    final success = await provider.loadEntry(id, forceRefresh: true);

    if (!mounted) return;

    if (success) {
      if (widget.isModal) {
        Navigator.of(context).pop(true);
      }
      // If not modal, the parent widget will update its state automatically
    } else {
      setState(() {
        _error = provider.error ?? 'Failed to load team. Check your Entry ID.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: widget.isModal
          ? AppBar(
              backgroundColor: colors.secondary,
              title: const Text('Add Team'),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isModal) ...[
                const SizedBox(height: 24),
                _buildHeroSection(colors),
                const SizedBox(height: 40),
              ],
              _buildFormSection(colors),
              const SizedBox(height: 32),
              _buildHowToFindSection(colors),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00E5A0), Color(0xFF00A87A)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5A0).withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'FPL',
              style: TextStyle(
                color: Color(0xFF0C0720),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'FPL Analytics',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Link your team to unlock live points, transfer tools, league standings, and more.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your FPL Entry ID',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. 1234567',
              prefixIcon: Icon(
                Icons.badge_rounded,
                color: colors.textSecondary,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: colors.textSecondary),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your Entry ID';
              final n = int.tryParse(v);
              if (n == null || n <= 0) return 'Enter a valid numeric Entry ID';
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.error.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: colors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: colors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _loading ? null : _linkTeam,
            child: _loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.secondary,
                    ),
                  )
                : const Text(
                    'Link My Team',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Guest mode button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colors.textSecondary,
            ),
            onPressed: () {
              if (widget.isModal) {
                Navigator.pop(context);
              }
              // Simply skip — app will work in browse mode
            },
            child: Text(
              'Browse without linking',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHowToFindSection(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  color: colors.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'How to find your Entry ID',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._steps(colors),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.cardDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'fantasy.premierleague.com/entry/YOUR_ID/event/1/picks',
              style: TextStyle(
                color: colors.primary,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your data is only read from the official FPL API and stored locally on your device.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _steps(AppColors colors) {
    final steps = [
      'Log in to the official FPL website or app.',
      'Go to "My Team" or "Points" page.',
      'Look at the URL — the number after /entry/ is your Entry ID.',
      'Or go to Gameweek History — the ID appears in the URL.',
    ];
    return steps
        .asMap()
        .entries
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8, top: 1),
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
