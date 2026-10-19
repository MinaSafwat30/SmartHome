import 'package:flutter/material.dart';

class SmartDeviceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isOn;
  final ValueChanged<bool> onToggle;

  const SmartDeviceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isOn
                      ? [const Color(0xFF7F70F5), const Color(0xFF9E5CF6)]
                      : [Colors.grey.shade400, Colors.grey.shade400],
                ).createShader(bounds),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOn ? "ON" : "OFF",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isOn ? const Color(0xFF7F70F5) : Colors.grey.shade400,
                ),
              ),
              Switch.adaptive(
                value: isOn,
                activeThumbColor: const Color(0xFF7F70F5),
                activeTrackColor: const Color(0xFF7F70F5).withValues(alpha: 0.5),
                onChanged: onToggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
