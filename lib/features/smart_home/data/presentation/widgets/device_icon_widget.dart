import 'package:flutter/material.dart';
import 'package:smarthome/core/constants/app_constants.dart';
import 'package:smarthome/core/theme/app_theme.dart';

class DeviceIconWidget extends StatelessWidget {
  final String type;
  final String deviceId;
  final bool isOn;
  final double size;

  const DeviceIconWidget({
    super.key,
    required this.type,
    required this.deviceId,
    required this.isOn,
    this.size = 40,
  });

  IconData _icon() {
    final t = type.toLowerCase();
    final dId = deviceId.toLowerCase();

    if (t == 'climate' || t == 'ac') {
      return Icons.ac_unit_rounded;
    }
    if (t == 'relay') {
      if (dId.contains('light') || dId.contains('lamp')) {
        return Icons.lightbulb_rounded;
      }
      return Icons.power_rounded;
    }
    switch (t) {
      case 'heater':
        return Icons.heat_pump_rounded;
      case 'light':
        return Icons.lightbulb_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'speaker':
        return Icons.speaker_rounded;
      case 'fan':
        return Icons.cyclone_rounded;
      default:
        return Icons.power_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: isOn
            ? [AppConstants.primaryPurple, AppConstants.primaryPurpleDark]
            : [context.textSecondaryCol, context.textSecondaryCol],
      ).createShader(bounds),
      child: Icon(_icon(), size: size, color: Colors.white),
    );
  }
}
