/// User Entity - Domain Layer
class UserEntity {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String theme;
  final String language;
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.theme = 'light',
    this.language = 'en',
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.isVerified = false,
    this.createdAt,
    this.lastLoginAt,
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    String? theme,
    String? language,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
