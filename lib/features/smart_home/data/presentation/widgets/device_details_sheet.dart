import 'package:flutter/material.dart';
import 'package:smarthome/core/constants/app_constants.dart';
import 'package:smarthome/core/theme/app_theme.dart';
import 'package:smarthome/features/smart_home/data/Models/device_model.dart';
import 'package:smarthome/features/smart_home/data/presentation/cubit/home_cubit.dart';
import 'package:smarthome/features/smart_home/data/presentation/widgets/device_icon_widget.dart';

class DeviceDetailsSheet extends StatefulWidget {
  final DeviceModel device;
  final String homeId;
  final String roomId;
  final HomeCubit homeCubit;

  const DeviceDetailsSheet({
    super.key,
    required this.device,
    required this.homeId,
    required this.roomId,
    required this.homeCubit,
  });

  @override
  State<DeviceDetailsSheet> createState() => _DeviceDetailsSheetState();
}

class _DeviceDetailsSheetState extends State<DeviceDetailsSheet> {
  late bool _isOn;
  late String _currentMode;
  late double _targetTemp;

  @override
  void initState() {
    super.initState();
    _isOn = widget.device.status == 1;
    _currentMode = widget.device.mode?.toLowerCase() ?? 'cool';
    _targetTemp = widget.device.targetTemp ?? 24.0;
  }

  String _formatTimeAgo(int? timestamp) {
    if (timestamp == null) return 'Live RTDB';
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = (now - timestamp) ~/ 1000;
    if (diff < 60) return 'Just now';
    if (diff < 3600) return '${diff ~/ 60}m ago';
    if (diff < 86400) return '${diff ~/ 3600}h ago';
    return '${diff ~/ 86400}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isClimate = widget.device.type.toLowerCase() == 'climate' ||
        widget.device.type.toLowerCase() == 'ac';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: context.cardCol,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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

          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isOn
                        ? [AppConstants.primaryPurple, AppConstants.primaryPurpleDark]
                        : [const Color(0xFFDDDFF0), const Color(0xFFC8CBDD)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: DeviceIconWidget(
                    type: widget.device.type,
                    deviceId: widget.device.id,
                    isOn: _isOn,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.device.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.roomId.replaceAll('_', ' ').toUpperCase()} • ${widget.device.type.toUpperCase()}',
                      style: TextStyle(fontSize: 11, color: context.textSecondaryCol),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch.adaptive(
                  value: _isOn,
                  activeThumbColor: AppConstants.primaryPurple,
                  activeTrackColor: AppConstants.primaryPurple.withValues(alpha: 0.5),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: context.isDarkMode
                      ? const Color(0xFF383C56)
                      : const Color(0xFFDEDFF0),
                  onChanged: (val) {
                    setState(() => _isOn = val);
                    widget.homeCubit.toggleDevice(
                      widget.homeId,
                      widget.roomId,
                      widget.device.copyWith(status: val ? 0 : 1),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (isClimate) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardSubtleCol,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target Temperature',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryCol,
                        ),
                      ),
                      Text(
                        'Range: 16° - 30°C',
                        style: TextStyle(fontSize: 11, color: context.textSecondaryCol),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: context.cardCol,
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.remove_rounded,
                            color: AppConstants.primaryPurple, size: 20),
                        onPressed: _targetTemp > 16.0
                            ? () {
                                final next = _targetTemp - 0.5;
                                setState(() => _targetTemp = next);
                                widget.homeCubit.setDeviceTemperature(
                                    widget.roomId, widget.device, next);
                              }
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '${_targetTemp.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimaryCol,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: context.cardCol,
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.add_rounded,
                            color: AppConstants.primaryPurple, size: 20),
                        onPressed: _targetTemp < 30.0
                            ? () {
                                final next = _targetTemp + 0.5;
                                setState(() => _targetTemp = next);
                                widget.homeCubit.setDeviceTemperature(
                                    widget.roomId, widget.device, next);
                              }
                            : null,
                      ),
                    ],
                  ),
                  Slider(
                    value: _targetTemp.clamp(16.0, 30.0),
                    min: 16.0,
                    max: 30.0,
                    divisions: 28,
                    activeColor: AppConstants.primaryPurple,
                    inactiveColor: context.isDarkMode
                        ? const Color(0xFF383C56)
                        : const Color(0xFFDEDFF0),
                    onChanged: (val) {
                      setState(() => _targetTemp = val);
                      widget.homeCubit.setDeviceTemperature(
                          widget.roomId, widget.device, val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Operating Mode',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryCol,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ModeChip(
                  icon: Icons.ac_unit_rounded,
                  label: 'Cool',
                  isSelected: _currentMode == 'cool',
                  onTap: () {
                    setState(() => _currentMode = 'cool');
                    widget.homeCubit.setDeviceMode(
                        widget.homeId, widget.roomId, widget.device, 'cool');
                  },
                ),
                ModeChip(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Heat',
                  isSelected: _currentMode == 'heat',
                  onTap: () {
                    setState(() => _currentMode = 'heat');
                    widget.homeCubit.setDeviceMode(
                        widget.homeId, widget.roomId, widget.device, 'heat');
                  },
                ),
                ModeChip(
                  icon: Icons.cyclone_rounded,
                  label: 'Fan',
                  isSelected: _currentMode == 'fan',
                  onTap: () {
                    setState(() => _currentMode = 'fan');
                    widget.homeCubit.setDeviceMode(
                        widget.homeId, widget.roomId, widget.device, 'fan');
                  },
                ),
                ModeChip(
                  icon: Icons.auto_mode_rounded,
                  label: 'Auto',
                  isSelected: _currentMode == 'auto',
                  onTap: () {
                    setState(() => _currentMode = 'auto');
                    widget.homeCubit.setDeviceMode(
                        widget.homeId, widget.roomId, widget.device, 'auto');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cardSubtleCol,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                TelemetryRow(label: 'Device Key', value: widget.device.id),
                const SizedBox(height: 6),
                TelemetryRow(
                  label: 'Hardware Status',
                  value: _isOn ? 'Relay Active (1)' : 'Relay Idle (0)',
                ),
                const SizedBox(height: 6),
                TelemetryRow(
                  label: 'Last Sync',
                  value: _formatTimeAgo(widget.device.lastUpdated),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ModeChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryPurple : context.cardSubtleCol,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppConstants.primaryPurple : context.dividerCol,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : context.textPrimaryCol),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : context.textPrimaryCol,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TelemetryRow extends StatelessWidget {
  final String label;
  final String value;

  const TelemetryRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.textSecondaryCol)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryCol,
          ),
        ),
      ],
    );
  }
}
