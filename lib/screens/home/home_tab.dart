import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/drawer.dart';
import 'package:roomy_finder/components/get_more_button.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/helpers/roomy_notification.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/screens/ads/property_ad/find_properties.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/find_roommates.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/ads/roommates/find_roommates.dart';
import 'package:roomy_finder/screens/chat/chat_room/chat_room_screen.dart';
import 'package:roomy_finder/screens/home/home.dart';
import 'package:roomy_finder/screens/user/public_profile.dart';
import 'package:roomy_finder/screens/utility_screens/faq.dart';
import 'package:roomy_finder/utilities/data.dart';

class HomeTab extends StatefulWidget implements HomeScreenSupportable {
  const HomeTab({super.key});

  @override
  void onTabIndexSelected(int index) {}

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isLoading = true;

  late final StreamSubscription<RemoteMessage> _fcmStream;

  // late final PageController _pageController;
  var _hasFechError = false;

  int _currentPage = 0;

  // Premium Properties
  final _premiumPropertyAds = <PropertyAd>[];

  // Properties
  final _propertyAds = <PropertyAd>[];

  // Roommates
  final _roommatesAds = <RoommateAd>[];

  // Roommates
  final _roommateUsers = <User>[];

  @override
  void initState() {
    _hasFechError;

    super.initState();

    // _pageController = PageController(initialPage: _currentPage);

    Future.value([
      _fetchPremiunProperties(),
      _fetchProperties(),
      _fetchRoommates(),
      _fetchRoommateAds(),
    ]);

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
  }

  @override
  void dispose() {
    super.dispose();

    _fcmStream.cancel();
    // _pageController.dispose();
  }

