import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/find_properties.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/find_roommates.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/post_roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/user/upgrade_plan.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class _HomeTabController extends LoadingController {
  final _targetAds = "All".obs;

  final _homePropertyAds = <PropertyAd>[];
  final _homeRoommateAds = <RoommateAd>[];
  final _isLoadingHomeAds = true.obs;
  final _failedToLoadHomeAds = false.obs;

  final canSeeDetails = AppController.me.isPremium.obs;

  @override
  void onInit() {
    super.onInit();

    _fetchHommeAds();

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

      final res = await Dio().get(
        "$API_URL/ads/recomended",
        queryParameters: {
          "countryCode": AppController.instance.country.value.code,
        },
      );

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

  Future<void> upgradeToSeeDetails(RoommateAd ad) async {
    await Get.to(() => UpgragePlanScreen(
          skipCallback: () {
            canSeeDetails(true);
            Get.to(() => ViewRoommateAdScreen(ad: ad));
          },
        ));
    update();
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
                          "assets/images/home_background.jpg",
                          width: double.infinity,
                          height: (controller._targetAds.value == "All")
                              ? 250
                              : 300,
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
                            if (controller._targetAds.value != "All")
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: TypeAheadField<String>(
                                  itemBuilder: (ctx, suggestion) {
                                    return ListTile(
                                      title: Text(suggestion),
                                      dense: true,
                                    );
                                  },
                                  onSuggestionSelected: (suggestion) {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();

                                    switch (controller._targetAds.value) {
                                      case "Room":
                                        Get.to(() {
                                          return FindPropertiesAdsScreen(
                                            filter: {"city": suggestion},
                                          );
                                        });
                                        break;
                                      case "Roommate":
                                        Get.to(() {
                                          return FindRoommatesScreen(
                                            filter: {"city": suggestion},
                                          );
                                        });
                                        break;
                                      default:
                                    }
                                  },
                                  suggestionsCallback: (pattern) {
                                    pattern = pattern.trim().toLowerCase();
                                    return CITIES_FROM_CURRENT_COUNTRY
                                        .where((e) {
                                      e = e.trim().toLowerCase();

                                      return e.startsWith(pattern) ||
                                          e.contains(pattern);
                                    });
                                  },
                                  suggestionsBoxDecoration:
                                      const SuggestionsBoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  textFieldConfiguration:
                                      TextFieldConfiguration(
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      hintText: "Search by city",
                                      suffixIcon: SizedBox(
                                        child: IconButton(
                                          onPressed: () {
                                            switch (
                                                controller._targetAds.value) {
                                              case "Room":
                                                Get.to(() {
                                                  return const FindPropertiesAdsScreen();
                                                });
                                                break;
                                              case "Roommate":
                                                Get.to(() {
                                                  return const FindRoommatesScreen();
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
                                      contentPadding: const EdgeInsets.fromLTRB(
                                          12, 10, 12, 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                    textInputAction: TextInputAction.search,
                                  ),
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
                    if (controller._targetAds.value == "Room") ...[
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
                    if (controller._targetAds.value == "Roommate") ...[
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
                              onPressed: () {
                                Get.to(() {
                                  return const FindRoommatesScreen();
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
                                if (AppController.me.isGuest) {
                                  Get.offAllNamed("/registration");
                                  return;
                                }
                                if (AppController.me.isPremium) {
                                  Get.to(() => ViewRoommateAdScreen(ad: ad));
                                } else {
                                  controller.upgradeToSeeDetails(ad);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],

                    // Merged grid
                    if (controller._targetAds.value == "All") ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            Text(
                              "Properties",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ROOMY_ORANGE,
                              ),
                            ),
                            Text(
                              "Roommates",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ROOMY_ORANGE,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        children: List.generate(
                          controller._homePropertyAds.length +
                                      controller._homeRoommateAds.length >
                                  0
                              ? controller._homePropertyAds.length +
                                  controller._homeRoommateAds.length -
                                  1
                              : controller._homePropertyAds.length +
                                  controller._homeRoommateAds.length,
                          (index) {
                            if (controller._isLoadingHomeAds.isTrue) {
                              return const Card(
                                child: CupertinoActivityIndicator(radius: 30),
                              );
                            }
                            final ind = index ~/ 2;

                            if (index % 2 == 0) {
                              if (ind < controller._homePropertyAds.length) {
                                final ad = controller._homePropertyAds[ind];
                                return PropertyAdMiniWidget(
                                  ad: ad,
                                  onTap: () {
                                    Get.to(() => ViewPropertyAd(ad: ad));
                                  },
                                );
                              }
                            } else {
                              if (ind < controller._homeRoommateAds.length) {
                                final ad = controller._homeRoommateAds[ind];

                                return RoommateAdMiniWidget(
                                  ad: ad,
                                  onTap: () {
                                    if (AppController.me.isGuest) {
                                      Get.offAllNamed("/registration");
                                      return;
                                    }
                                    if (AppController.me.isPremium) {
                                      Get.to(
                                          () => ViewRoommateAdScreen(ad: ad));
                                    } else {
                                      controller.upgradeToSeeDetails(ad);
                                    }
                                  },
                                );
                              }
                            }

                            return const SizedBox();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
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
      backgroundColor: ROOMY_PURPLE,
      // automaticallyImplyLeading: false,
      leadingWidth: 150,
      leading: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 5),
          Image.asset("assets/images/logo.png", height: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Roomy",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "FINDER",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: ROOMY_ORANGE,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      actions: [
        Builder(builder: (context) {
          return IconButton(
            onPressed: () async {
              var changed = await changeAppCountry(context);
              if (changed) {
                controller._fetchHommeAds();
              }
            },
            icon: Obx(() {
              return Text(
                AppController.instance.country.value.flag,
                style: const TextStyle(fontSize: 25),
              );
            }),
          );
        }),
        Builder(builder: (context) {
          return IconButton(
            onPressed: () {
              if (Scaffold.of(context).isDrawerOpen) {
                Scaffold.of(context).closeDrawer();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
            icon: Icon(Icons.menu, color: Colors.grey.shade300),
          );
        }),
      ],
      elevation: 0,
    );
  }

  @override
  BottomNavigationBarItem get navigationBarItem {
    return BottomNavigationBarItem(
      activeIcon: Image.asset("assets/icons/home.png", height: 30),
      icon: Image.asset("assets/icons/home_white.png", height: 30),
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
