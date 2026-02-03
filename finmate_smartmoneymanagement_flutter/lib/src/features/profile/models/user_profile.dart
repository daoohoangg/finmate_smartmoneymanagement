class UserProfile {
  UserProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.hasAvatar,
  });

  final String userId;
  final String email;
  final String fullName;
  final bool hasAvatar;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      hasAvatar: json['hasAvatar'] == true,
    );
  }
}
