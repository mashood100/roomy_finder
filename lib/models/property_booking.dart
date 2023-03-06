// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/user.dart';

class PropertyBooking {
  String id;
  PropertyAd ad;
  User poster;
  User client;
  int quantity;
  String status;
  DateTime checkIn;
  DateTime checkOut;
  String rentType;
  bool isPayed;
  DateTime? lastPaymentDate;
  DateTime? lastTransactionId;
  DateTime createdAt;

  PropertyBooking({
    required this.id,
    required this.ad,
    required this.poster,
    required this.client,
    required this.quantity,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.rentType,
    required this.isPayed,
    this.lastPaymentDate,
    this.lastTransactionId,
    required this.createdAt,
  });

  bool get isMine => poster.isMe;
  bool get isOffered => status == 'offered';
  bool get isPending => status == 'pending';
  num get budget {
    switch (rentType) {
      case "Monthly":
        return ad.monthlyPrice * quantity;
      case "Weekly":
        return ad.weeklyPrice * quantity;
      default:
        return ad.dailyPrice * quantity;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ad': ad.toMap(),
      'poster': poster.toMap(),
      'client': client.toMap(),
      'quantity': quantity,
      'status': status,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'rentType': rentType,
      'isPayed': isPayed,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'lastTransactionId': lastTransactionId?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PropertyBooking.fromMap(Map<String, dynamic> map) {
    return PropertyBooking(
      id: map['id'] as String,
      ad: PropertyAd.fromMap(map['ad'] as Map<String, dynamic>),
      poster: User.fromMap(map['poster'] as Map<String, dynamic>),
      client: User.fromMap(map['client'] as Map<String, dynamic>),
      quantity: map['quantity'] as int,
      status: map['status'] as String,
      checkIn: DateTime.parse(map['checkIn'] as String),
      checkOut: DateTime.parse(map['checkOut'] as String),
      rentType: map['rentType'] as String,
      isPayed: map['isPayed'] as bool,
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.parse(map['lastPaymentDate'] as String)
          : null,
      lastTransactionId: map['lastTransactionId'] != null
          ? DateTime.parse(map['lastTransactionId'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  // ignore: unused_element
  factory PropertyBooking.fromJson(String source) =>
      PropertyBooking.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant PropertyBooking other) {
    if (identical(this, other)) return true;

    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  @override
  String toString() {
    return 'PropertyBooking(id: $id, ad: $ad, poster: $poster, client: $client, quantity: $quantity, status: $status, checkIn: $checkIn, checkOut: $checkOut, rentType: $rentType, isPayed: $isPayed, lastPaymentDate: $lastPaymentDate, lastTransactionId: $lastTransactionId, createdAt: $createdAt)';
  }
}
