part of 'home_cubit.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<DeviceModel> devices;
  final List<RoomModel> rooms;
  final String? selectedRoomId;
  final String? homeName;

  HomeLoaded({
    required this.devices,
    required this.rooms,
    this.selectedRoomId,
    this.homeName,
  });
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}
