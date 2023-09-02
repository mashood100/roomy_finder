// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/user/user.dart';

class PropertyBooking {
  String id;
  User poster;
  User client;
  PropertyAd ad;
  int quantity;
  String status;
  DateTime checkIn;
  DateTime checkOut;
  String rentType;
  bool isPayed;
  DateTime createdAt;
  String? paymentService;
  String? transactionId;
  bool isViewedByLandlord;
  bool isViewedByClient;
  String? cancelMessage;
  final num rentFee;
  final num commissionFee;
  final num vatPercentage;
  final num? depositFee;

  PropertyBooking({
    required this.id,
    required this.poster,
    required this.client,
    required this.ad,
    required this.quantity,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.rentType,
    required this.isPayed,
    required this.createdAt,
    this.paymentService,
    this.transactionId,
    this.isViewedByLandlord = true,
    this.isViewedByClient = true,
    this.cancelMessage,
    required this.rentFee,
    required this.commissionFee,
    required this.vatPercentage,
    this.depositFee,
  });

  bool get isMine => poster.isMe;
  bool get isOffered => status == 'offered';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';
  bool get isDeclined => status == 'declined';
  bool get isActive => status == 'active';

  /// The sum of the rent fee and the commission fee
  num get displayPrice => rentFee + commissionFee;

  num calculateFee(num percentage) {
    return (rentFee + commissionFee + vatPercentage) * percentage;
  }

  /// The number of periods(days,weeks,monyhs) the rent will last
  int get rentPeriod {
    // The difference in milliseconds between the checkout and the checkin date
    final checkOutCheckInMillisecondsDifference =
        checkOut.millisecondsSinceEpoch - checkIn.millisecondsSinceEpoch;

    final int period;

    switch (rentType) {
      case "Monthly":
        const oneMothDuration = 1000 * 3600 * 24 * 30;
        period =
            (checkOutCheckInMillisecondsDifference / oneMothDuration).ceil();

        break;
      case "Weekly":
        const oneWeekDuration = 1000 * 3600 * 24 * 7;
        period =
            (checkOutCheckInMillisecondsDifference / oneWeekDuration).ceil();
        break;
      default:
        const oneDayDuration = 1000 * 3600 * 24;
        period =
            (checkOutCheckInMillisecondsDifference / oneDayDuration).ceil();
        break;
    }

    return period;
  }

  String get rentPeriodUnit {
    final String rentPeriodUnit;
    switch (rentType) {
      case "Monthly":
        rentPeriodUnit = "Month";
        break;
      case "Weekly":
        rentPeriodUnit = "Week";
        break;
      default:
        rentPeriodUnit = "Day";
    }
    return rentPeriodUnit;
  }

  /// VAT (5% of commission fee [commissionFee])
  num get vatFee => commissionFee * (vatPercentage / 100);

  String get capitaliezedStatus =>
      status.replaceFirst(status[0], status[0].toUpperCase());

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'poster': poster.toMap(),
      'client': client.toMap(),
      'ad': ad.toMap(),
      'quantity': quantity,
      'status': status,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'rentType': rentType,
      'isPayed': isPayed,
      'createdAt': createdAt.toIso8601String(),
      'paymentService': paymentService,
      'transactionId': transactionId,
      'isViewedByLandlord': isViewedByLandlord,
      'isViewedByClient': isViewedByClient,
      'cancelMessage': cancelMessage,
      'rentFee': rentFee,
      'commissionFee': commissionFee,
      'vatFee': vatPercentage,
      'depositFee': depositFee,
    };
  }

  factory PropertyBooking.fromMap(Map<String, dynamic> map) {
    if (map["rentFee"] == null) map["rentFee"] = map["virtualRentFee"];
    if (map["commissionFee"] == null) {
      map["commissionFee"] = map["virtualCommissionFee"];
    }
    if (map["vatFee"] == null) map["vatFee"] = map["virtualVatPercentage"];
    if (map["depositFee"] == null) map["depositFee"] = map["virtualDepositFee"];

    return PropertyBooking(
      id: map['id'] as String,
      poster: User.fromMap(map['poster'] as Map<String, dynamic>),
      client: User.fromMap(map['client'] as Map<String, dynamic>),
      ad: PropertyAd.fromMap(map['ad'] as Map<String, dynamic>),
      quantity: map['quantity'] as int,
      status: map['status'] as String,
      checkIn: DateTime.parse(map['checkIn'] as String),
      checkOut: DateTime.parse(map['checkOut'] as String),
      rentType: map['rentType'] as String,
      isPayed: map['isPayed'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      paymentService: map['paymentService'] != null
          ? map['paymentService'] as String
          : null,
      transactionId:
          map['transactionId'] != null ? map['transactionId'] as String : null,
      isViewedByLandlord: map['isViewedByLandlord'] as bool,
      isViewedByClient: map['isViewedByClient'] as bool,
      cancelMessage:
          map['cancelMessage'] != null ? map['cancelMessage'] as String : null,
      rentFee: map['rentFee'] as num,
      commissionFee: map['commissionFee'] as num,
      vatPercentage: map['vatFee'] as num,
      depositFee: map['depositFee'] != null ? map['depositFee'] as num : null,
    );
  }

  String toJson() => json.encode(toMap());

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

  void updateFrom(PropertyBooking other) {
    // id= other.id;
    ad = other.ad;
    poster = other.poster;
    client = other.client;
    quantity = other.quantity;
    status = other.status;
    checkIn = other.checkIn;
    checkOut = other.checkOut;
    rentType = other.rentType;
    isPayed = other.isPayed;
    createdAt = other.createdAt;
    paymentService = other.paymentService;
    transactionId = other.transactionId;
    isViewedByClient = other.isViewedByClient;
    isViewedByLandlord = other.isViewedByLandlord;
  }

  bool get isOverDue {
    return checkIn.isBefore(DateTime.now().subtract(const Duration(days: 3)));
  }
}
