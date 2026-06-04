import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum UserRole { admin, seller, delivery }

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

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
