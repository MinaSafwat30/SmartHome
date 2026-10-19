import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smarthome/features/Auth/Models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();


  User? get currentFirebaseUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;


  Future<UserModel> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final now = DateTime.now().toIso8601String();

    final userModel = UserModel(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      email: email,
      homeId: 'home_alpha', // default home; can be changed later
      role: 'admin', // first user of a home is admin
      createdAt: now,
    );

    await _db.child('users/$uid').set(userModel.toMap());

    await _db.child('homes/${userModel.homeId}/members/$uid').set({
      'role': userModel.role,
      'name': userModel.fullName,
      'email': email,
      'joinedAt': now,
    });

    return userModel;
  }


  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final snapshot = await _db.child('users/$uid').get();

    if (!snapshot.exists) {
      final namePart = email.split('@').first;
      final defaultUser = UserModel(
        uid: uid,
        firstName: namePart.isNotEmpty
            ? '${namePart[0].toUpperCase()}${namePart.substring(1)}'
            : 'User',
        lastName: '',
        email: email,
        homeId: 'home_alpha',
        role: 'admin',
        createdAt: DateTime.now().toIso8601String(),
      );

      await _db.child('users/$uid').set(defaultUser.toMap());
      await _db.child('homes/home_alpha/members/$uid').set({
        'role': 'admin',
        'name': defaultUser.fullName,
        'email': email,
        'joinedAt': defaultUser.createdAt,
      });

      return defaultUser;
    }

    return UserModel.fromMap(
      uid,
      Map<dynamic, dynamic>.from(snapshot.value as Map),
    );
  }


  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }


  Future<void> signOut() async {
    await _auth.signOut();
  }


  Future<UserModel?> fetchUserProfile(String uid) async {
    final snapshot = await _db.child('users/$uid').get();
    if (!snapshot.exists) return null;
    return UserModel.fromMap(
      uid,
      Map<dynamic, dynamic>.from(snapshot.value as Map),
    );
  }
}
