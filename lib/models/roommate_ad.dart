// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:roomy_finder/models/user.dart';

class RoommateAd {
  String id;
  User poster; // The user who poster the ad
  String type; // "Studio", "Appartment", "House"
  String rentType; // Monthly, Weekly, Daily
  String action; // "NEED ROOM", "HAVE ROOM"
  bool isPremium;
  num budget;
  String description;
  List<String> images;
  List<String> videos;
  bool isAvailable;
  DateTime movingDate;
  DateTime createdAt;
  Map<String, Object?> address; // keys : city,location,buildingName
  Map<String, Object?> aboutYou; //
  Map<String, Object> socialPreferences;
  List<String> amenities;
  List<String> interests;
  String? shareLink;

  RoommateAd({
    required this.id,
    required this.poster,
    required this.type,
    required this.rentType,
    required this.action,
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
    required this.amenities,
    required this.interests,
    this.shareLink,
  });

  bool get isMine => poster.isMe;
  bool get isHaveRoom => action == "HAVE ROOM";
  bool get isNeedRoom => action == "NEED ROOM";

  List<String> get technologyAmenities {
    return amenities.where((e) {
      return ["WIFI", "TV"].contains(e);
    }).toList();
  }

  List<String> get homeAppliancesAmenities {
    return amenities.where((e) {
      return ["Washer", "Cleaning included", "Kitchen appliances"].contains(e);
    }).toList();
  }

  List<String> get utilitiesAmenities {
    return amenities.where((e) {
      return [
        "Close to metro",
        "Balcony",
        "Parking",
        "Shared gym",
        "Near to supermarket",
        "Shared swimming pool",
        "Near to pharmacy",
      ].contains(e);
    }).toList();
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
      'amenities': amenities,
      'interests': interests,
      'shareLink': shareLink,
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
      isPremium: map['isPremium'] as bool,
      isAvailable: map['isAvailable'] as bool,
      description: map['description'] as String,
      images: List<String>.from((map['images'] as List)),
      videos: List<String>.from((map['videos'] as List)),
      createdAt: DateTime.parse(map['createdAt'] as String),
      movingDate: DateTime.parse(map['movingDate'] as String),
      address: Map<String, Object?>.from((map['address'] as Map)),
      aboutYou: Map<String, Object?>.from((map['aboutYou'] as Map)),
      socialPreferences:
          Map<String, Object>.from((map['socialPreferences'] as Map)),
      amenities: List<String>.from((map['amenities'] as List)),
      interests: List<String>.from((map['interests'] as List)),
      shareLink: map['shareLink'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoommateAd.fromJson(String source) =>
      RoommateAd.fromMap(json.decode(source) as Map<String, dynamic>);
}
