import 'package:firebase_database/firebase_database.dart';
import '../Models/device_model.dart';
import '../Models/room_model.dart';

class SmartHomeRepository {
  SmartHomeRepository._privateConstructor();

  static final SmartHomeRepository _instance = SmartHomeRepository._privateConstructor();

  factory SmartHomeRepository() => _instance;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();


  Stream<Map<String, dynamic>?> getHomeMetadataStream(String homeId) {
    return _dbRef.child('homes/$homeId/metadata').onValue.map((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    });
  }


  Stream<List<DeviceModel>> getDevicesStream(String homeId, String roomId) {
    return _dbRef
        .child('homes/$homeId/rooms/$roomId/devices')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return [];
      final mapData = Map<dynamic, dynamic>.from(data);
      return mapData.entries
          .where((e) => e.value is Map)
          .map((e) => DeviceModel.fromMap(
                e.key.toString(),
                Map<dynamic, dynamic>.from(e.value as Map),
              ))
          .toList();
    });
  }

  Future<void> toggleDeviceState({
    required String homeId,
    required String roomId,
    required String deviceId,
    required bool isNowOn,
  }) async {
    await _dbRef
        .child('homes/$homeId/rooms/$roomId/devices/$deviceId')
        .update({
      'status': isNowOn ? 1 : 0,
      'last_updated': ServerValue.timestamp,
    });

    try {
      final snapshot =
          await _dbRef.child('homes/$homeId/rooms/$roomId/devices').get();
      if (snapshot.exists && snapshot.value is Map) {
        final devicesMap = snapshot.value as Map<dynamic, dynamic>;
        bool anyDeviceActive = false;
        devicesMap.forEach((k, v) {
          if (v is Map) {
            final st = v['status'];
            if (st == 1) anyDeviceActive = true;
          }
        });
        await _dbRef.child('homes/$homeId/rooms/$roomId').update({
          'status': anyDeviceActive ? 1 : 0,
          'last_updated': ServerValue.timestamp,
        });
      }
    } catch (_) {}
  }

  Future<void> updateDeviceMode({
    required String homeId,
    required String roomId,
    required String deviceId,
    required String mode,
  }) async {
    await _dbRef
        .child('homes/$homeId/rooms/$roomId/devices/$deviceId')
        .update({
      'mode': mode,
      'last_updated': ServerValue.timestamp,
    });
  }


  Stream<List<RoomModel>> getRoomsStream(String homeId) {
    return _dbRef.child('homes/$homeId/rooms').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return [];
      final mapData = Map<dynamic, dynamic>.from(data);
      return mapData.entries
          .where((e) => e.value is Map)
          .map((e) => RoomModel.fromMap(
                e.key.toString(),
                Map<dynamic, dynamic>.from(e.value as Map),
              ))
          .toList();
    });
  }

  Future<void> toggleRoomState({
    required String homeId,
    required String roomId,
    required bool isNowOn,
  }) async {
    await toggleAllDevicesInRoom(
      homeId: homeId,
      roomId: roomId,
      turnOn: isNowOn,
    );
  }

  Future<void> toggleAllDevicesInRoom({
    required String homeId,
    required String roomId,
    required bool turnOn,
  }) async {
    final roomRef = _dbRef.child('homes/$homeId/rooms/$roomId');
    final snapshot = await roomRef.child('devices').get();

    final updates = <String, dynamic>{
      'status': turnOn ? 1 : 0,
      'last_updated': ServerValue.timestamp,
    };

    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      for (final key in data.keys) {
        updates['devices/$key/status'] = turnOn ? 1 : 0;
        updates['devices/$key/last_updated'] = ServerValue.timestamp;
      }
    }

    try {
      await roomRef.update(updates);
    } catch (_) {
      await roomRef.child('status').set(turnOn ? 1 : 0);
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (final key in data.keys) {
          await roomRef.child('devices/$key/status').set(turnOn ? 1 : 0);
        }
      }
    }
  }

  Future<void> toggleAllDevicesInHome({
    required String homeId,
    required bool turnOn,
    List<String>? fallbackRoomIds,
  }) async {
    final homeRef = _dbRef.child('homes/$homeId');
    DataSnapshot? snapshot;
    try {
      snapshot = await homeRef.child('rooms').get();
    } catch (_) {}

    final updates = <String, dynamic>{};
    final Map<String, dynamic> parsedRooms = {};

    if (snapshot != null && snapshot.exists && snapshot.value != null) {
      final val = snapshot.value;
      if (val is Map) {
        val.forEach((k, v) {
          parsedRooms[k.toString()] = v;
        });
      } else if (val is List) {
        for (int i = 0; i < val.length; i++) {
          if (val[i] != null) {
            parsedRooms[i.toString()] = val[i];
          }
        }
      }
    }

    parsedRooms.forEach((roomKey, roomVal) {
      updates['rooms/$roomKey/status'] = turnOn ? 1 : 0;
      updates['rooms/$roomKey/last_updated'] = ServerValue.timestamp;

      if (roomVal is Map && roomVal['devices'] is Map) {
        final devicesMap = roomVal['devices'] as Map<dynamic, dynamic>;
        for (final deviceKey in devicesMap.keys) {
          updates['rooms/$roomKey/devices/$deviceKey/status'] = turnOn ? 1 : 0;
          updates['rooms/$roomKey/devices/$deviceKey/last_updated'] =
              ServerValue.timestamp;
        }
      }
    });

    bool multiPathSuccess = false;
    if (updates.isNotEmpty) {
      try {
        await homeRef.update(updates);
        multiPathSuccess = true;
      } catch (_) {
        multiPathSuccess = false;
      }
    }

    if (!multiPathSuccess) {
      final roomIdsToUpdate = <String>{
        ...parsedRooms.keys,
        if (fallbackRoomIds != null) ...fallbackRoomIds,
      };

      for (final rId in roomIdsToUpdate) {
        await toggleAllDevicesInRoom(
          homeId: homeId,
          roomId: rId,
          turnOn: turnOn,
        );
      }
    }
  }

  Future<void> updateDeviceTemperature({
    required String homeId,
    required String roomId,
    required String deviceId,
    required double targetTemp,
  }) async {
    await _dbRef
        .child('homes/$homeId/rooms/$roomId/devices/$deviceId')
        .update({
      'target_temp': targetTemp,
      'last_updated': ServerValue.timestamp,
    });
  }

  Stream<List<String>> getAvailableHomesStream() {
    return _dbRef.child('homes').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return ['home_alpha'];
      return data.keys.map((k) => k.toString()).toList();
    });
  }

  Future<void> switchUserHome({
    required String uid,
    required String newHomeId,
  }) async {
    await _dbRef.child('users/$uid').update({'homeId': newHomeId});
  }
}
