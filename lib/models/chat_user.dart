import 'dart:convert';

class ChatUser {
  final String id;
  String firstName;
  String lastName;
  String profilePicture;
  String fcmToken;
  DateTime createdAt;

  ChatUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.fcmToken,
    required this.createdAt,
  });

  String get fullName => "$firstName $lastName";

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'profilePicture': profilePicture,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      id: map['id'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      profilePicture: map['profilePicture'] as String,
      fcmToken: map['fcmToken'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatUser.fromJson(String source) =>
      ChatUser.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant ChatUser other) {
    if (identical(this, other)) return true;

    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        profilePicture.hashCode ^
        fcmToken.hashCode ^
        createdAt.hashCode;
  }
}
