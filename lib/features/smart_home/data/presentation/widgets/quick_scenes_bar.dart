import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smarthome/core/constants/app_constants.dart';
import 'package:smarthome/core/theme/app_theme.dart';
import 'package:smarthome/features/smart_home/data/presentation/cubit/home_cubit.dart';

class QuickScenesBar extends StatelessWidget {
  const QuickScenesBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Scenes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryCol,
                ),
              ),
              Text(
                '1-Tap Automation',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondaryCol,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ScenePill(
                  icon: Icons.nightlight_round,
                  label: 'Night Mode',
                  subtitle: 'Turn Off All',
                  accentColor: AppConstants.accentBlue,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await context.read<HomeCubit>().toggleAllDevicesInHome(false);
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.nightlight_round,
                                color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Text('🌙 Night mode: All devices turned OFF'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF191C2E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                ScenePill(
                  icon: Icons.lightbulb_rounded,
                  label: 'Awake Mode',
                  subtitle: 'Turn On All',
                  accentColor: AppConstants.accentOrange,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await context.read<HomeCubit>().toggleAllDevicesInHome(true);
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.lightbulb_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Text('💡 Awake mode: All devices turned ON'),
                          ],
                        ),
                        backgroundColor: AppConstants.primaryPurple,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                ScenePill(
                  icon: context.isDarkMode
                      ? Icons.wb_sunny_rounded
                      : Icons.dark_mode_rounded,
                  label: context.isDarkMode ? 'Light UI' : 'Night UI',
                  subtitle: 'Toggle Theme',
                  accentColor: AppConstants.primaryPurpleDark,
                  onTap: () => toggleAppTheme(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScenePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const ScenePill({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.cardCol,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: context.isDarkMode ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 16),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryCol,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondaryCol,
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
