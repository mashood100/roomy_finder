// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:roomy_finder/models/chat_user.dart';
import 'package:roomy_finder/controllers/app_controller.dart';

class User {
  String id;
  String type;
  String email;
  String phone;
  String firstName;
  String lastName;
  String country;
  String gender;
  String profilePicture;
  bool isPremium;
  DateTime createdAt;
  String fcmToken;

  User({
    required this.id,
    required this.type,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.gender,
    required this.profilePicture,
    required this.isPremium,
    required this.createdAt,
    required this.fcmToken,
  });

  String? get password => AppController.instance.userPassword;
  String get fullName => "$firstName $lastName";
  bool get isMe => AppController.instance.user.value.id == id;
  bool get isLandlord => type == "landlord";
  bool get isRoommate => type == "roommate";
  bool get isGuest => this == GUEST_USER;

  Future<String> get formattedPhoneNumber async {
    final phoneNumber = PhoneNumber(
      phoneNumber: AppController.me.phone,
    );
    try {
      final data = await PhoneNumber.getParsableNumber(phoneNumber);
      return "(${phoneNumber.dialCode}) $data";
    } on Exception catch (_) {
      return phoneNumber.phoneNumber ?? "";
    }
  }

  ChatUser get chatUser => ChatUser(
        id: id,
        firstName: firstName,
        lastName: lastName,
        profilePicture: profilePicture,
        fcmToken: fcmToken,
        createdAt: createdAt,
      );

  User copyWith({
    String? id,
    String? type,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? country,
    String? gender,
    String? profilePicture,
    bool? isPremium,
    DateTime? createdAt,
    String? fcmToken,
  }) {
    return User(
      id: id ?? this.id,
      type: type ?? this.type,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      gender: gender ?? this.gender,
      profilePicture: profilePicture ?? this.profilePicture,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'email': email,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'country': country,
      'gender': gender,
      'profilePicture': profilePicture,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
      'fcmToken': fcmToken,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      type: map['type'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      country: map['country'] as String,
      gender: map['gender'] as String,
      profilePicture: map['profilePicture'] as String,
      isPremium: map['isPremium'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      fcmToken: map['fcmToken'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(id: $id, type: $type, email: $email, phone: $phone,'
        ' firstName: $firstName, lastName: $lastName,'
        ' country: $country, profilePicture: $profilePicture,'
        ' isPremium: $isPremium, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;

    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  Widget ppWidget({
    double size = 50,
    bool borderColor = true,
  }) {
    final innerRadius = borderColor ? size - 2 : size;
    return CircleAvatar(
      backgroundColor: Colors.black,
      radius: size,
      child: Builder(builder: (context) {
        final logoText = firstName[0] + lastName[0];

        return CircleAvatar(
          radius: innerRadius,
          foregroundImage: CachedNetworkImageProvider(profilePicture),
          onForegroundImageError: (e, trace) {},
          child: Text(
            logoText,
            style: TextStyle(fontSize: size * 0.9),
          ),
        );
      }),
    );
  }

  // ignore: non_constant_identifier_names
  static User GUEST_USER = User(
    id: "010101010101010101010101",
    type: "geust",
    email: "",
    phone: "",
    firstName: "",
    lastName: "",
    country: "",
    gender: "",
    profilePicture: "",
    isPremium: false,
    createdAt: DateTime(2023),
    fcmToken: "",
  );
}
