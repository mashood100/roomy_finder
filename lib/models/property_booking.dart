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
  DateTime createdAt;
  String? paymentService;
  String? transactionId;

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
    required this.createdAt,
    this.paymentService,
    this.transactionId,
  });

  bool get isMine => poster.isMe;
  bool get isOffered => status == 'offered';
  bool get isPending => status == 'pending';

  /// The price of the ad with to the renttype choosen
  num get adPricePerRentype {
    switch (rentType) {
      case "Monthly":
        return ad.monthlyPrice;
      case "Weekly":
        return ad.weeklyPrice;
      default:
        return ad.dailyPrice;
    }
  }

  /// The total renting fee of the booking (depends on the quantity
  /// booked and rent duration)
  num get rentFee {
    final num fee;
    switch (rentType) {
      case "Monthly":
        fee = ad.monthlyPrice * quantity * rentPeriod;
        break;
      case "Weekly":
        fee = ad.weeklyPrice * quantity * rentPeriod;
        break;
      default:
        fee = ad.dailyPrice * quantity * rentPeriod;
    }
    return fee;
  }

  /// Commission fee (10% of rent fee[rentFee])
  num get commissionFee {
    switch (rentType) {
      case "Monthly":
      case "Weekly":
        return rentFee * 0.1;
      default:
        return rentFee * 0.05;
    }
  }

  /// TAV (5% of commission fee [commissionFee])
  num get vatFee => commissionFee * 0.05;

  /// The sum of the rent fee and the commission fee
  num get displayPrice => rentFee + commissionFee;

  num calculateFee(num percentage) {
    return (rentFee + commissionFee + vatFee) * percentage;
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

  String get capitaliezedStatus =>
      status.replaceFirst(status[0], status[0].toUpperCase());

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
      'createdAt': createdAt.toIso8601String(),
      'paymentService': paymentService,
      'transactionId': transactionId,
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
      createdAt: DateTime.parse(map['createdAt'] as String),
      paymentService: map['paymentService'] != null
          ? map['paymentService'] as String
          : null,
      transactionId:
          map['transactionId'] != null ? map['transactionId'] as String : null,
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
}
