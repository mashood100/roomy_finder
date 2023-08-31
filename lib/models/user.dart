// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:socket_io_client/socket_io_client.dart';

import 'package:roomy_finder/controllers/app_controller.dart';

class User {
  String id;
  String type;
  String email;
  String? phone;
  String firstName;
  String lastName;
  String? country;
  String? gender;
  String? profilePicture;
  bool isPremium;
  DateTime createdAt;
  num? serviceFee;
  num? VAT;

  AboutMe aboutMe;

  User({
    required this.id,
    required this.type,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    this.country,
    this.gender,
    this.profilePicture,
    required this.isPremium,
    required this.createdAt,
    this.serviceFee,
    this.VAT,
    required this.aboutMe,
  });

  String? get password => AppController.instance.userPassword;
  String get fullName => "$firstName $lastName";
  bool get isMe => AppController.instance.user.value.id == id;
  bool get isLandlord => type == "landlord";
  bool get isRoommate => type == "roommate";
  bool get isMaintenant => type == "maintainer";
  bool get isGuest => this == GUEST_USER;
  bool get isTerminatedUser => id == "0" * 24;

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
      'serviceFee': serviceFee,
      'VAT': VAT,
      'aboutMe': aboutMe.toMap(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    if (map["aboutMe"] == null) {
      map["aboutMe"] = {
        "country": map["country"],
        "gender": map["gender"],
      };
    }

    return User(
      id: map['id'] as String,
      type: map['type'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      country: map['country'] as String?,
      gender: map['gender'] as String?,
      profilePicture: map['profilePicture'] as String?,
      isPremium: map['isPremium'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      serviceFee: map['serviceFee'] as num?,
      VAT: map['VAT'] as num?,
      aboutMe: AboutMe.fromMap(map['aboutMe'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(id: $id, type: $type, email: $email, phone: $phone,'
        ' firstName: $firstName, lastName: $lastName, country: $country)';
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
        final logoText = fullName.isNotEmpty ? fullName[0] : "#";

        return CircleAvatar(
          radius: innerRadius,
          foregroundImage: (profilePicture == null
              ? AssetImage(gender == "Male"
                  ? "assets/images/default_male.png"
                  : "assets/images/default_female.png")
              : CachedNetworkImageProvider(profilePicture!)) as ImageProvider,
          onForegroundImageError: (e, trace) {},
          child: Text(
            logoText.toUpperCase(),
            style: TextStyle(fontSize: size * 0.9),
          ),
        );
      }),
    );
  }

  Map<String, dynamic> get socketOption {
    var options = OptionBuilder()
        .setAuth({
          "userId": AppController.me.id,
          "password": AppController.me.password
        })
        .disableAutoConnect()
        .setTransports(["websocket"])
        .build();

    options["auth"];

    return options;
  }

  static User GUEST_USER = User(
    id: "010101010101010101010101",
    type: "geust",
    email: "",
    firstName: "Guest",
    lastName: "User",
    isPremium: false,
    createdAt: DateTime(2023),
    aboutMe: AboutMe(languages: []),
  );

  void updateFrom(User other) {
    type = other.type;
    email = other.email;
    phone = other.phone;
    firstName = other.firstName;
    lastName = other.lastName;
    country = other.country;
    gender = other.gender;
    profilePicture = other.profilePicture;
    isPremium = other.isPremium;
    createdAt = other.createdAt;
    serviceFee = other.serviceFee;
    VAT = other.VAT;
    aboutMe = other.aboutMe;
  }
}

class AboutMe {
  String? nationality;
  String? astrologicalSign;
  int? age;
  String? occupation;
  List<String>? languages;
  String? lifeStyle;
  String? description;

  double get percentageCompleted {
    var values2 = toMap().values;
    var delta = 100 / values2.length;

    var percantageDone = 0.0;
    for (var val in values2) {
      if (val != null) percantageDone += delta;
    }

    return percantageDone;
  }

  AboutMe({
    this.nationality,
    this.astrologicalSign,
    this.age,
    this.occupation,
    this.languages,
    this.lifeStyle,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nationality': nationality,
      'astrologicalSign': astrologicalSign,
      'age': age,
      'occupation': occupation,
      'languages': languages,
      'lifeStyle': lifeStyle,
      'description': description,
    };
  }

  factory AboutMe.fromMap(Map<String, dynamic> map) {
    if (map["age"] != null) map["age"] = int.tryParse(map["age"].toString());
    return AboutMe(
      nationality:
          map['nationality'] != null ? map['nationality'] as String : null,
      astrologicalSign: map['astrologicalSign'] != null
          ? map['astrologicalSign'] as String
          : null,
      age: map['age'] != null ? map['age'] as int : null,
      occupation:
          map['occupation'] != null ? map['occupation'] as String : null,
      languages: map['languages'] != null
          ? List<String>.from((map['languages'] as List))
          : null,
      lifeStyle: map['lifeStyle'] != null ? map['lifeStyle'] as String : null,
      description:
          map['description'] != null ? map['description'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AboutMe.fromJson(String source) =>
      AboutMe.fromMap(json.decode(source) as Map<String, dynamic>);
}
