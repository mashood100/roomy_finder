// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

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
  Map<String, Object>? autoApproval;

  String? shareLink;

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
      return ["Washer", "Cleaning Included", "Kitchen Appliances"].contains(e);
    }).toList();
  }

  List<String> get utilitiesAmenities {
    return amenities.where((e) {
      return [
        "Close to Metro",
        "Balcony",
        "Parking Lot",
        "Gym",
        "Near Grocery",
        "Swimming Pool",
        "Near Pharmacy",
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
    this.needsPhotograph,
    this.shareLink,
    this.autoApproval,
  });

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
      'needsPhotograph': needsPhotograph,
      'shareLink': shareLink,
      'autoApproval': autoApproval,
    };
  }

  factory PropertyAd.fromMap(Map<String, dynamic> map) {
    if (map["posterType"] == "Landlord") map.remove("agentInfo");
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
      needsPhotograph: map["needsPhotograph"] == true,
      shareLink: map['shareLink'] as String?,
      autoApproval: map["autoApproval"] == null
          ? null
          : Map<String, Object>.from((map['autoApproval'] as Map)),
    );
  }

  String toJson() => json.encode(toMap());

  factory PropertyAd.fromJson(String source) =>
      PropertyAd.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PropertyAd(id: $id, poster: $poster, type: $type, quantity: $quantity, quantityTaken: $quantityTaken, preferedRentType: $preferedRentType, monthlyPrice: $monthlyPrice, weeklyPrice: $weeklyPrice, dailyPrice: $dailyPrice, deposit: $deposit, depositPrice: $depositPrice, posterType: $posterType, description: $description, images: $images, videos: $videos, amenties: $amenities, createdAt: $createdAt, address: $address, socialPreferences: $socialPreferences)';
  }

  @override
  bool operator ==(covariant PropertyAd other) {
    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  void updateFrom(PropertyAd other) {
    // id= other.id;
    poster = other.poster;
    type = other.type;
    quantity = other.quantity;
    quantityTaken = other.quantityTaken;
    preferedRentType = other.preferedRentType;
    monthlyPrice = other.monthlyPrice;
    weeklyPrice = other.weeklyPrice;
    dailyPrice = other.dailyPrice;
    deposit = other.deposit;
    depositPrice = other.depositPrice;
    posterType = other.posterType;
    agentInfo = other.agentInfo;
    description = other.description;
    images = other.images;
    videos = other.videos;
    amenities = other.amenities;
    createdAt = other.createdAt;
    address = other.address;
    socialPreferences = other.socialPreferences;
    needsPhotograph = other.needsPhotograph;
    shareLink = other.shareLink;
    autoApproval = other.autoApproval;
  }
}
