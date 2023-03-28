import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';

Future<void> dynamicLinkHandler(Uri uri) async {
  if (uri.path.contains("/ads/property-ad")) {
    final res = await Dio()
        .get("$API_URL/ads/property-ad/${uri.queryParameters['adId']}");
    if (res.statusCode == 200) {
      final ad = PropertyAd.fromMap(res.data);
      Get.to(() => ViewPropertyAd(ad: ad));
    } else {
      Get.log("Error handling dynamic url : ${uri.path}");
    }
  } else if (uri.path.contains("/ads/roommate-ad")) {
    final res = await Dio()
        .get("$API_URL/ads/roommate-ad/${uri.queryParameters['adId']}");
    if (res.statusCode == 200) {
      final ad = RoommateAd.fromMap(res.data);
      Get.to(() => ViewRoommateAdScreen(ad: ad));
    } else {
      Get.log("Error handling dynamic url : ${uri.path}");
    }
  }
}
