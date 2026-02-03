class AuthResponse {
  AuthResponse({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.token,
  });

  final String userId;
  final String email;
  final String fullName;
  final String token;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
    );
  }
}
