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
                  ? Image.asset(
                      "assets/images/default_ad_picture.jpg",
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    )
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Taken ${ad.quantityTaken}",
                    style: const TextStyle(
                      color: ROOMY_ORANGE,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 30,
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
            const SizedBox(height: 10),
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
              if (ad.images.isEmpty)
                Image.asset(
                  "assets/images/default_ad_picture.jpg",
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                CachedNetworkImage(
                  imageUrl: ad.images[0],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (ctx, url, e) {
                    return const SizedBox();
                  },
                ),
              DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.type,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${ad.address["location"]},"
                        " ${ad.address["city"]}",
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatMoney(
                          ad.prefferedRentDisplayPrice *
                              AppController.convertionRate,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
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
              child: (ad.images.isEmpty)
                  ? Image.asset(
                      "assets/images/default_ad_picture.jpg",
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
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
                      Text("${ad.aboutYou["occupation"] ?? ""}"
                          " Age(${ad.aboutYou["age"] ?? "N/A"})"),
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
                        formatMoney(ad.budget * AppController.convertionRate),
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
                        ad.movingDate != null
                            ? Jiffy(ad.movingDate!).yMEd
                            : "N/A",
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
              if (ad.images.isEmpty)
                Image.asset(
                  "assets/images/default_ad_picture.jpg",
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                CachedNetworkImage(
                  imageUrl: ad.images[0],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (ctx, url, e) {
                    return const SizedBox();
                  },
                ),
              DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ad.poster.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${ad.address["location"]},"
                            " ${ad.address["city"]}",
                          ),
                          const SizedBox(height: 5),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: "Budget ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: formatMoney(
                                      ad.budget * AppController.convertionRate),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
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

/// To be to use to display information like amenities, preferences,
/// about me ...

class AdOverViewItem extends StatelessWidget {
  const AdOverViewItem({
    super.key,
    required this.icon,
    required this.title,
    this.subTitle,
    this.subTitleColor,
  });
  final Widget icon;
  final Widget title;
  final Widget? subTitle;
  final Color? subTitleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            title,
            if (subTitle != null)
              DefaultTextStyle.merge(
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: subTitleColor,
                ),
                child: subTitle!,
              ),
          ],
        ),
      ],
    );
  }
}
