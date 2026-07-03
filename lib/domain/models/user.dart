import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum UserRole { admin, seller, delivery }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.seller:
        return 'Vendedor';
      case UserRole.delivery:
        return 'Domiciliario';
    }
  }
}

UserRole? _userRoleFromDb(String value) {
  return UserRole.values.cast<UserRole?>().firstWhere(
        (e) => e?.name == value,
        orElse: () => null,
      );
}

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String fullName,
    required UserRole role,
    String? phone,
    String? avatarUrl,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => User._fromJson(json);

  static User _fromJson(Map<String, dynamic> json) {
    return _$UserFromJson({
      ...json,
      'id': jsonStringRequired(json['id']),
      'email': jsonStringRequired(json['email']),
      'fullName': jsonStringRequired(json['full_name']),
      'role': jsonEnum(
        json['role'],
        _userRoleFromDb,
        defaultValue: UserRole.seller,
      ).name,
      'phone': jsonString(json['phone']),
      'avatarUrl': jsonString(json['avatar_url']),
      'isActive': jsonBool(json['is_active'], defaultValue: true),
      'createdAt': jsonDateTime(json['created_at']),
      'updatedAt': jsonDateTime(json['updated_at']),
    });
  }
}
