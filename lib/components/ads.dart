import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/utilities/data.dart';

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
      // onTap: onTap,
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
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${ad.type} to rent",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.room, color: ROOMY_ORANGE),
                          const SizedBox(width: 5),
                          Text(
                            "${ad.address["location"]}",
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Obx(() {
                    return Text(
                      formatMoney(
                        ad.prefferedRentDisplayPrice *
                            AppController
                                .instance.country.value.aedCurrencyConvertRate,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(),
            Container(
              padding: const EdgeInsets.only(right: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(builder: (context) {
                    final String asset;
                    switch (ad.type) {
                      case "Bed":
                        asset = "assets/icons/bed.png";
                        break;
                      case "Partition":
                        asset = "assets/icons/partition.png";
                        break;
                      case "Room":
                        asset = "assets/icons/regular_room.png";
                        break;
                      default:
                        asset = "assets/icons/master_room.png";
                    }
                    return Image.asset(asset, height: 30);
                  }),
                  Text(
                    "Available ${ad.quantity - ad.quantityTaken}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Taken ${ad.quantityTaken}",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: ROOMY_ORANGE,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: ROOMY_ORANGE),
                      ),
                      onPressed: onTap,
                      child: const Text(
                        "View Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // SizedBox(
                  //   height: 30,
                  //   child: IconButton(
                  //     onPressed: onFavoriteTap ??
                  //         () {
                  //           _addAdToFavorite(
                  //             ad.toJson(),
                  //             "favorites-property-ads",
                  //           ).then((value) {
                  //             if (value) {
                  //               showToast("Ad added to favorites");
                  //             }
                  //           });
                  //         },
                  //     icon: onFavoriteTap != null
                  //         ? const Icon(Icons.delete, color: Colors.red)
                  //         : const Icon(Icons.favorite),
                  //   ),
                  // )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialPreferenceWidget extends StatelessWidget {
  const SocialPreferenceWidget({
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
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            Expanded(child: icon),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: ROOMY_ORANGE,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyAdMiniWidget extends StatelessWidget {
  const PropertyAdMiniWidget({super.key, required this.ad, this.onTap});

  final PropertyAd ad;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CachedNetworkImage(
                imageUrl: ad.images.isNotEmpty
                    ? ad.images[0]
                    : ad.poster.profilePicture,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (ctx, url, e) {
                  return const SizedBox();
                },
              ),
              DefaultTextStyle.merge(
                style: TextStyle(
                  color: Get.isDarkMode ? Colors.white : ROOMY_PURPLE,
                  fontSize: 12,
                ),
                child: Container(
                  color: Get.theme.scaffoldBackgroundColor.withOpacity(0.5),
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: ad.type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(text: " for rent"),
                            ]),
                          ),
                          Text(
                            "${ad.address["location"]},"
                            " ${ad.address["city"]}",
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: ROOMY_ORANGE,
                        ),
                        child: Text(
                          "${ad.quantity - ad.quantityTaken}".padLeft(2, "0"),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RoommateAdWidget extends StatelessWidget {
  const RoommateAdWidget({
    super.key,
    required this.ad,
    this.onTap,
    this.seeInformationLabel = "View Ad",
  });

  final RoommateAd ad;
  final void Function()? onTap;
  final String seeInformationLabel;

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
                      Text(
                        ad.action,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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
                        backgroundColor: ROOMY_ORANGE,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        side: const BorderSide(color: ROOMY_ORANGE),
                      ),
                      onPressed: onTap,
                      child: Text(
                        seeInformationLabel,
                        style: const TextStyle(color: Colors.white),
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

class RoommateAdMiniWidget extends StatelessWidget {
  const RoommateAdMiniWidget({super.key, required this.ad, this.onTap});

  final RoommateAd ad;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CachedNetworkImage(
                imageUrl: ad.images.isNotEmpty
                    ? ad.images[0]
                    : ad.poster.profilePicture,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (ctx, url, e) {
                  return const SizedBox();
                },
              ),
              DefaultTextStyle.merge(
                style: TextStyle(
                  color: Get.isDarkMode ? Colors.white : ROOMY_PURPLE,
                  fontSize: 12,
                ),
                child: Container(
                  color: Get.theme.scaffoldBackgroundColor.withOpacity(0.5),
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: ad.poster.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                          ),
                          SizedBox(
                            width: Get.width * 0.25,
                            child: Text(
                              "${ad.address["city"]},"
                              " ${ad.address["location"]}",
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Text(
                          formatMoney(ad.budget * AppController.convertionRate),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ROOMY_ORANGE,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