  Future<void> _fetchRoommates({bool isRefresh = false}) async {
    try {
      _hasFechError = false;
      setState(() => _isLoading = true);

      final res = await Dio().get(
        "$API_URL/ads/roommates",
        data: {
          "skip": isRefresh ? 0 : _roommateUsers.length,
          "limit": 10,
        },
      );

      // Roommate users
      final roommateUsers = (res.data as List).map((e) {
        try {
          var user = User.fromMap(e);
          return user;
        } catch (e) {
          return null;
        }
      });

      if (isRefresh) _roommateUsers.clear();
      _roommateUsers.addAll(roommateUsers.whereType<User>());
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");

      _hasFechError = true;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchProperties({bool isRefresh = false}) async {
    try {
      _hasFechError = false;
      setState(() => _isLoading = true);

      final requestBody = <String, dynamic>{
        "skip": isRefresh ? 0 : _propertyAds.length,
        "countryCode": AppController.instance.country.value.code,
        "limit": 10,
      };
      final res = await Dio().post(
        "$API_URL/ads/property-ad/available",
        data: requestBody,
      );

      final data = (res.data as List).map((e) {
        try {
          var ad = PropertyAd.fromMap(e);
          return ad;
        } catch (e, trace) {
          Get.log("$trace");
          return null;
        }
      });
      if (isRefresh) {
        _propertyAds.clear();
      }
      _propertyAds.addAll(data.whereType<PropertyAd>());
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPremiunProperties({bool isRefresh = false}) async {
    try {
      _hasFechError = false;
      setState(() => _isLoading = true);

      final requestBody = <String, dynamic>{
        "skip": isRefresh ? 0 : _premiumPropertyAds.length,
        "countryCode": AppController.instance.country.value.code,
        "limit": 10,
        "sortOrder": 1,
      };
      final res = await Dio().post(
        "$API_URL/ads/property-ad/available",
        data: requestBody,
      );

      final data = (res.data as List).map((e) {
        try {
          var ad = PropertyAd.fromMap(e);
          return ad;
        } catch (e, trace) {
          Get.log("$trace");
          return null;
        }
      });
      if (isRefresh) {
        _premiumPropertyAds.clear();
      }
      _premiumPropertyAds.addAll(data.whereType<PropertyAd>());
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRoommateAds({bool isRefresh = false}) async {
    try {
      _hasFechError = false;
      setState(() => _isLoading = true);

      final requestBody = <String, dynamic>{
        "countryCode": AppController.instance.country.value.code,
        "skip": isRefresh ? 0 : _roommatesAds.length,
        "limit": 10,
      };
      final res = await Dio().post(
        "$API_URL/ads/roommate-ad/available",
        data: requestBody,
      );

      final data = (res.data as List).map((e) {
        try {
          var ad = RoommateAd.fromMap(e);
          return ad;
        } catch (e, trace) {
          Get.log("$trace");
          return null;
        }
      });
      if (isRefresh) {
        _roommatesAds.clear();
      }
      _roommatesAds.addAll(data.whereType<RoommateAd>());
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onNewAd(String adType, String adId) async {
    if (adType == "new-property-ad") {
      final ad = await ApiService.fetchPropertyAd(adId);

      if (ad != null) {
        _propertyAds.insert(0, ad);
        showToast("New property posted");
        setState(() {});
      }
    } else if (adType == "new-roommate-ad") {
      final ad = await ApiService.fetchRoommateAd(adId);

      if (ad != null) {
        _roommatesAds.insert(0, ad);
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

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var ad in _premiumPropertyAds)
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: PropertyAdWidget(
                      ad: ad,
                      isMiniView: true,
                      onTap: () {
                        Get.to(() => ViewPropertyAd(ad: ad));
                      },
                    ),
                  ),
                if (_premiumPropertyAds.isNotEmpty)
                  GetMoreButton(getMore: _fetchPremiunProperties),
              ],
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
                  Get.to(() => FindPropertiesAdsScreen(
                      initialSkip: _propertyAds.length));
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
            children: _propertyAds.map((e) {
              return PropertyAdWidget(
                ad: e,
                onTap: () {
                  Get.to(() => ViewPropertyAd(ad: e));
                },
              );
            }).toList(),
          ),

          if (_propertyAds.isNotEmpty) GetMoreButton(getMore: _fetchProperties),
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
                "All ads",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.to(() =>
                      FindRoommateAdsScreen(initialSkip: _roommatesAds.length));
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

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _roommatesAds.length; i++)
                  SizedBox(
                    width: 180,
                    height: 200,
                    child: Builder(
                      builder: (context) {
                        var e = _roommatesAds[i];

                        return RoommateAdWidget(
                          ad: e,
                          onTap: () {
                            Get.to(() => ViewRoommateAdScreen(ad: e));
                          },
                          onChat: () {
                            if (AppController.me.isGuest) {
                              RoomyNotificationHelper
                                  .showRegistrationRequiredToChat();
                            } else {
                              moveToChatRoom(AppController.me, e.poster);
                            }
                          },
                          isMiniView: true,
                        );
                      },
                    ),
                  ),
                if (_roommatesAds.isNotEmpty)
                  GetMoreButton(getMore: _fetchRoommateAds),
              ],
            ),
          ),

// Roommates
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
                  Get.to(() => FindRoommateUsersScreen(
                      initialSkip: _roommateUsers.length));
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
            children: [
              for (int i = 0; i < _roommateUsers.length; i++)
                Builder(
                  builder: (context) {
                    var e = _roommateUsers[i];

                    return RoommateUser(
                      user: e,
                      onTap: () {
                        Get.to(() => UserPublicProfile(user: e));
                      },
                      onChat: () {
                        if (AppController.me.isGuest) {
                          RoomyNotificationHelper
                              .showRegistrationRequiredToChat();
                        } else {
                          moveToChatRoom(AppController.me, e);
                        }
                      },
                    );
                  },
                )
            ],
          ),
          GetMoreButton(
            getMore: _fetchRoommates,
          ),
        ],
      ),
    );

    final adSlivers = [roomsSliver, roommatesSliver];

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentPage == 0) {
          await Future.wait([
            _fetchPremiunProperties(isRefresh: true),
            _fetchProperties(isRefresh: true),
          ]);
        } else {
          await Future.wait([
            _fetchRoommates(isRefresh: true),
            _fetchRoommateAds(isRefresh: true)
          ]);
        }
      },
      child: Scaffold(
        drawer: const HomeDrawer(),
        body: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      IconButton(
                        onPressed: () => Get.to(() => const FAQScreen()),
                        icon: const Icon(
                          Icons.question_mark_outlined,
                          color: Colors.white,
                        ),
                      ),
                      Builder(builder: (context) {
                        return IconButton(
                          onPressed: () async {
                            var changed = await changeAppCountry(context);
                            if (changed) {
                              _fetchRoommates(isRefresh: true);
                              _fetchProperties(isRefresh: true);
                              _fetchRoommates(isRefresh: true);
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
                              color:
                                  Theme.of(context).appBarTheme.backgroundColor,
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
            if (_isLoading) const LoadingPlaceholder()
          ],
        ),
        bottomNavigationBar:
            AppController.me.isGuest ? null : const HomeBottomNavigationBar(),
      ),
    );
  }
}
