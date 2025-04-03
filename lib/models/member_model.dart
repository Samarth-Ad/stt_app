class Member {
  final String name;
  final String role;
  final String? avatarUrl;
  final String? email;
  final String? phone;
  final String? quote;

  Member({
    required this.name,
    required this.role,
    this.avatarUrl,
    this.email,
    this.phone,
    this.quote,
  });
}
