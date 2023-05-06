import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/custom_bottom_navbar_icon.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/find_properties.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/find_roommates.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/user/upgrade_plan.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class _HomeTabController extends LoadingController {
  final _targetAds = "Room".obs;

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

  List<PropertyAd> get _firstRowPropertyAds {
    if (_homePropertyAds.length <= 6) {
      return _homePropertyAds;
    } else {
      return _homePropertyAds.sublist(0, 6);
    }
  }

  List<PropertyAd> get _secondRowPropertyAds {
    if (_homePropertyAds.length <= 6) {
      return [];
    } else {
      return _homePropertyAds.sublist(6, _homePropertyAds.length - 1);
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
        ]);
      },
      child: GetBuilder<_HomeTabController>(builder: (controller) {
        return SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // Account detail
                    if (AppController.me.isGuest)
                      const Align(
                        alignment: Alignment.topLeft,
                        child: Text("I am looking for"),
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // const Icon(
                                  //   CupertinoIcons.person_alt_circle_fill,
                                  //   color: ROOMY_ORANGE,
                                  // ),
                                  // const SizedBox(width: 10),
                                  Text(
                                    AppController.me.fullName,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.key,
                                    color: ROOMY_ORANGE,
                                  ),
                                  const SizedBox(width: 10),
                                  Builder(builder: (context) {
                                    final type = AppController.me.type;
                                    return Text(
                                      type.replaceFirst(
                                        type[0],
                                        type[0].toUpperCase(),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                          AppController.me.ppWidget(
                            size: 25,
                            borderColor: false,
                          )
                        ],
                      ),
                    const SizedBox(height: 10),
                    //  Ads types
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: ROOMY_ORANGE),
                      ),
                      child: Row(
                        children: ["Room", "Roommate"].map((e) {
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                controller._targetAds(e);
                                controller.update();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      controller._targetAds.value == e ? 3 : 5),
                                  color: controller._targetAds.value == e
                                      ? ROOMY_ORANGE
                                      : Colors.white,
                                ),
                                child: Text(
                                  e,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: controller._targetAds.value == e
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Search box
                    SizedBox(
                      height: 40,
                      child: TypeAheadField<String>(
                        itemBuilder: (ctx, suggestion) {
                          return ListTile(
                            title: Text(suggestion),
                            dense: true,
                          );
                        },
                        onSuggestionSelected: (suggestion) {
                          FocusManager.instance.primaryFocus?.unfocus();

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
                          return CITIES_FROM_CURRENT_COUNTRY.where((e) {
                            e = e.trim().toLowerCase();

                            return e.startsWith(pattern) || e.contains(pattern);
                          });
                        },
                        suggestionsBoxDecoration:
                            const SuggestionsBoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        textFieldConfiguration: TextFieldConfiguration(
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            hintText: "Search by city",
                            suffixIcon: IconButton(
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(5),
                              ),
                              onPressed: () {
                                switch (controller._targetAds.value) {
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
                              icon: const Icon(Icons.search),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 12),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              if (controller._targetAds.value == "Room") ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Available Rooms",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.to(() {
                            return const FindPropertiesAdsScreen();
                          });
                        },
                        child: const Text(
                          "See all",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller._isLoadingHomeAds.isTrue)
                  for (int i = 0; i < 2; i++)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(6, (index) {
                          return const Card(
                            child: SizedBox(
                              width: 150,
                              height: 200,
                              child: CupertinoActivityIndicator(
                                radius: 30,
                              ),
                            ),
                          );
                        }),
                      ),
                    )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: controller._firstRowPropertyAds.map((ad) {
                          return SizedBox(
                            width: 160,
                            height: 200,
                            child: PropertyAdMiniWidget(
                              ad: ad,
                              onTap: () {
                                Get.to(() => ViewPropertyAd(ad: ad));
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: controller._secondRowPropertyAds.map((ad) {
                          return SizedBox(
                            width: 150,
                            height: 200,
                            child: PropertyAdMiniWidget(
                              ad: ad,
                              onTap: () {
                                Get.to(() => ViewPropertyAd(ad: ad));
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
              if (controller._targetAds.value == "Roommate") ...[
                // Need room
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Need room",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.to(() {
                            return const FindRoommatesScreen(
                              filter: {"action": "NEED ROOM"},
                            );
                          });
                        },
                        child: const Text(
                          "See All",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            // color: ROOMY_ORANGE,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: controller._homeRoommateAds
                          .where((e) => e.action == "NEED ROOM")
                          .map((ad) {
                        return SizedBox(
                          width: 150,
                          height: 200,
                          child: RoommateAdMiniWidget(
                            ad: ad,
                            onTap: () {
                              if (AppController.me.isGuest) {
                                Get.offAllNamed("/login");
                                return;
                              }
                              if (AppController.me.isPremium) {
                                Get.to(() => ViewRoommateAdScreen(ad: ad));
                              } else {
                                controller.upgradeToSeeDetails(ad);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                //  Have room
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Have room",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.to(() {
                            return const FindRoommatesScreen(
                              filter: {"action": "HAVE ROOM"},
                            );
                          });
                        },
                        child: const Text(
                          "See All",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            // color: ROOMY_ORANGE,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: controller._homeRoommateAds
                          .where((e) => e.action == "HAVE ROOM")
                          .map((ad) {
                        return SizedBox(
                          width: 150,
                          height: 200,
                          child: RoommateAdMiniWidget(
                            ad: ad,
                            onTap: () {
                              if (AppController.me.isGuest) {
                                Get.offAllNamed("/login");
                                return;
                              }
                              if (AppController.me.isPremium) {
                                Get.to(() => ViewRoommateAdScreen(ad: ad));
                              } else {
                                controller.upgradeToSeeDetails(ad);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 10),
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
          Image.asset("assets/images/logo_house.png", height: 40),
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
                    fontSize: 16,
                    fontFamily: "Avro",
                  ),
                ),
                Text(
                  "FINDER",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: ROOMY_ORANGE,
                    fontSize: 16,
                    fontFamily: "Avro",
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
  BottomNavigationBarItem navigationBarItem(isCurrent) {
    return BottomNavigationBarItem(
      icon: CustomBottomNavbarIcon(
        icon: Image.asset(
          "assets/icons/home.png",
          height: 30,
          width: 30,
          color: ROOMY_PURPLE,
        ),
        isCurrent: isCurrent,
      ),
      label: 'Home'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;

  @override
  void onIndexSelected(int index) {}
}
