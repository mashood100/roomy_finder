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
import 'package:roomy_finder/screens/ads/my_property_ads.dart';
import 'package:roomy_finder/screens/ads/property_ad/find_properties.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/screens/booking/my_bookings.dart';
import 'package:roomy_finder/screens/home/home.dart';
import 'package:roomy_finder/screens/user/account_balance.dart/balance.dart';
import 'package:roomy_finder/screens/utility_screens/faq.dart';
import 'package:roomy_finder/utilities/data.dart';

class LandlordHomeTab extends StatefulWidget implements HomeScreenSupportable {
  const LandlordHomeTab({super.key});

  @override
  void onTabIndexSelected(int index) {}

  @override
  State<LandlordHomeTab> createState() => _LandlordHomeTabState();
}

class _LandlordHomeTabState extends State<LandlordHomeTab> {
  final _propertyAds = <PropertyAd>[];

  // bool _failedToLoadHomeAds = false;

  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;
  late final StreamSubscription<RemoteMessage> _fcmStream;

  // late final PageController _pageController;
  late final Timer _timer;
  var _hasFechError = false;

  var _isLoading = false;

  String? _seletedDashboardIcon;

  @override
  void initState() {
    super.initState();

    // _pageController = PageController(initialPage: _currentPage);

    _fetchProperties();

    Future.delayed(const Duration(), () async {
      setState(() => _isLoading = true);
      await ApiService.setLanlordIsBlocked();
      if (mounted) setState(() => _isLoading = false);
    });

    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        _fetchProperties(isSilent: true);
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

        case "roomy-balance-payment-successfully":
          ApiService.setLanlordIsBlocked();
          break;

        default:
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_hasFechError) {
        _fetchProperties();
        ApiService.setUnreadBookingCount();
      }
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

  Future<void> _fetchProperties(
      {bool isRefresh = false, bool isSilent = false}) async {
    try {
      _hasFechError = false;
      if (isSilent == false) setState(() => _isLoading = true);

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

  Future<void> _onNewAd(String adType, String adId) async {
    if (adType == "new-property-ad") {
      final ad = await ApiService.fetchPropertyAd(adId);

      if (ad != null) {
        _propertyAds.insert(0, ad);
        showToast("New property posted");
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = MediaQuery.sizeOf(context).width ~/ 300;
    return Obx(() {
      var dashboardData = [
        (
          icon: AssetIcons.home2PNG,
          label: "My Properties",
          onPressed: () => Get.to(() => const MyPropertyAdsScreen()),
          badge: 0,
        ),
        (
          icon: AssetIcons.calender3PNG,
          label: "My Bookings",
          onPressed: () => Get.to(() => const MyBookingsCreen()),
          badge: Home.unViewBookingsCount.value,
        ),
        (
          icon: AssetIcons.dollarBanknotePNG,
          label: "Rent payments",
          onPressed: () =>
              Get.to(() => const UserBalanceScreen(initialPage: 0)),
          badge: 0,
        ),
        (
          icon: AssetIcons.homeAdd2PNG,
          label: "Add Property",
          onPressed: () => Get.to(() => const PostPropertyAdScreen()),
          badge: 0,
        ),
        (
          icon: AssetIcons.repair2PNG,
          label: "Request Maintenance",
          onPressed: () => showToast("Coming soon"),
          badge: 0,
        ),
        (
          icon: AssetIcons.mobilePayPNG,
          label: "Roomy Pay",
          onPressed: () {
            Get.to(() => UserBalanceScreen(
                  initialPage: 1,
                  canSwicthPage: !AppController.dashboardIsBlocked,
                ));
          },
          badge: 0,
        ),
      ];
      return RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_fetchProperties(isRefresh: true)]);
        },
        child: Scaffold(
          drawer: const HomeDrawer(),
          body: Stack(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: ROOMY_PURPLE,
                    // automaticallyImplyLeading: false,

                    elevation: 0,
                    pinned: true,

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
                                _fetchProperties();
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
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                                    Text(
                                      AppController.me.fullName,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
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

                              Get.to(() {
                                return FindPropertiesAdsScreen(
                                  filter: {"city": suggestion},
                                );
                              });
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
                                    Get.to(() {
                                      return const FindPropertiesAdsScreen();
                                    });
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
                  const SliverToBoxAdapter(
                      child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "My services",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: dashboardData.map((e) {
                        var isSelected = _seletedDashboardIcon == e.icon;
                        var index = dashboardData.indexOf(e);

                        return Badge.count(
                          count: e.badge,
                          isLabelVisible: e.badge > 0,
                          child: GestureDetector(
                            onTapDown: (details) {
                              setState(() => _seletedDashboardIcon = e.icon);
                            },
                            onTapUp: (details) {
                              setState(() => _seletedDashboardIcon = null);
                            },
                            onTap: () {
                              var isBlocked =
                                  AppController.dashboardIsBlocked &&
                                      index != 5;
                              if (isBlocked) {
                                RoomyNotificationHelper
                                    .showDashBoardIsBlocked();
                              } else {
                                e.onPressed();
                              }
                            },
                            child: Card(
                              color: Colors.white,
                              surfaceTintColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                                side: isSelected
                                    ? const BorderSide(color: ROOMY_PURPLE)
                                    : BorderSide.none,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Column(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Image.asset(
                                        e.icon,
                                        color: isSelected ? ROOMY_ORANGE : null,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Text(
                                          e.label,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? ROOMY_ORANGE
                                                : null,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Image.asset(AssetImages.landlordDashboardBoostPNG),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => const Icon(Icons.circle_outlined, size: 10),
                    ),
                  )),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid.count(
                      crossAxisCount: crossAxisCount,
                      children: [
                        for (var ad in _propertyAds)
                          PropertyAdWidget(
                            ad: ad,
                            onTap: () async {
                              if (AppController.me.isGuest) {
                                showToast("Please register to see ad details");
                                return;
                              }
                              final result =
                                  await Get.to(() => ViewPropertyAd(ad: ad));
                              if (result is Map<String, dynamic>) {
                                final deletedId = result["deletedId"];
                                if (deletedId != null) {
                                  _propertyAds
                                      .removeWhere((e) => e.id == deletedId);
                                }
                              }
                              setState(() {});
                            },
                          )
                      ],
                    ),
                  ),
                  if (_propertyAds.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: GetMoreButton(getMore: _fetchProperties),
                      ),
                    ),
                ],
              ),
              if (_isLoading) const LoadingPlaceholder()
            ],
          ),
          bottomNavigationBar:
              AppController.me.isGuest ? null : const HomeBottomNavigationBar(),
        ),
      );
    });
  }
}
