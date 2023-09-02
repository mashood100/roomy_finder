// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:roomy_finder/models/user/user.dart';

class PropertyAd {
  String id;
  User poster;
  String type;
  int quantity;
  int quantityTaken;
  num? monthlyPrice;
  num? weeklyPrice;
  num? dailyPrice;
  num? depositPrice;
  String posterType;
  Map<String, dynamic>? agentInfo;
  String? description;
  List<String> images;
  List<String> videos;
  List<String> amenities;
  DateTime createdAt;
  Map<String, dynamic> address;
  Map<String, dynamic> socialPreferences;
  bool? needsPhotograph;
  Map<String, dynamic>? autoApproval;
  bool? billIncluded;

  String? shareLink;

  bool get hasDeposit => depositPrice != null;
  bool get isMine => poster.isMe;
  bool get isAvailable => quantity != quantityTaken;

  num? get monthlyCommission =>
      monthlyPrice == null ? null : monthlyPrice! * 0.1;
  num? get weeklyCommission => weeklyPrice == null ? null : weeklyPrice! * 0.1;
  num? get dailyCommission => dailyPrice == null ? null : dailyPrice! * 0.05;

  num get prefferedRentDisplayPrice {
    if (monthlyPrice != null) {
      return monthlyPrice! + monthlyCommission!;
    }

    if (weeklyPrice != null) {
      return weeklyPrice! + weeklyCommission!;
    }
    if (dailyPrice != null) {
      return dailyPrice! + dailyCommission!;
    }

    return 0;
  }

  bool get autoApprovalIsActivated {
    if (autoApproval == null) return false;

    final date = DateTime.tryParse("${autoApproval?["expireAt"]}");

    if (date == null) return false;

    if (DateTime.now().isAfter(date)) return false;

    return true;
  }

  bool get autoApprovalIsEnabled {
    return autoApprovalIsActivated && autoApproval?["enabled"] == true;
  }

  String get preferedRentType {
    if (monthlyPrice != null) {
      return "Monthly";
    }

    if (weeklyPrice != null) {
      return "Weekly";
    }

    return "Daily";
  }

  String get city => address["city"].toString();

  String get location {
    var value = address["location"].toString();

    if (value.contains("(") && !value.endsWith('(')) {
      return '(${value.split("(").last}';
    }

    return value;
  }

  String get buildingName {
    return address["buildingName"]?.toString() ?? "N/A";
  }

  String get appartmentNumber {
    return address["appartmentNumber"]?.toString() ?? "N/A";
  }

  String get floorNumber {
    return address["floorNumber"]?.toString() ?? "N/A";
  }

  PropertyAd({
    required this.id,
    required this.poster,
    required this.type,
    required this.quantity,
    required this.quantityTaken,
    this.monthlyPrice,
    this.weeklyPrice,
    this.dailyPrice,
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
    this.autoApproval,
    this.billIncluded,
    this.shareLink,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'poster': poster.toMap(),
      'type': type,
      'quantity': quantity,
      'quantityTaken': quantityTaken,
      'monthlyPrice': monthlyPrice,
      'weeklyPrice': weeklyPrice,
      'dailyPrice': dailyPrice,
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
      'autoApproval': autoApproval,
      'billIncluded': billIncluded,
      'shareLink': shareLink,
    };
  }

  factory PropertyAd.fromMap(Map<String, dynamic> map) {
    return PropertyAd(
      id: map['id'] as String,
      poster: User.fromMap(map['poster'] as Map<String, dynamic>),
      type: map['type'] as String,
      quantity: map['quantity'] as int,
      quantityTaken: map['quantityTaken'] as int,
      monthlyPrice:
          map['monthlyPrice'] != null ? map['monthlyPrice'] as num : null,
      weeklyPrice:
          map['weeklyPrice'] != null ? map['weeklyPrice'] as num : null,
      dailyPrice: map['dailyPrice'] != null ? map['dailyPrice'] as num : null,
      depositPrice:
          map['depositPrice'] != null ? map['depositPrice'] as num : null,
      posterType: map['posterType'] as String,
      agentInfo: map['agentInfo'] != null
          ? Map<String, dynamic>.from(
              (map['agentInfo'] as Map<String, dynamic>))
          : null,
      description:
          map['description'] != null ? map['description'] as String : null,
      images: List<String>.from((map['images'] as List)),
      videos: List<String>.from((map['videos'] as List)),
      amenities: List<String>.from((map['amenities'] as List)),
      createdAt: DateTime.parse(map['createdAt'] as String),
      address:
          Map<String, dynamic>.from((map['address'] as Map<String, dynamic>)),
      socialPreferences: Map<String, dynamic>.from(
          (map['socialPreferences'] as Map<String, dynamic>)),
      needsPhotograph: map['needsPhotograph'] != null
          ? map['needsPhotograph'] as bool
          : null,
      autoApproval: map['autoApproval'] != null
          ? Map<String, dynamic>.from(
              (map['autoApproval'] as Map<String, dynamic>))
          : null,
      billIncluded:
          map['billIncluded'] != null ? map['billIncluded'] as bool : null,
      shareLink: map['shareLink'] != null ? map['shareLink'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PropertyAd.fromJson(String source) =>
      PropertyAd.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PropertyAd(id: $id, type: $type, quantity: $quantity)';
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
    monthlyPrice = other.monthlyPrice;
    weeklyPrice = other.weeklyPrice;
    dailyPrice = other.dailyPrice;
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
