import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/custom_button.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/helpers/roomy_notification.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/models/user/user.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/chat/chat_room/chat_room_screen.dart';
import 'package:roomy_finder/screens/user/update_profile.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/utilities/data.dart';

class UserPublicProfile extends StatefulWidget {
  const UserPublicProfile({super.key, required this.user});
  final User user;

  @override
  State<UserPublicProfile> createState() => _UserPublicProfileState();
}

class _UserPublicProfileState extends State<UserPublicProfile> {
  User get user => widget.user;
  AboutMe get aboutMe => widget.user.aboutMe;

  var _homePropertyAds = <PropertyAd>[];
  var _homeRoommateAds = <RoommateAd>[];

  late final Timer _timer;
  var _hasFechError = false;
  bool _isLoadingHomeAds = false;

  @override
  void initState() {
    super.initState();
    _fetchHommeAds();
    _upUserProfiles();

    // _pageController = PageController(initialPage: _currentPage);

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_hasFechError) _fetchHommeAds();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  Future<void> _upUserProfiles() async {
    try {
      final other = await ApiService.fetchUser(user.id);
      if (other != null) user.updateFrom(other);
    } catch (_) {}
  }

  Future<void> chatWithUser() async {
    if (AppController.me.isGuest) {
      RoomyNotificationHelper.showRegistrationRequiredToChat();
    } else {
      moveToChatRoom(AppController.me, user);
    }
  }

  Future<void> completeMyProfile() async {
    await Get.to(() => const UpdateUserProfileScreen());
    await _upUserProfiles();
    setState(() {});
  }

  Future<void> _fetchHommeAds() async {
    try {
      _isLoadingHomeAds = true;
      // _failedToLoadHomeAds = false;
      _hasFechError = false;

      _homePropertyAds = await ApiService.getUserPropertyAds(user.id);
      _homeRoommateAds = await ApiService.getUserRoommateAds(user.id);
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      // _failedToLoadHomeAds = true;
      _hasFechError = true;
    } finally {
      _isLoadingHomeAds = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = MediaQuery.sizeOf(context).width ~/ 150;

    var languages = aboutMe.languages ?? [];

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Builder(builder: (context) {
                      if (user.profilePicture == null) {
                        final name = user.gender == null
                            ? AssetImages.defaultRoomPNG
                            : user.gender == "Male"
                                ? AssetImages.defaultMalePNG
                                : AssetImages.defaultFemalePNG;

                        return LoadingProgressImage(
                          fit: BoxFit.cover,
                          image: AssetImage(name),
                          width: double.infinity,
                          height: 200,
                        );
                      }
                      return GestureDetector(
                        onTap: () => Get.to(() => ViewImages(
                              images: [
                                CachedNetworkImageProvider(user.profilePicture!)
                              ],
                              title: user.fullName,
                            )),
                        child: LoadingProgressImage(
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                          image:
                              CachedNetworkImageProvider(user.profilePicture!),
                        ),
                      );
                    }),
                  ],
                ),
                if (user.isMe && aboutMe.percentageCompleted != 100)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(
                          value: (aboutMe.percentageCompleted / 100)
                              .truncateToDouble(),
                          minHeight: 8,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${aboutMe.percentageCompleted}%"),
                            TextButton(
                              onPressed: completeMyProfile,
                              child: const Text("Complete your profile"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  user.type.toLowerCase(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!user.isMe)
                            CustomButton(
                              "  Chat  ",
                              onPressed: chatWithUser,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                            ),
                        ],
                      ),
                      const Divider(height: 20),
                      // Description

                      if (aboutMe.description != null &&
                          aboutMe.description!.isNotEmpty) ...[
                        ReadMoreText(
                          aboutMe.description!,
                          trimLines: 3,
                          trimCollapsedText: "Read more",
                          trimExpandedText: "Read less",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                          trimMode: TrimMode.Line,
                          colorClickableText: ROOMY_PURPLE,
                        ),
                        const Divider(height: 20),
                      ],

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          (
                            label: "Gender:",
                            value: user.gender ?? "N/A",
                          ),
                          (
                            label: "Nationality:",
                            value: user.country ?? "N/A",
                          ),
                          (
                            label: "Age:",
                            value: aboutMe.age ?? "N/A",
                          ),
                          (
                            label: "Occupation:",
                            value: aboutMe.occupation ?? "N/A",
                          ),
                          (
                            label: "Lifestyle:",
                            value: aboutMe.lifeStyle ?? "N/A",
                          ),
                          (
                            label: "Sign:",
                            value: aboutMe.astrologicalSign ?? "N/A",
                          ),
                          (
                            label: "Languages:",
                            value: languages.isEmpty
                                ? "N/A"
                                : languages.join(", "),
                          ),
                        ].map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(e.label),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "${e.value}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 20),
                      Text(
                        "Ads from ${user.fullName}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_isLoadingHomeAds)
                        const Center(
                          child: Text(
                            "Loading...",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      GridView.count(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _homePropertyAds.map((e) {
                          return PropertyAdWidget(
                            ad: e,
                            isMiniView: true,
                            onTap: () {
                              Get.to(() => ViewPropertyAd(
                                    ad: e,
                                    readOnly: true,
                                  ));
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _homeRoommateAds.map((e) {
                          return RoommateAdWidget(
                            ad: e,
                            isMiniView: true,
                            onTap: () {
                              Get.to(() => ViewRoommateAdScreen(
                                    ad: e,
                                    readOnly: true,
                                  ));
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoadingHomeAds) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 15),
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              onPressed: () => Get.back(),
              icon: const Icon(CupertinoIcons.back),
            ),
          ),
        ],
      ),
    );
  }
}
