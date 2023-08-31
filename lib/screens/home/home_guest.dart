import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/drawer.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/helpers/roomy_notification.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/find_properties.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/find_roommates.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/chat/chat_room/chat_room_screen.dart';
import 'package:roomy_finder/screens/home/home.dart';
import 'package:roomy_finder/utilities/data.dart';

class HomeGuestUser extends StatefulWidget implements HomeScreenSupportable {
  const HomeGuestUser({super.key});

  @override
  void onTabIndexSelected(int index) {}

  @override
  State<HomeGuestUser> createState() => _HomeGuestUserState();
}

class _HomeGuestUserState extends State<HomeGuestUser> {
  final _homePropertyAds = <PropertyAd>[];
  final _homeRoommateAds = <RoommateAd>[];
  bool _isLoadingHomeAds = true;
  // bool _failedToLoadHomeAds = false;

  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;
  late final StreamSubscription<RemoteMessage> _fcmStream;

  // late final PageController _pageController;
  late final Timer _timer;
  var _hasFechError = false;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // _pageController = PageController(initialPage: _currentPage);

    _fetchHommeAds();

    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        _fetchHommeAds();
      }
    });

    _fcmStream =
        FirebaseMessaging.onMessage.asBroadcastStream().listen((event) async {
      final data = event.data;
      // AppController.instance.haveNewMessage(false);
      switch (data["event"]) {
        case "new-property-ad":
        case "new-roommate-ad":
          _onNewAd(data["event"], data["adId"]);
          break;

        default:
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_hasFechError) _fetchHommeAds();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
    _fGBGNotifierSubScription.cancel();
    _fcmStream.cancel();
    // _pageController.dispose();
  }

  Future<void> _fetchHommeAds() async {
    try {
      _isLoadingHomeAds = true;
      // _failedToLoadHomeAds = false;
      _hasFechError = false;

      final res = await Dio().get(
        "$API_URL/ads/recommended",
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
      // _failedToLoadHomeAds = true;
      _hasFechError = true;
    } finally {
      _isLoadingHomeAds = false;
      setState(() {});
    }
  }

  List<PropertyAd> get _normalPropertyAds {
    // final half = _homePropertyAds.length ~/ 2;
    if (_homePropertyAds.length <= 6) {
      return _homePropertyAds;
    } else {
      return _homePropertyAds.sublist(0, 6);
    }
  }

  List<PropertyAd> get _premiumPropertyAds {
    if (_homePropertyAds.length <= 6) {
      return [];
    } else {
      return _homePropertyAds.sublist(6, _homePropertyAds.length - 1);
    }
  }

  List<RoommateAd> get _premiumRoommateAds {
    // final half = _homePropertyAds.length ~/ 2;
    if (_homePropertyAds.length <= 6) {
      return _homeRoommateAds;
    } else {
      return _homeRoommateAds.sublist(0, 6);
    }
  }

  List<RoommateAd> get _normalRoommateAds {
    if (_homePropertyAds.length <= 6) {
      return [];
    } else {
      return _homeRoommateAds.sublist(6, _homeRoommateAds.length - 1);
    }
  }

  Future<void> _onNewAd(String adType, String adId) async {
    if (adType == "new-property-ad") {
      final ad = await ApiService.fetchPropertyAd(adId);

      if (ad != null) {
        _homePropertyAds.insert(0, ad);
        showToast("New property posted");
        setState(() {});
      }
    } else if (adType == "new-roommate-ad") {
      final ad = await ApiService.fetchRoommateAd(adId);

      if (ad != null) {
        _homeRoommateAds.insert(0, ad);
        setState(() {});
        showToast("New roommate posted");
      }
    }
  }

  void _moveToPage(int page) {
    setState(() => _currentPage = page);
    // _pageController.animateToPage(
    //   page,
    //   duration: const Duration(milliseconds: 200),
    //   curve: Curves.linear,
    // );
  }

  @override
  Widget build(BuildContext context) {
    var adTypes = ["Room", "Roommate"];

    final largeSizeGridsCount = MediaQuery.sizeOf(context).width ~/ 300;

    final roomsSliver = SliverPadding(
      padding: const EdgeInsets.all(10),
      sliver: SliverList.list(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Premium Ads",
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
          if (_isLoadingHomeAds)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(6, (index) {
                  return const _SmallItemPlaceHolder();
                }),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _premiumPropertyAds.map((ad) {
                  return SizedBox(
                    width: 180,
                    height: 180,
                    child: PropertyAdWidget(
                      ad: ad,
                      isMiniView: true,
                      onTap: () {
                        Get.to(() => ViewPropertyAd(ad: ad));
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          // Normal rooms
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "All Rooms",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.to(() => const FindPropertiesAdsScreen());
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

          GridView.count(
            crossAxisCount: largeSizeGridsCount,
            childAspectRatio: 1.25,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _normalPropertyAds.map((e) {
              return PropertyAdWidget(
                ad: e,
                onTap: () {
                  Get.to(() => ViewPropertyAd(ad: e));
                },
              );
            }).toList(),
          ),
        ],
      ),
    );

    final roommatesSliver = SliverPadding(
      padding: const EdgeInsets.all(10),
      sliver: SliverList.list(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Premium Ads",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.to(() => const FindRoommateAdsScreen());
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

          if (_isLoadingHomeAds)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(6, (index) {
                  return const _SmallItemPlaceHolder();
                }),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _premiumRoommateAds.map((ad) {
                  return SizedBox(
                    width: 180,
                    height: 180,
                    child: RoommateAdWidget(
                      ad: ad,
                      isMiniView: true,
                      onTap: () {
                        Get.to(() => ViewRoommateAdScreen(ad: ad));
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

// Normal rooms
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "All Roommates",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.to(() => const FindRoommateAdsScreen());
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

          GridView.count(
            crossAxisCount: largeSizeGridsCount,
            childAspectRatio: 1.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _normalRoommateAds.map((e) {
              return RoommateAdWidget(
                ad: e,
                onTap: () {
                  Get.to(() => ViewRoommateAdScreen(ad: e));
                },
                onChat: () {
                  if (AppController.me.isGuest) {
                    RoomyNotificationHelper.showRegistrationRequiredToChat();
                  } else {
                    moveToChatRoom(AppController.me, e.poster);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );

    final adSlivers = [roomsSliver, roommatesSliver];

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_fetchHommeAds()]);
      },
      child: Scaffold(
        drawer: const HomeDrawer(),
        body: CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              backgroundColor: ROOMY_PURPLE,
              // automaticallyImplyLeading: false,

              elevation: 0,
              floating: true, snap: true,
              expandedHeight: 250,

              leadingWidth: MediaQuery.sizeOf(context).width,

              title: const Text(""),

              leading: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 5),
                  Image.asset(AssetImages.logoHousePNG, height: 40),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                  Builder(builder: (context) {
                    return IconButton(
                      onPressed: () async {
                        var changed = await changeAppCountry(context);
                        if (changed) {
                          _fetchHommeAds();
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
              ),

              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Theme.of(context).appBarTheme.backgroundColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Account detail

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Builder(builder: (context) {
                          if (AppController.me.isGuest) {
                            return const Align(
                              alignment: Alignment.topLeft,
                              child: Text("I am looking for"),
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                              Obx(() {
                                return AppController.instance.user.value
                                    .ppWidget(
                                  size: 25,
                                  borderColor: false,
                                );
                              })
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      //  Ads types
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: ROOMY_ORANGE),
                        ),
                        child: Row(
                          children: adTypes.map((e) {
                            var index = adTypes.indexOf(e);
                            var isSelected = _currentPage == index;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _moveToPage(index);
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        isSelected ? 3 : 5),
                                    color: isSelected
                                        ? ROOMY_ORANGE
                                        : Colors.white,
                                  ),
                                  child: Text(
                                    e,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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

                            switch (_currentPage) {
                              case 0:
                                Get.to(() {
                                  return FindPropertiesAdsScreen(
                                    filter: {"city": suggestion},
                                  );
                                });
                                break;
                              case 1:
                                Get.to(() {
                                  return FindRoommateAdsScreen(
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
                          textFieldConfiguration: TextFieldConfiguration(
                            decoration: InputDecoration(
                              fillColor: Colors.white,
                              hintText: "Search by city",
                              suffixIcon: IconButton(
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsets.all(5),
                                ),
                                onPressed: () {
                                  switch (_currentPage) {
                                    case 0:
                                      Get.to(() {
                                        return const FindPropertiesAdsScreen();
                                      });
                                      break;
                                    case 1:
                                      Get.to(() {
                                        return const FindRoommateAdsScreen();
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
              ),
            ),
            adSlivers[_currentPage],
          ],
        ),
        bottomNavigationBar: const HomeBottomNavigationBar(),
      ),
    );
  }
}

class _SmallItemPlaceHolder extends StatelessWidget {
  const _SmallItemPlaceHolder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 150,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Colors.grey.withOpacity(0.5),
                strokeWidth: 2,
              ),
            ),
            Text(
              "...",
              style: TextStyle(
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
