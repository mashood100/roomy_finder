// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roomy_finder/classes/place_autocomplete.dart';

import 'package:roomy_finder/models/user.dart';

class PropertyAd {
  String id;
  User poster;
  String type;
  int quantity;
  int quantityTaken;
  String preferedRentType;
  num monthlyPrice;
  num weeklyPrice;
  num dailyPrice;
  bool deposit;
  num? depositPrice;
  String posterType;
  Map<String, String>? agentInfo;
  String? description;
  List<String> images;
  List<String> videos;
  List<String> amenities;
  DateTime createdAt;
  Map<String, Object> address;
  Map<String, Object> socialPreferences;
  bool? needsPhotograph;

  CameraPosition? cameraPosition;
  PlaceAutoCompletePredicate? autoCompletePredicate;

  bool get isMine => poster.isMe;
  bool get isAvailable => quantity != quantityTaken;
  String? get depositPriceText => deposit ? "Deposit $depositPrice AED" : null;
  String get locationText {
    return "${address["city"]}, ${address["location"]}, ${address["buildingName"]}";
  }

  num get monthlyCommission => monthlyPrice * 0.1;
  num get weeklyCommission => weeklyPrice * 0.1;
  num get dailyCommission => dailyPrice * 0.05;

  num get prefferedRentDisplayPrice {
    switch (preferedRentType) {
      case "Monthly":
        return monthlyPrice + monthlyCommission;
      case "Weekly":
        return weeklyPrice + weeklyCommission;
      default:
        return dailyPrice + dailyCommission;
    }
  }

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

