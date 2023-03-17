import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PropertyAdWidget extends StatelessWidget {
  const PropertyAdWidget({
    super.key,
    required this.ad,
    this.onTap,
    this.onFavoriteTap,
  });

  final PropertyAd ad;
  final void Function()? onTap;
  final void Function()? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Theme.of(context).scaffoldBackgroundColor,
        elevation: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: ad.images.isEmpty
                  ? const SizedBox(height: 150)
                  : CachedNetworkImage(
                      imageUrl: ad.images[0],
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, url, e) {
                        return const SizedBox(
                          width: 150,
                          height: 150,
                          child: CupertinoActivityIndicator(radius: 30),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() {
                    return Text(
                      formatMoney(
                        ad.prefferedRentDisplayPrice *
                            AppController
                                .instance.country.value.aedCurrencyConvertRate,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  Text(
                    "Posted ${relativeTimeText(ad.createdAt)}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ad.disPlayText,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    ad.preferedRentType,
                    style: const TextStyle(fontSize: 14),
                  )
                ],
              ),
            ),
            const Divider(),
            Container(
              padding: const EdgeInsets.only(
                left: 5,
                bottom: 10,
                right: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.location_solid),
                      const SizedBox(width: 5),
                      Text(
                        "${ad.address["location"]}",
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                    child: IconButton(
                      onPressed: onFavoriteTap ??
                          () {
                            _addAdToFavorite(
                              ad.toJson(),
                              "favorites-property-ads",
                            ).then((value) {
                              if (value) {
                                showToast("Ad added to favorites");
                              }
                            });
                          },
                      icon: onFavoriteTap != null
                          ? const Icon(Icons.delete, color: Colors.red)
                          : const Icon(Icons.favorite),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyAdOverviewItemWidget extends StatelessWidget {
  const PropertyAdOverviewItemWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class RoommateAdWidget extends StatelessWidget {
  const RoommateAdWidget({super.key, required this.ad, this.onTap});

  final RoommateAd ad;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Theme.of(context).scaffoldBackgroundColor,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: CachedNetworkImage(
                imageUrl: ad.images.isNotEmpty
                    ? ad.images[0]
                    : ad.poster.profilePicture,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorWidget: (ctx, url, e) {
                  return const SizedBox(
                    width: double.infinity,
                    height: 150,
                  );
                },
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Looking for a roommate",
                        style: TextStyle(fontSize: 14),
                      ),
                      Text("${ad.aboutYou["occupation"]},"
                          " Age(${ad.aboutYou["age"]})"),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 35,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Get.theme.appBarTheme.backgroundColor,
                      ),
                      onPressed: onTap,
                      child: const Text(
                        "See Information",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.only(
                left: 5,
                bottom: 10,
                right: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Budget",
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        formatMoney(ad.budget),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Moving date",
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        Jiffy(ad.createdAt).yMEd,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _addAdToFavorite(String item, String listKey) async {
  try {
    final pref = await SharedPreferences.getInstance();

    final favorites = pref.getStringList(listKey) ?? [];
    if (!favorites.contains(item)) {
      favorites.add(item);
    }
    pref.setStringList(listKey, favorites);
    return true;
  } catch (_) {
    return false;
  }
}
