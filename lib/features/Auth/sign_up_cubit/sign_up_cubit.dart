import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smarthome/features/Auth/Models/user_model.dart';
import 'package:smarthome/features/Auth/auth_repository.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final AuthRepository _repo;
  SignUpCubit(this._repo) : super(SignUpInitial());

  Future<void> signUpUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    emit(SignUpLoading());
    try {
      final user = await _repo.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      if (!isClosed) emit(SignUpSuccess(user: user));
    } on FirebaseAuthException catch (e) {
      if (!isClosed) emit(SignUpFailure(errorMessage: _mapFirebaseError(e)));
    } catch (e) {
      if (!isClosed) emit(SignUpFailure(errorMessage: e.toString()));
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email sign-up is not enabled. Contact support.';
      default:
        return e.message ?? 'Sign up failed. Please try again.';
    }
  }
}
