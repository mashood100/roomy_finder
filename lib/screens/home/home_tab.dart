import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/blog_post.dart';
import 'package:roomy_finder/models/country.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/find_properties.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/post_roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/blog_post/view_post.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _HomeTabController extends LoadingController {
  final List<BlogPost> _blogPosts = [];
  final _targetAds = "All".obs;

  final _homePropertyAds = <PropertyAd>[];
  final _homeRoommateAds = <RoommateAd>[];
  final _isLoadingHomeAds = true.obs;
  final _failedToLoadHomeAds = false.obs;

  @override
  void onInit() {
    super.onInit();

    _fetchHommeAds();

    _fetBlogPost();
    FirebaseMessaging.onMessage.asBroadcastStream().listen((event) async {
      final data = event.data;

      switch (data["event"]) {
        case "plan-upgraded-successfully":
          AppController.instance.user.update((val) {
            if (val == null) return;
            val.isPremium = true;
          });
          final pref = await SharedPreferences.getInstance();
          if (pref.get("user") != null) {
            AppController.instance.saveUser();
          }
          showToast("Plan upgraded successfully");

          break;
        default:
      }
    });
  }

  Future<void> _fetchHommeAds() async {
    try {
      _isLoadingHomeAds(true);
      _failedToLoadHomeAds(false);

      final res = await Dio().get("$API_URL/ads/recomended");

      // Property ads
      final propertyAds = (res.data["propertyAds"] as List).map((e) {
        try {
          var propertyAd = PropertyAd.fromMap(e);
          return propertyAd;
        } catch (e) {
          return null;
        }
      });
      _homePropertyAds.clear();
      _homePropertyAds.addAll(propertyAds.whereType<PropertyAd>());

      // Roommate ads
      final roommateAds = (res.data["roommateAds"] as List).map((e) {
        try {
          var propertyAd = RoommateAd.fromMap(e);
          return propertyAd;
        } catch (e) {
          return null;
        }
      });
      _homeRoommateAds.clear();
      _homeRoommateAds.addAll(roommateAds.whereType<RoommateAd>());
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      _failedToLoadHomeAds(true);
    } finally {
      _isLoadingHomeAds(false);
      update();
    }
  }

  Future<void> _fetBlogPost() async {
    try {
      final posts = await BlogPost.getBlogPost();
      _blogPosts.clear();
      _blogPosts.addAll(posts);
      update(["blogposts-get-builder"]);
    } catch (e) {
      Get.log('$e');
    }
  }

  void _toggleThemeMode() {
    AppController.setThemeMode(
        Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
    Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> changeAppCountry(BuildContext context) async {
    final country = await showModalBottomSheet<Country?>(
      context: context,
      builder: (context) {
        return CupertinoScrollbar(
          child: ListView(
            children: supporttedCountries
                .map(
                  (e) => ListTile(
                    leading: CircleAvatar(child: Text(e.flag)),
                    onTap: () => Get.back(result: e),
                    title: Text(e.name),
                    trailing: AppController.instance.country.value == e
                        ? const Icon(
                            Icons.check_circle_sharp,
                            color: Colors.green,
                          )
                        : null,
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (country != null) {
      if (country.code != Country.UAE.code &&
          country.code != Country.SAUDI_ARABIA.code) {
        showToast('Comming soon');
        return;
      }
      AppController.instance.country(country);
    }
  }
}

class HomeTab extends StatelessWidget implements HomeScreenSupportable {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_HomeTabController());
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          controller._fetchHommeAds(),
          controller._fetBlogPost(),
        ]);
      },
      child: GetBuilder<_HomeTabController>(builder: (controller) {
        return Padding(
          padding: const EdgeInsets.symmetric(),
          child: CustomScrollView(
            slivers: [
              // const SliverToBoxAdapter(
              //   child: HomeUserInfo(),
              // ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Image.asset(
                          "assets/images/appartment-inner-view.jpg",
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Account detail
                            Container(
                              width: Get.width,
                              color: Colors.grey.shade300,
                              child: Builder(
                                builder: (context) {
                                  if (AppController.me.isGuest) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Get.offAllNamed("/registration");
                                          },
                                          child: const Text(
                                            "REGISTER",
                                            style: TextStyle(
                                              color: ROOMY_PURPLE,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Get.offAllNamed("/login");
                                          },
                                          child: const Text(
                                            "LOGIN",
                                            style: TextStyle(
                                              color: ROOMY_ORANGE,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    CupertinoIcons
                                                        .person_alt_circle_fill,
                                                    color: ROOMY_ORANGE,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    AppController.me.fullName,
                                                    style: const TextStyle(
                                                      color: ROOMY_PURPLE,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.key,
                                                    color: ROOMY_ORANGE,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Builder(builder: (context) {
                                                    final type =
                                                        AppController.me.type;
                                                    return Text(
                                                      type.replaceFirst(
                                                        type[0],
                                                        type[0].toUpperCase(),
                                                      ),
                                                      style: const TextStyle(
                                                        color: ROOMY_PURPLE,
                                                        fontSize: 16,
                                                      ),
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ],
                                          ),
                                          AppController.me.ppWidget(size: 25)
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            //  Ads types
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: ROOMY_PURPLE,
                              ),
                              child: Row(
                                children: ["Roommate", "Room", "All"].map((e) {
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        controller._targetAds(e);
                                        controller.update();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          color:
                                              controller._targetAds.value == e
                                                  ? Colors.white
                                                  : ROOMY_PURPLE,
                                        ),
                                        child: Text(
                                          e,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                controller._targetAds.value == e
                                                    ? ROOMY_PURPLE
                                                    : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Search box
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: TextField(
                                decoration: InputDecoration(
                                  fillColor: Colors.white,
                                  hintText: "Search",
                                  suffixIcon: SizedBox(
                                    child: IconButton(
                                      onPressed: () {
                                        switch (controller._targetAds.value) {
                                          case "Room":
                                            Get.to(() {
                                              return const FindPropertiesAdsScreen();
                                            });
                                            break;
                                          default:
                                        }
                                      },
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: ROOMY_PURPLE,
                                        ),
                                        child: const Icon(
                                          Icons.search,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.fromLTRB(12, 10, 12, 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                textInputAction: TextInputAction.search,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Post ad button
                            SizedBox(
                              width: Get.width * 0.4,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (AppController.me.isGuest) {
                                    Get.offAllNamed('/login');
                                  } else if (AppController.me.isLandlord) {
                                    Get.to(() => const PostPropertyAdScreen());
                                  } else if (AppController.me.isRoommate) {
                                    Get.to(() {
                                      return const PostRoommateAdScreen(
                                        isPremium: true,
                                      );
                                    });
                                  }
                                },
                                child: DefaultTextStyle(
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: ROOMY_ORANGE,
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      if (AppController.me.isGuest) {
                                        return const Text("Post Ad");
                                      }
                                      if (AppController.me.isLandlord) {
                                        return const Text("Post Property");
                                      }
                                      return const Text("Post Roommate");
                                    },
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                    if (controller._targetAds.value == "Room" ||
                        controller._targetAds.value == "All") ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Properties",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ROOMY_ORANGE,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.to(() {
                                  return const FindPropertiesAdsScreen();
                                });
                              },
                              child: const Text("See all"),
                            ),
                          ],
                        ),
                      ),
                      GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        children: List.generate(
                          (controller._homePropertyAds.length ~/ 2) * 2,
                          (ind) {
                            if (controller._isLoadingHomeAds.isTrue) {
                              return const Card(
                                child: CupertinoActivityIndicator(radius: 30),
                              );
                            }
                            final ad = controller._homePropertyAds[ind];
                            return PropertyAdMiniWidget(
                              ad: ad,
                              onTap: () {
                                Get.to(() => ViewPropertyAd(ad: ad));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    if (controller._targetAds.value == "Roommate" ||
                        controller._targetAds.value == "All") ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Roommates",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ROOMY_ORANGE,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text("See all"),
                            ),
                          ],
                        ),
                      ),
                      GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        children: List.generate(
                          (controller._homeRoommateAds.length ~/ 2) * 2,
                          (ind) {
                            if (controller._isLoadingHomeAds.isTrue) {
                              return const Card(
                                child: CupertinoActivityIndicator(radius: 30),
                              );
                            }
                            final ad = controller._homeRoommateAds[ind];
                            return RoommateAdMiniWidget(
                              ad: ad,
                              onTap: () {
                                Get.to(() => ViewRoommateAdScreen(ad: ad));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Blog posts",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ROOMY_ORANGE,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: GetBuilder<_HomeTabController>(
                    id: "blogposts-get-builder",
                    builder: (controller) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: controller._blogPosts
                              .map((e) => BlogPostWidget(
                                    post: e,
                                    onTap: () {
                                      Get.to(() => ViewBlogPostScreen(post: e));
                                    },
                                  ))
                              .toList(),
                        ),
                      );
                    }),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  AppBar get appBar {
    final controller = Get.put(_HomeTabController());
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      // automaticallyImplyLeading: false,
      leadingWidth: 30,
      title: SizedBox(
        width: Get.width,
        child: Builder(builder: (context) {
          return Row(
            children: [
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Roomy",
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: "FINDER",
                      style: TextStyle(color: Color.fromRGBO(255, 123, 77, 1)),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: controller._toggleThemeMode,
                icon: Theme.of(context).brightness == Brightness.light
                    ? const Icon(Icons.dark_mode, color: Colors.white)
                    : const Icon(Icons.light_mode, color: Colors.white),
              ),
              Obx(() {
                return TextButton(
                  onPressed: () => controller.changeAppCountry(context),
                  // icon: const Icon(Icons.arrow_drop_down, size: 40),
                  child: Text(
                    AppController.instance.country.value.flag,
                    style: const TextStyle(fontSize: 25),
                  ),
                );
              }),
              // Builder(builder: (context) {
              //   return IconButton(
              //     onPressed: () {
              //       if (Scaffold.of(context).isDrawerOpen) {
              //         Scaffold.of(context).openDrawer();
              //       } else {
              //         Scaffold.of(context).closeDrawer();
              //       }
              //     },
              //     icon: Icon(Icons.menu, color: Colors.grey.shade300),
              //   );
              // }),
            ],
          );
        }),
      ),
      centerTitle: false,
      elevation: 0,
    );
  }

  @override
  BottomNavigationBarItem get navigationBarItem {
    return BottomNavigationBarItem(
      icon: const Icon(CupertinoIcons.home),
      label: 'Home'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;
}

class HomeUserInfo extends StatelessWidget {
  const HomeUserInfo({super.key});

  Future<String> get _formattedPhoneNumber async {
    final phoneNumber = PhoneNumber(
      phoneNumber: AppController.me.phone,
    );
    try {
      final data = await PhoneNumber.getParsableNumber(phoneNumber);
      return "(${phoneNumber.dialCode}) $data";
    } on Exception catch (_) {
      return phoneNumber.phoneNumber ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Card(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppController.me.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.fade,
                      ),
                      maxLines: 1,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mail),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppController.me.email,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_android),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FutureBuilder(
                            builder: (ctx, asp) => Text(
                              "${asp.data}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            future: _formattedPhoneNumber,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.location_solid),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppController.me.country,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.person_alt_circle_fill),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppController.me.type.replaceFirst(
                              AppController.me.type[0],
                              AppController.me.type[0].toUpperCase(),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: AppController.me.profilePicture,
              height: 130,
              errorWidget: (ctx, url, e) {
                Get.log('$e');
                return Card(
                  child: SizedBox(
                    height: 130,
                    child: Icon(
                      AppController.me.gender == "Male"
                          ? Icons.person
                          : Icons.person_2,
                      size: 80,
                    ),
                  ),
                );
              },
              // height: 130,
            ),
          )
        ],
      );
    });
  }
}

class HomeCard extends StatelessWidget {
  final String label;
  final String assetImage;
  final void Function()? onTap;

  const HomeCard({
    super.key,
    required this.label,
    required this.assetImage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(assetImage),
              fit: BoxFit.cover,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
              const Icon(
                Icons.arrow_forward_ios,
                size: 25,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlogPostWidget extends StatelessWidget {
  final BlogPost post;
  final void Function()? onTap;

  const BlogPostWidget({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        child: Container(
          width: 200,
          height: 240,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl ?? "",
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (ctx, e, trace) {
                    return const Center();
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    post.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Divider(height: 1),
              if (post.createdAt != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      Jiffy(post.createdAt!).yMEd,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall,
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
