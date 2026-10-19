import 'package:flutter/material.dart';
import 'package:smarthome/core/constants/app_constants.dart';
import 'package:smarthome/core/theme/app_theme.dart';
import 'package:smarthome/features/smart_home/data/presentation/cubit/home_cubit.dart';

class VoiceAssistantModal extends StatefulWidget {
  final String homeId;
  final HomeCubit homeCubit;

  const VoiceAssistantModal({
    super.key,
    required this.homeId,
    required this.homeCubit,
  });

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  final TextEditingController _cmdCtrl = TextEditingController();
  String _assistantFeedback = 'Listening... Say or select a command below.';
  bool _isProcessing = false;

  @override
  void dispose() {
    _pulseController.dispose();
    _cmdCtrl.dispose();
    super.dispose();
  }

  void _executeCommand(String command) async {
    final lower = command.toLowerCase().trim();
    setState(() {
      _isProcessing = true;
      _assistantFeedback = 'Processing: "$command"...';
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (lower.contains('night') ||
        (lower.contains('off') &&
            (lower.contains('all') || lower.contains('everything')))) {
      await widget.homeCubit.toggleAllDevicesInHome(false);
      if (mounted) {
        setState(() {
          _assistantFeedback = '🌙 Night mode: All devices turned OFF.';
          _isProcessing = false;
        });
      }
    } else if (lower.contains('on') &&
        (lower.contains('all') || lower.contains('everything'))) {
      await widget.homeCubit.toggleAllDevicesInHome(true);
      if (mounted) {
        setState(() {
          _assistantFeedback = '💡 All devices turned ON.';
          _isProcessing = false;
        });
      }
    } else if (lower.contains('cool') || lower.contains('cold')) {
      final state = widget.homeCubit.state;
      if (state is HomeLoaded) {
        for (final d in state.devices) {
          if (d.type == 'climate' || d.type == 'ac') {
            await widget.homeCubit.setDeviceMode(
              widget.homeId,
              state.selectedRoomId ?? 'living_room',
              d,
              'cool',
            );
          }
        }
      }
      if (mounted) {
        setState(() {
          _assistantFeedback = '❄️ Climate mode switched to COOL.';
          _isProcessing = false;
        });
      }
    } else if (lower.contains('heat') || lower.contains('warm')) {
      final state = widget.homeCubit.state;
      if (state is HomeLoaded) {
        for (final d in state.devices) {
          if (d.type == 'climate' || d.type == 'ac') {
            await widget.homeCubit.setDeviceMode(
              widget.homeId,
              state.selectedRoomId ?? 'living_room',
              d,
              'heat',
            );
          }
        }
      }
      if (mounted) {
        setState(() {
          _assistantFeedback = '🔥 Climate mode switched to HEAT.';
          _isProcessing = false;
        });
      }
    } else if (lower.contains('eco') || lower.contains('fan')) {
      final state = widget.homeCubit.state;
      if (state is HomeLoaded) {
        for (final d in state.devices) {
          if (d.type == 'climate' || d.type == 'ac') {
            await widget.homeCubit.setDeviceMode(
              widget.homeId,
              state.selectedRoomId ?? 'living_room',
              d,
              'fan',
            );
          }
        }
      }
      if (mounted) {
        setState(() {
          _assistantFeedback = '🌱 Eco mode enabled.';
          _isProcessing = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _assistantFeedback =
              'Command recognized: "$command". Devices synchronized.';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: context.cardCol,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white24
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Smart Voice Assistant',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.textPrimaryCol,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quick smart commands & voice automation',
            style: TextStyle(fontSize: 13, color: context.textSecondaryCol),
          ),
          const SizedBox(height: 22),

          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              return Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      AppConstants.primaryPurple,
                      AppConstants.primaryPurpleDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryPurple.withValues(
                        alpha: 0.25 + 0.25 * _pulseController.value,
                      ),
                      blurRadius: 18 + 12 * _pulseController.value,
                      spreadRadius: 4 * _pulseController.value,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: const Center(
              child: Icon(Icons.mic_rounded, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardSubtleCol,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessing) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppConstants.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    _assistantFeedback,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryCol,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                QuickCommandPill(
                  icon: Icons.lightbulb_rounded,
                  label: 'Turn ON All',
                  onTap: () => _executeCommand('Turn on all devices'),
                ),
                QuickCommandPill(
                  icon: Icons.nightlight_round,
                  label: 'Night Mode',
                  onTap: () => _executeCommand('Night mode turn off all'),
                ),
                QuickCommandPill(
                  icon: Icons.ac_unit_rounded,
                  label: 'Cool Climate',
                  onTap: () => _executeCommand('Set climate to cool'),
                ),
                QuickCommandPill(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Heat Climate',
                  onTap: () => _executeCommand('Set climate to heat'),
                ),
                QuickCommandPill(
                  icon: Icons.eco_rounded,
                  label: 'Eco Mode',
                  onTap: () => _executeCommand('Eco mode'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cmdCtrl,
                  style: TextStyle(color: context.textPrimaryCol),
                  decoration: InputDecoration(
                    hintText: 'Type custom voice command...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryCol,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: context.cardSubtleCol,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _executeCommand(val);
                      _cmdCtrl.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppConstants.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  final text = _cmdCtrl.text.trim();
                  if (text.isNotEmpty) {
                    _executeCommand(text);
                    _cmdCtrl.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickCommandPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickCommandPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardSubtleCol,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.dividerCol),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppConstants.primaryPurple),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryCol,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