  PropertyAd({
    required this.id,
    required this.poster,
    required this.type,
    required this.quantity,
    required this.quantityTaken,
    required this.preferedRentType,
    required this.monthlyPrice,
    required this.weeklyPrice,
    required this.dailyPrice,
    required this.deposit,
    this.depositPrice,
    required this.posterType,
    this.agentInfo,
    this.description,
    required this.images,
    required this.videos,
    required this.amenities,
    required this.createdAt,
    required this.address,
    required this.socialPreferences,
    this.cameraPosition,
    this.autoCompletePredicate,
    this.needsPhotograph,
  }) : assert(images.isNotEmpty);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'poster': poster.toMap(),
      'type': type,
      'quantity': quantity,
      'quantityTaken': quantityTaken,
      'preferedRentType': preferedRentType,
      'monthlyPrice': monthlyPrice,
      'weeklyPrice': weeklyPrice,
      'dailyPrice': dailyPrice,
      'deposit': deposit,
      'depositPrice': depositPrice,
      'posterType': posterType,
      'agentInfo': agentInfo,
      'description': description,
      'images': images,
      'videos': videos,
      'amenities': amenities,
      'createdAt': createdAt.toIso8601String(),
      'address': address,
      'socialPreferences': socialPreferences,
      'cameraPosition': cameraPosition?.toMap(),
      'autoCompletePredicate': autoCompletePredicate?.toMap(),
      'needsPhotograph': needsPhotograph,
    };
  }

  factory PropertyAd.fromMap(Map<String, dynamic> map) {
    return PropertyAd(
      id: map['id'] as String,
      poster: User.fromMap(map['poster'] as Map<String, dynamic>),
      type: map['type'] as String,
      quantity: map['quantity'] as int,
      quantityTaken: map['quantityTaken'] as int,
      preferedRentType: map['preferedRentType'] as String,
      monthlyPrice: map['monthlyPrice'] as num,
      weeklyPrice: map['weeklyPrice'] as num,
      dailyPrice: map['dailyPrice'] as num,
      deposit: map['deposit'] as bool,
      depositPrice: num.tryParse("${map['depositPrice']}") ?? 0,
      posterType: map['posterType'] as String,
      description:
          map["description"] == null ? null : map['description'] as String,
      images: List<String>.from((map['images'] as List)),
      videos: List<String>.from((map['videos'] as List)),
      amenities: List<String>.from((map['amenities'] as List)),
      createdAt: DateTime.parse(map['createdAt'] as String),
      address: Map<String, Object>.from((map['address'] as Map)),
      agentInfo: map["agentInfo"] == null
          ? null
          : Map<String, String>.from((map['agentInfo'] as Map)),
      socialPreferences:
          Map<String, Object>.from((map['socialPreferences'] as Map)),
      cameraPosition: map["cameraPosition"] == null
          ? null
          : CameraPosition.fromMap(map["cameraPosition"]),
      autoCompletePredicate: map["autoCompletePredicate"] == null
          ? null
          : PlaceAutoCompletePredicate.fromMap(map["autoCompletePredicate"]),
      needsPhotograph: map["needsPhotograph"] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory PropertyAd.fromJson(String source) =>
      PropertyAd.fromMap(json.decode(source) as Map<String, dynamic>);

  PropertyAd copyWith({
    String? id,
    User? poster,
    String? type,
    int? quantity,
    int? quantityTaken,
    String? preferedRentType,
    num? monthlyPrice,
    num? weeklyPrice,
    num? dailyPrice,
    bool? deposit,
    bool? isPostPaid,
    num? depositPrice,
    String? posterType,
    String? description,
    List<String>? images,
    List<String>? videos,
    List<String>? amenities,
    DateTime? createdAt,
    Map<String, Object>? address,
    Map<String, Object>? socialPreferences,
  }) {
    return PropertyAd(
      id: id ?? this.id,
      poster: poster ?? this.poster,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      quantityTaken: quantityTaken ?? this.quantityTaken,
      preferedRentType: preferedRentType ?? this.preferedRentType,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      weeklyPrice: weeklyPrice ?? this.weeklyPrice,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      deposit: deposit ?? this.deposit,
      depositPrice: depositPrice ?? this.depositPrice,
      posterType: posterType ?? this.posterType,
      description: description ?? this.description,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      socialPreferences: socialPreferences ?? this.socialPreferences,
    );
  }

  @override
  String toString() {
    return 'PropertyAd(id: $id, poster: $poster, type: $type, quantity: $quantity, quantityTaken: $quantityTaken, preferedRentType: $preferedRentType, monthlyPrice: $monthlyPrice, weeklyPrice: $weeklyPrice, dailyPrice: $dailyPrice, deposit: $deposit, depositPrice: $depositPrice, posterType: $posterType, description: $description, images: $images, videos: $videos, amenties: $amenities, createdAt: $createdAt, address: $address, socialPreferences: $socialPreferences)';
  }

  @override
  bool operator ==(covariant PropertyAd other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.poster == poster &&
        other.type == type &&
        other.quantity == quantity &&
        other.quantityTaken == quantityTaken &&
        other.preferedRentType == preferedRentType &&
        other.monthlyPrice == monthlyPrice &&
        other.weeklyPrice == weeklyPrice &&
        other.dailyPrice == dailyPrice &&
        other.deposit == deposit &&
        other.depositPrice == depositPrice &&
        other.posterType == posterType &&
        other.description == description &&
        listEquals(other.images, images) &&
        listEquals(other.videos, videos) &&
        listEquals(other.amenities, amenities) &&
        other.createdAt == createdAt &&
        mapEquals(other.address, address) &&
        mapEquals(other.socialPreferences, socialPreferences);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        poster.hashCode ^
        type.hashCode ^
        quantity.hashCode ^
        quantityTaken.hashCode ^
        preferedRentType.hashCode ^
        monthlyPrice.hashCode ^
        weeklyPrice.hashCode ^
        dailyPrice.hashCode ^
        deposit.hashCode ^
        depositPrice.hashCode ^
        posterType.hashCode ^
        description.hashCode ^
        images.hashCode ^
        videos.hashCode ^
        amenities.hashCode ^
        createdAt.hashCode ^
        address.hashCode ^
        socialPreferences.hashCode ^
        cameraPosition.hashCode;
  }
}
