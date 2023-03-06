// ignore_for_file: non_constant_identifier_names

import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

String relativeTimeText(DateTime dateTime) {
  if (dateTime.add(const Duration(minutes: 59)).isAfter(DateTime.now())) {
    return Jiffy(dateTime.toUtc()).fromNow();
  }

  if (dateTime.add(const Duration(hours: 23)).isAfter(DateTime.now())) {
    return Jiffy(dateTime.toUtc()).Hm;
  }

  if (dateTime.add(const Duration(days: 3)).isAfter(DateTime.now())) {
    return Jiffy(dateTime.toUtc()).Hm;
  }

  return Jiffy(dateTime.toUtc()).yMMMEd;
}

String formatMoney(num price, {String? currencyCode}) {
  final NumberFormat formatter =
      NumberFormat.currency(locale: "en_US", name: "AED", decimalDigits: 2);

  return formatter.format(price);
}
