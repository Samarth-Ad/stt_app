class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String gender;
  final String membership;
  final DateTime registrationDate;

  UserModel({
    required this.id,
    required this.email,
    this.name = '',
    this.phone = '',
    this.gender = '',
    this.membership = 'Member',
    DateTime? registrationDate,
  }) : registrationDate = registrationDate ?? DateTime.now();

  // Convert to a map (for possible future persistence)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'membership': membership,
      'registrationDate': registrationDate.millisecondsSinceEpoch,
    };
  }

  // Create a UserModel object from a map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      gender: map['gender'] ?? '',
      membership: map['membership'] ?? 'Member',
      registrationDate:
          map['registrationDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['registrationDate'])
              : DateTime.now(),
    );
  }

  // Create a copy of this user with different values
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? gender,
    String? membership,
    DateTime? registrationDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      membership: membership ?? this.membership,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }
}
