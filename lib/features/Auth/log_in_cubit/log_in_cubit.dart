import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smarthome/features/Auth/Models/user_model.dart';
import 'package:smarthome/features/Auth/auth_repository.dart';

part 'log_in_state.dart';

class LogInCubit extends Cubit<LogInState> {
  final AuthRepository _repo;
  LogInCubit(this._repo) : super(LogInInitial());

  Future<void> loginUser(String email, String password) async {
    emit(LogInLoading());
    try {
      final user = await _repo.signIn(email: email, password: password);
      if (!isClosed) emit(LogInSuccess(user: user));
    } on FirebaseAuthException catch (e) {
      if (!isClosed) emit(LogInFailure(errorMessage: _mapFirebaseError(e)));
    } catch (e) {
      if (!isClosed) emit(LogInFailure(errorMessage: e.toString()));
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }
}
