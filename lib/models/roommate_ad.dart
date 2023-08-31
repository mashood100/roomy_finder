// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:roomy_finder/models/user.dart';

class RoommateAd {
  String id;
  User poster; // The user who poster the ad
  String type; // "Studio", "Apartment", "House"
  String rentType; // Monthly, Weekly, Daily
  String action; // "NEED ROOM", "HAVE ROOM"
  num budget;
  String? description;
  List<String> images;
  List<String> videos;
  bool isAvailable;
  DateTime? movingDate;
  DateTime createdAt;
  Map<String, Object?> address; // keys : city,location
  Map<String, Object?> aboutYou; //
  Map<String, Object> socialPreferences;
  List<String> amenities;
  List<String> interests;
  String? shareLink;
  bool? billIncluded;

  RoommateAd({
    required this.id,
    required this.poster,
    required this.type,
    required this.rentType,
    required this.action,
    required this.budget,
    required this.isAvailable,
    this.description,
    required this.images,
    required this.videos,
    required this.createdAt,
    required this.movingDate,
    required this.address,
    required this.aboutYou,
    required this.socialPreferences,
    required this.amenities,
    required this.interests,
    this.shareLink,
    this.billIncluded,
  });

  bool get isMine => poster.isMe;
  bool get isHaveRoom => action == "HAVE ROOM";
  bool get isNeedRoom => action == "NEED ROOM";

  String get city => address["city"].toString();

  String get location {
    var value = address["location"].toString();

    if (value.contains("(") && !value.endsWith('(')) {
      return '(${value.split("(").last}';
    }

    return value;
  }

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
      'action': action,
      'budget': budget,
      'isAvailable': isAvailable,
      'description': description,
      'images': images,
      'videos': videos,
      'createdAt': createdAt.toIso8601String(),
      'movingDate': movingDate?.toIso8601String(),
      'address': address,
      'aboutYou': aboutYou,
      'socialPreferences': socialPreferences,
      'amenities': amenities,
      'interests': interests,
      'shareLink': shareLink,
      'billIncluded': billIncluded,
    };
  }

  factory RoommateAd.fromMap(Map<String, dynamic> map) {
    return RoommateAd(
      id: map['id'] as String,
      poster: User.fromMap(map['poster'] as Map<String, dynamic>),
      type: map['type'] as String,
      rentType: map['rentType'] as String,
      action: map['action'] as String,
      budget: map['budget'] as num,
      isAvailable: map['isAvailable'] as bool,
      description: map['description'] as String?,
      images: List<String>.from((map['images'] as List)),
      videos: List<String>.from((map['videos'] as List)),
      createdAt: DateTime.parse(map['createdAt'] as String),
      movingDate: map['movingDate'] != null
          ? DateTime.parse(map['movingDate'] as String)
          : null,
      address: Map<String, Object?>.from((map['address'] as Map)),
      aboutYou: Map<String, Object?>.from((map['aboutYou'] as Map)),
      socialPreferences:
          Map<String, Object>.from((map['socialPreferences'] as Map)),
      amenities: List<String>.from((map['amenities'] as List)),
      interests: List<String>.from((map['interests'] as List)),
      shareLink: map['shareLink'] as String?,
      billIncluded: map['billIncluded'] as bool?,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoommateAd.fromJson(String source) =>
      RoommateAd.fromMap(json.decode(source) as Map<String, dynamic>);
}
