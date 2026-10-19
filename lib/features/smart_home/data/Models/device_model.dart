class DeviceModel {
  final String id;
  final String name;
  final String subtitle;
  final int status; // 1 for ON, 0 for OFF
  final String type; // e.g. climate, relay, heater, light, tv, speaker
  final String? mode; // e.g. cool, heat, fan, auto
  final double? targetTemp; // e.g. 24.0 for climate units
  final int? lastUpdated;

  DeviceModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.type,
    this.mode,
    this.targetTemp,
    this.lastUpdated,
  });

  static String formatNameFromId(String id) {
    if (id.isEmpty) return 'Device';
    return id
        .split('_')
        .map((word) {
          final lower = word.toLowerCase();
          if (lower == 'ac') return 'AC';
          if (lower == 'tv') return 'TV';
          return word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '';
        })
        .join(' ');
  }

  factory DeviceModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final rawName = map['name'] as String?;
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : formatNameFromId(id);

    final type = (map['type'] as String?) ?? 'relay';
    final mode = map['mode'] as String?;
    final targetTemp =
        (map['target_temp'] as num?)?.toDouble() ??
        (map['targetTemperature'] as num?)?.toDouble();

    String subtitle = (map['subtitle'] as String?) ?? '';
    if (subtitle.isEmpty) {
      if (mode != null && mode.isNotEmpty) {
        final tempStr = targetTemp != null
            ? ' • ${targetTemp.toStringAsFixed(0)}°C'
            : '';
        subtitle = 'Mode: ${mode.toUpperCase()}$tempStr';
      } else if (type == 'climate') {
        subtitle = 'Climate Unit';
      } else if (type == 'relay') {
        subtitle = id.toLowerCase().contains('light')
            ? 'Main Light'
            : 'Relay Switch';
      } else {
        subtitle = '${type[0].toUpperCase()}${type.substring(1)} Device';
      }
    }

    return DeviceModel(
      id: id,
      name: name,
      subtitle: subtitle,
      status: (map['status'] as num?)?.toInt() ?? 0,
      type: type,
      mode: mode,
      targetTemp: targetTemp,
      lastUpdated: (map['last_updated'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subtitle': subtitle,
      'status': status,
      'type': type,
      if (mode != null) 'mode': mode,
      if (targetTemp != null) 'target_temp': targetTemp,
      if (lastUpdated != null) 'last_updated': lastUpdated,
    };
  }

  DeviceModel copyWith({
    String? name,
    String? subtitle,
    int? status,
    String? type,
    String? mode,
    double? targetTemp,
    int? lastUpdated,
  }) {
    return DeviceModel(
      id: id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
      type: type ?? this.type,
      mode: mode ?? this.mode,
      targetTemp: targetTemp ?? this.targetTemp,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
