import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:get/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:share_plus/share_plus.dart';

Future<Uri> _createShareChanceLink(ad) async {
  final String title;
  final String description;
  final String? imageUrl;
  final String adId;
  final String adType;

  if (ad is PropertyAd) {
    title = "${ad.type} for rent. ${formatMoney(ad.prefferedRentDisplayPrice)}";
    description = "${ad.quantity} ${ad.type}${ad.quantity > 1 ? 's' : ''} "
        "in ${ad.address["city"]}, ${ad.address["location"]}";
    imageUrl = ad.images.isNotEmpty ? ad.images[0] : null;
    adId = ad.id;
    adType = "property-ad";
  } else if (ad is RoommateAd) {
    title = "${ad.action}. Budget : ${formatMoney(ad.budget)}";
    description = "${ad.address["city"]}, ${ad.address["location"]}";
    imageUrl = ad.images.isNotEmpty ? ad.images[0] : null;
    adId = ad.id;
    adType = "roommate-ad";
  } else {
    throw "Invalid ad";
  }
  final packageInfo = await PackageInfo.fromPlatform();
  final DynamicLinkParameters dynamicLinkParams = DynamicLinkParameters(
    uriPrefix: DYNAMIC_LINK_URL,
    link: Uri.parse('$DYNAMIC_LINK_URL/ads/$adType?adId=$adId'),
    androidParameters: AndroidParameters(packageName: packageInfo.packageName),
    iosParameters: IOSParameters(bundleId: packageInfo.packageName),
    socialMetaTagParameters: SocialMetaTagParameters(
      imageUrl: imageUrl != null ? Uri.parse(imageUrl) : null,
      title: title,
      description: description,
    ),
  );

  final dynamicLink =
      await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
  return dynamicLink.shortUrl;
}

Future<void> shareAd(dynamic ad) async {
  try {
    final uri = await _createShareChanceLink(ad);

    Share.share('$uri');
  } catch (e, trace) {
    Get.log("$e");
    Get.log("$trace");
  }
}
