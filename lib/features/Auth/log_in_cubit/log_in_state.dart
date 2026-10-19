part of 'log_in_cubit.dart';

abstract class LogInState {}

class LogInInitial extends LogInState {}

class LogInLoading extends LogInState {}

class LogInSuccess extends LogInState {
  final UserModel user;
  LogInSuccess({required this.user});
}

class LogInFailure extends LogInState {
  final String errorMessage;
  LogInFailure({required this.errorMessage});
}
