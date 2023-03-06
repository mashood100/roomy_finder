// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/models/user.dart';

class RoommateBooking {
  String id;
  RoommateAd ad;
  User poster;
  User client;
  String status;
  DateTime checkIn;
  DateTime checkOut;
  bool isPayed;
  DateTime? lastPaymentDate;
  DateTime? lastTransactionId;
  DateTime createdAt;

  RoommateBooking({
    required this.id,
    required this.ad,
    required this.poster,
    required this.client,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.isPayed,
    this.lastPaymentDate,
    this.lastTransactionId,
    required this.createdAt,
  });

  bool get isMine => poster.isMe;
  bool get isOffered => status == 'offered';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ad': ad.toMap(),
      'poster': poster.toMap(),
      'client': client.toMap(),
      'status': status,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'isPayed': isPayed,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'lastTransactionId': lastTransactionId?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RoommateBooking.fromMap(Map<String, dynamic> map) {
    return RoommateBooking(
      id: map['id'] as String,
      ad: RoommateAd.fromMap(map['ad'] as Map<String, dynamic>),
      poster: User.fromMap(map['poster'] as Map<String, dynamic>),
      client: User.fromMap(map['client'] as Map<String, dynamic>),
      status: map['status'] as String,
      checkIn: DateTime.parse(map['checkIn'] as String),
      checkOut: DateTime.parse(map['checkOut'] as String),
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
  factory RoommateBooking.fromJson(String source) =>
      RoommateBooking.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant RoommateBooking other) {
    if (identical(this, other)) return true;

    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
