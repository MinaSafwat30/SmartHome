import 'package:smarthome/features/smart_home/data/repositories/smart_home_repository.dart';

class ServiceLocator {
  ServiceLocator._privateConstructor();

  static final ServiceLocator _instance = ServiceLocator._privateConstructor();

  factory ServiceLocator() => _instance;

  final SmartHomeRepository smartHomeRepository = SmartHomeRepository();
}
