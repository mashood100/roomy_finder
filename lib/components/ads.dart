import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roomy_finder/components/custom_button.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/utilities/data.dart';

class PropertyAdWidget extends StatelessWidget {
  const PropertyAdWidget({
    super.key,
    required this.ad,
    this.onTap,
    this.onFavoriteTap,
    this.isMiniView = false,
  });

  final PropertyAd ad;
  final void Function()? onTap;
  final void Function()? onFavoriteTap;
  final bool isMiniView;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: (ad.images.isEmpty)
                    ? Image.asset(
                        AssetImages.defaultRoomPNG,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : LoadingProgressImage(
                        image: CachedNetworkImageProvider(ad.images[0]),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ad.type,
                          style: TextStyle(
                            fontSize: isMiniView ? 9 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: "Budget: "),
                              TextSpan(
                                text:
                                    "${formatMoney(ad.prefferedRentDisplayPrice * AppController.convertionRate)}/${ad.preferedRentType}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            style: TextStyle(
                              fontSize: isMiniView ? 9 : 12,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isMiniView)
                    CustomButton(
                      "View details",
                      onPressed: onTap,
                      height: 30,
                      boldLabel: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 0,
                      ),
                    )
                ],
              ),
            ),
            if (!isMiniView && ad.description != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  ad.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    color: Colors.black54,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(
                left: 10,
                bottom: 10,
                right: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.location_solid,
                    color: ROOMY_PURPLE,
                    size: isMiniView ? 12 : 15,
                  ),
                  Expanded(
                    child: Text(
                      "${ad.address["city"]}, ${ad.address["location"]}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMiniView ? 9 : 12,
                        fontWeight: FontWeight.w300,
                        color: Colors.black54,
                      ),
                    ),
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

// class PropertyAdMiniWidget extends StatelessWidget {
//   const PropertyAdMiniWidget({super.key, required this.ad, this.onTap});

//   final PropertyAd ad;
//   final void Function()? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Card(
//         child: ClipRRect(
//           borderRadius: const BorderRadius.all(
//             Radius.circular(10),
//           ),
//           child: Stack(
//             alignment: Alignment.bottomCenter,
//             children: [
//               if (ad.images.isEmpty)
//                 Image.asset(
//                   "assets/images/default_room.png",
//                   width: double.infinity,
//                   height: double.infinity,
//                   fit: BoxFit.fill,
//                 )
//               else
//                 LoadingProgressImage(
//                   image: CachedNetworkImageProvider(ad.images[0]),
//                   width: double.infinity,
//                   height: double.infinity,
//                   fit: BoxFit.cover,
//                 ),
//               DefaultTextStyle.merge(
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontSize: 10,
//                 ),
//                 child: Container(
//                   color: Colors.white,
//                   padding: const EdgeInsets.all(8.0),
//                   width: double.infinity,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     // mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         ad.type,
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         "${ad.address["location"]},"
//                         " ${ad.address["city"]}",
//                       ),
//                       const SizedBox(height: 5),
//                       Text(
//                         formatMoney(
//                           ad.prefferedRentDisplayPrice *
//                               AppController.convertionRate,
//                         ),
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class RoommateAdWidget extends StatelessWidget {
  const RoommateAdWidget({
    super.key,
    required this.ad,
    this.onTap,
    this.seeInformationLabel = "View Ad",
    this.isMiniView = false,
    this.onChat,
  });

  final RoommateAd ad;
  final void Function()? onTap;
  final String seeInformationLabel;
  final bool isMiniView;
  final void Function()? onChat;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: (ad.images.isEmpty)
                    ? Image.asset(
                        AssetImages.defaultRoomPNG,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : LoadingProgressImage(
                        image: CachedNetworkImageProvider(ad.images[0]),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${ad.poster.firstName}, ${ad.aboutYou["age"] ?? "N/A"}",
                          style: TextStyle(
                            fontSize: isMiniView ? 9 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: "Budget: "),
                              TextSpan(
                                text:
                                    "${formatMoney(ad.budget * AppController.convertionRate)}/${ad.rentType}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            style: TextStyle(
                              fontSize: isMiniView ? 9 : 12,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isMiniView && !ad.isMine)
                    CustomButton(
                      "   Chat   ",
                      onPressed: onChat,
                      height: 30,
                      boldLabel: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 0,
                      ),
                    )
                ],
              ),
            ),
            if (!isMiniView && ad.description != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  ad.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    color: Colors.black54,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(
                left: 10,
                bottom: 10,
                right: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.location_solid,
                    color: ROOMY_PURPLE,
                    size: isMiniView ? 12 : 15,
                  ),
                  Expanded(
                    child: Text(
                      "${ad.address["city"]}, ${ad.address["location"]}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMiniView ? 9 : 12,
                        fontWeight: FontWeight.w300,
                        color: Colors.black54,
                      ),
                    ),
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

class RoommateUser extends StatelessWidget {
  const RoommateUser({
    super.key,
    required this.user,
    this.onTap,
    this.isMiniView = false,
    this.onChat,
  });

  final User user;
  final void Function()? onTap;
  final bool isMiniView;
  final void Function()? onChat;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Builder(builder: (context) {
                  if (user.profilePicture == null) {
                    final name = user.gender == null
                        ? AssetImages.defaultRoomPNG
                        : user.gender == "Male"
                            ? AssetImages.defaultMalePNG
                            : AssetImages.defaultFemalePNG;

                    return LoadingProgressImage(
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(9),
                      ),
                      image: AssetImage(name),
                    );
                  }
                  return LoadingProgressImage(
                    fit: BoxFit.cover,
                    width: double.infinity,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(9),
                    ),
                    image: CachedNetworkImageProvider(user.profilePicture!),
                  );
                }),
              ),
              // const Divider(color: ROOMY_ORANGE, height: 1),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName),
                        if (user.country != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.location_solid,
                                color: ROOMY_PURPLE,
                                size: isMiniView ? 12 : 15,
                              ),
                              Text(
                                user.country!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (!isMiniView && !user.isMe)
                      CustomButton(
                        "   Chat   ",
                        onPressed: onChat,
                        height: 30,
                        boldLabel: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 0,
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
