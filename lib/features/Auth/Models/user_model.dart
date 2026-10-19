class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String homeId;
  final String role; // 'admin' | 'member' | 'guest'
  final String createdAt;

  const UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.homeId,
    required this.role,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      homeId: map['homeId'] ?? 'home_alpha',
      role: map['role'] ?? 'member',
      createdAt: map['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'homeId': homeId,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
