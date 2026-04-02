class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String dob;
  final String avatarUrl;
  final String role;
  final String status;
  final List<String> savedAddresses;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.gender = '',
    this.dob = '',
    this.avatarUrl = '',
    this.role = 'customer',
    this.status = 'approved',
    this.savedAddresses = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      gender: map['gender'] ?? '',
      dob: map['dob'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      role: map['role'] ?? 'customer',
      status: map['status'] ?? 'approved',
      savedAddresses: List<String>.from(map['savedAddresses'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'dob': dob,
      'avatarUrl': avatarUrl,
      'role': role,
      'status': status,
      'savedAddresses': savedAddresses,
    };
  }
}
