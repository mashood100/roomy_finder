import 'dart:math';

String createDateTimeFileName([dynamic prefixSuffix = ""]) {
  final ran = Random();

  var suffix = "-$prefixSuffix${(ran.nextDouble() * 1000).truncate()}";

  return DateTime.now().toUtc().toIso8601String() + suffix;
}
