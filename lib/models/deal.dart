// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/models/user.dart';

class Deal {
  String id;
  String adType;
  String period;
  dynamic ad;
  User client;
  User poster;
  DateTime createdAt;
  bool isPayed;
  DateTime endDate;
  Deal({
    required this.id,
    required this.adType,
    required this.period,
    required this.ad,
    required this.client,
    required this.poster,
    required this.createdAt,
    required this.isPayed,
    required this.endDate,
  });

  bool get isMine => poster.isMe;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'adType': adType,
      'period': period,
      'ad': ad.toMap(),
      'client': client.toMap(),
      'poster': poster.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'isPayed': isPayed,
      'endDate': endDate.toIso8601String(),
    };
  }

  factory Deal.fromMap(Map<String, dynamic> map) {
    return Deal(
      id: map['id'] as String,
      adType: map['adType'] as String,
      period: map['period'] as String,
      ad: map['adType'] == "PROPERTY"
          ? PropertyAd.fromMap(map['ad'])
          : RoommateAd.fromMap(map['ad']),
      client: User.fromMap(map['client'] as Map<String, dynamic>),
      poster: User.fromMap(map['poster'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['createdAt'] as String),
      isPayed: map['isPayed'] as bool,
      endDate: DateTime.parse(map['endDate'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory Deal.fromJson(String source) =>
      Deal.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant Deal other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.adType == adType &&
        other.period == period &&
        other.ad == ad &&
        other.client == client &&
        other.poster == poster &&
        other.createdAt == createdAt &&
        other.isPayed == isPayed &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        adType.hashCode ^
        period.hashCode ^
        ad.hashCode ^
        client.hashCode ^
        poster.hashCode ^
        createdAt.hashCode ^
        isPayed.hashCode ^
        endDate.hashCode;
  }
}
