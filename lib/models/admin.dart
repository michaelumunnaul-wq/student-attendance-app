class Admin {
  final String username;
  final String passwordHash;
  final String fullName;
  final String email;

  Admin({
    required this.username,
    required this.passwordHash,
    required this.fullName,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'passwordHash': passwordHash,
        'fullName': fullName,
        'email': email,
      };

  factory Admin.fromJson(Map<String, dynamic> json) => Admin(
        username: json['username'],
        passwordHash: json['passwordHash'],
        fullName: json['fullName'],
        email: json['email'],
      );
}
