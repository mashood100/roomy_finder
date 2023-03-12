// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roomy_finder/classes/place_autocomplete.dart';
import 'package:roomy_finder/models/user.dart';

class RoommateAd {
  String id;
  User poster;
  String type;
  String rentType;
  bool isPremium;
  num budget;
  String description;
  List<String> images;
  List<String> videos;
  bool isAvailable;
  DateTime movingDate;
  DateTime createdAt;
  Map<String, Object> address;
  Map<String, Object> aboutYou;
  Map<String, Object> socialPreferences;

  CameraPosition? cameraPosition;
  PlaceAutoCompletePredicate? autoCompletePredicate;

  RoommateAd({
    required this.id,
    required this.poster,
    required this.type,
    required this.rentType,
    required this.budget,
    required this.isPremium,
    required this.isAvailable,
    required this.description,
    required this.images,
    required this.videos,
    required this.createdAt,
    required this.movingDate,
    required this.address,
    required this.aboutYou,
    required this.socialPreferences,
    this.cameraPosition,
    this.autoCompletePredicate,
  });

  bool get isMine => poster.isMe;

  @override
  bool operator ==(covariant RoommateAd other) {
    if (identical(this, other)) return true;

    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'poster': poster.toMap(),
      'type': type,
      'rentType': rentType,
      'budget': budget,
      'isPremium': isPremium,
      'isAvailable': isAvailable,
      'description': description,
      'images': images,
      'videos': videos,
      'createdAt': createdAt.toIso8601String(),
      'movingDate': movingDate.toIso8601String(),
      'address': address,
      'aboutYou': aboutYou,
      'socialPreferences': socialPreferences,
      'cameraPosition': cameraPosition?.toMap(),
      'autoCompletePredicate': autoCompletePredicate?.toMap(),
    };
  }

  factory RoommateAd.fromMap(Map<String, dynamic> map) {
    return RoommateAd(
      id: map['id'] as String,
      poster: User.fromMap(map['poster'] as Map<String, dynamic>),
      type: map['type'] as String,
      rentType: map['rentType'] as String,
      budget: map['budget'] as num,
      isPremium: map['isPremium'] as bool,
      isAvailable: map['isAvailable'] as bool,
      description: map['description'] as String,
      images: List<String>.from((map['images'] as List)),
      videos: List<String>.from((map['videos'] as List)),
      createdAt: DateTime.parse(map['createdAt'] as String),
      movingDate: DateTime.parse(map['movingDate'] as String),
      address: Map<String, Object>.from((map['address'] as Map)),
      aboutYou: Map<String, Object>.from((map['aboutYou'] as Map)),
      socialPreferences:
          Map<String, Object>.from((map['socialPreferences'] as Map)),
      cameraPosition: map["cameraPosition"] == null
          ? null
          : CameraPosition.fromMap(map["cameraPosition"]),
      autoCompletePredicate: map["autoCompletePredicate"] == null
          ? null
          : PlaceAutoCompletePredicate.fromMap(map["autoCompletePredicate"]),
    );
  }

  String toJson() => json.encode(toMap());

  factory RoommateAd.fromJson(String source) =>
      RoommateAd.fromMap(json.decode(source) as Map<String, dynamic>);
}
