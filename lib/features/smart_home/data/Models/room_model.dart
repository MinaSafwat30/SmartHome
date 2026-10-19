class RoomSensors {
  final double? temperature;
  final double? humidity;

  const RoomSensors({this.temperature, this.humidity});

  factory RoomSensors.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const RoomSensors();
    return RoomSensors(
      temperature: (map['temperature'] as num?)?.toDouble(),
      humidity: (map['humidity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (temperature != null) 'temperature': temperature,
      if (humidity != null) 'humidity': humidity,
    };
  }
}

class RoomModel {
  final String id;
  final String name;
  final int deviceCount;
  final int status; // 1 for ON, 0 for OFF
  final String imageAsset; // local asset path
  final int? lastUpdated;
  final RoomSensors? sensors;
  final List<String> deviceIds;

  RoomModel({
    required this.id,
    required this.name,
    required this.deviceCount,
    required this.status,
    required this.imageAsset,
    this.lastUpdated,
    this.sensors,
    this.deviceIds = const [],
  });

  static String formatNameFromId(String id) {
    if (id.isEmpty) return 'Room';
    return id.split('_').map((word) {
      return word.isNotEmpty
          ? '${word[0].toUpperCase()}${word.substring(1)}'
          : '';
    }).join(' ');
  }

  factory RoomModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final rawName = map['name'] as String?;
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : formatNameFromId(id);

    List<String> devIds = [];
    int devCount = 0;
    if (map['devices'] is Map) {
      final devicesMap = map['devices'] as Map;
      devIds = devicesMap.keys.map((k) => k.toString()).toList();
      devCount = devIds.length;
    } else if (map['device_count'] is num) {
      devCount = (map['device_count'] as num).toInt();
    }

    final sensors = map['sensors'] is Map
        ? RoomSensors.fromMap(map['sensors'] as Map<dynamic, dynamic>)
        : null;

    return RoomModel(
      id: id,
      name: name,
      deviceCount: devCount,
      status: (map['status'] as num?)?.toInt() ?? 0,
      imageAsset: (map['image_asset'] as String?) ?? 'assets/rooms/default.jpg',
      lastUpdated: (map['last_updated'] as num?)?.toInt(),
      sensors: sensors,
      deviceIds: devIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'device_count': deviceCount,
      'status': status,
      'image_asset': imageAsset,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (sensors != null) 'sensors': sensors!.toMap(),
    };
  }

  RoomModel copyWith({
    String? name,
    int? deviceCount,
    int? status,
    String? imageAsset,
    int? lastUpdated,
    RoomSensors? sensors,
    List<String>? deviceIds,
  }) {
    return RoomModel(
      id: id,
      name: name ?? this.name,
      deviceCount: deviceCount ?? this.deviceCount,
      status: status ?? this.status,
      imageAsset: imageAsset ?? this.imageAsset,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sensors: sensors ?? this.sensors,
      deviceIds: deviceIds ?? this.deviceIds,
    );
  }
}

