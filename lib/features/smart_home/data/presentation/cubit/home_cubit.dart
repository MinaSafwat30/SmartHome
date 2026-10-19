import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smarthome/features/smart_home/data/repositories/smart_home_repository.dart';
import 'package:smarthome/features/smart_home/data/Models/device_model.dart';
import 'package:smarthome/features/smart_home/data/Models/room_model.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final SmartHomeRepository repository;
  StreamSubscription? _devicesSubscription;
  StreamSubscription? _roomsSubscription;
  StreamSubscription? _metadataSubscription;

  List<DeviceModel> _devices = [];
  List<RoomModel> _rooms = [];
  String? _homeName;
  String? _homeId;
  String? _selectedRoomId;

  HomeCubit(this.repository) : super(HomeInitial());

  void initStreams(String homeId, String roomId) {
    emit(HomeLoading());

    _homeId = homeId;
    _selectedRoomId = roomId;

    _devicesSubscription?.cancel();
    _roomsSubscription?.cancel();
    _metadataSubscription?.cancel();

    _metadataSubscription =
        repository.getHomeMetadataStream(homeId).listen((meta) {
      if (meta != null && meta['name'] is String) {
        _homeName = meta['name'] as String;
      }
      _emitCurrentState();
    }, onError: (_) {});

    _roomsSubscription = repository.getRoomsStream(homeId).listen((rooms) {
      _rooms = rooms;
      if (_selectedRoomId == null ||
          (!_rooms.any((r) => r.id == _selectedRoomId) && _rooms.isNotEmpty)) {
        if (_rooms.isNotEmpty) {
          selectRoom(_rooms.first.id);
          return;
        }
      }
      _emitCurrentState();
    }, onError: (error) {
      emit(HomeError(error.toString()));
    });

    _listenDevices(roomId);
  }

  void _listenDevices(String roomId) {
    _devicesSubscription?.cancel();
    if (_homeId == null) return;

    _devicesSubscription =
        repository.getDevicesStream(_homeId!, roomId).listen((devices) {
      _devices = devices;
      _emitCurrentState();
    }, onError: (error) {
      emit(HomeError(error.toString()));
    });
  }

  void selectRoom(String roomId) {
    if (_selectedRoomId == roomId && _devicesSubscription != null) return;
    _selectedRoomId = roomId;
    _listenDevices(roomId);
    _emitCurrentState();
  }

  void _emitCurrentState() {
    emit(HomeLoaded(
      devices: _devices,
      rooms: _rooms,
      selectedRoomId: _selectedRoomId,
      homeName: _homeName,
    ));
  }

  void initDevicesStream(String homeId, String roomId) =>
      initStreams(homeId, roomId);

  Future<void> toggleDevice(
      String homeId, String roomId, DeviceModel device) async {
    try {
      await repository.toggleDeviceState(
        homeId: homeId,
        roomId: roomId,
        deviceId: device.id,
        isNowOn: device.status == 0,
      );
    } catch (_) {}
  }

  Future<void> setDeviceMode(
      String homeId, String roomId, DeviceModel device, String mode) async {
    try {
      await repository.updateDeviceMode(
        homeId: homeId,
        roomId: roomId,
        deviceId: device.id,
        mode: mode,
      );
    } catch (_) {}
  }

  Future<void> toggleRoom(String homeId, RoomModel room) async {
    try {
      await repository.toggleAllDevicesInRoom(
        homeId: homeId,
        roomId: room.id,
        turnOn: room.status == 0, // flip current state
      );
    } catch (_) {}
  }

  Future<void> toggleAllDevicesInHome(bool turnOn) async {
    if (_homeId == null) return;
    try {
      await repository.toggleAllDevicesInHome(
        homeId: _homeId!,
        turnOn: turnOn,
        fallbackRoomIds: _rooms.map((r) => r.id).toList(),
      );
    } catch (_) {}
  }

  Future<void> setDeviceTemperature(
      String roomId, DeviceModel device, double targetTemp) async {
    if (_homeId == null) return;
    try {
      await repository.updateDeviceTemperature(
        homeId: _homeId!,
        roomId: roomId,
        deviceId: device.id,
        targetTemp: targetTemp,
      );
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _devicesSubscription?.cancel();
    _roomsSubscription?.cancel();
    _metadataSubscription?.cancel();
    return super.close();
  }
}
