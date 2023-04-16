import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/user/upgrade_plan.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: unused_element
class _FavoriteTabController extends LoadingController
    with GetSingleTickerProviderStateMixin {
  final propertyAds = <PropertyAd>[];
  final roommateAds = <RoommateAd>[];
  late final TabController _tabController;

  final _currentTabIndex = 0.obs;

  final canSeeDetails = AppController.me.isPremium.obs;

  @override
  void onInit() {
    _tabController = TabController(length: 2, vsync: this);
    super.onInit();
    _loadFavoritePropertyAds();
    _loadFavoriteRoommateAds();
  }

  Future<void> _loadFavoritePropertyAds() async {
    try {
      isLoading(true);
      update();
      final pref = await SharedPreferences.getInstance();

      final favorites = pref.getStringList("favorites-property-ads") ?? [];

      if (favorites.isEmpty) return;
      propertyAds.clear();
      propertyAds.addAll(favorites.map((e) => PropertyAd.fromJson(e)));
    } catch (_) {
    } finally {
      isLoading(false);
      update();
    }
  }

  Future<void> _loadFavoriteRoommateAds() async {
    try {
      isLoading(true);
      update();
      final pref = await SharedPreferences.getInstance();

      final favorites = pref.getStringList("favorites-roommates-ads") ?? [];

      if (favorites.isEmpty) return;
      roommateAds.clear();
      roommateAds.addAll(favorites.map((e) => RoommateAd.fromJson(e)));
    } catch (_) {
    } finally {
      isLoading(false);
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

class FavoriteTab extends StatelessWidget implements HomeScreenSupportable {
  const FavoriteTab({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(_FavoriteTabController());
    return GetBuilder<_FavoriteTabController>(builder: (controller) {
      if (controller.isLoading.isTrue) {
        return const Center(child: CupertinoActivityIndicator());
      }
      if (controller.hasFetchError.isTrue) {
        return Center(
          child: Column(
            children: [
              const Text("Failed to fetch data"),
              OutlinedButton(
                onPressed: () {
                  controller._loadFavoritePropertyAds();
                  controller._loadFavoriteRoommateAds();
                },
                child: const Text("Refresh"),
              ),
            ],
          ),
        );
      }

      return TabBarView(
        controller: controller._tabController,
        children: [
          Builder(
            builder: (context) {
              if (controller.propertyAds.isEmpty) {
                return const Center(child: Text("No favorite property."));
              }
              return GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                shrinkWrap: true,
                children: List.generate(
                  controller.propertyAds.length,
                  (ind) {
                    final ad = controller.propertyAds[ind];
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        PropertyAdMiniWidget(
                          ad: ad,
                          onTap: () {
                            Get.to(() => ViewPropertyAd(ad: ad));
                          },
                        ),
                        IconButton(
                          onPressed: () async {
                            final res = await removeAdFromFavorite(
                              ad.toJson(),
                              "favorites-property-ads",
                            );
                            if (res) {
                              showToast("Ad removed");
                              controller.propertyAds.remove(ad);
                              controller.update();
                            }
                          },
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          Builder(
            builder: (context) {
              if (controller.roommateAds.isEmpty) {
                return const Center(child: Text("No favorite roommates."));
              }
              return GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                shrinkWrap: true,
                children: List.generate(
                  controller.roommateAds.length,
                  (ind) {
                    final ad = controller.roommateAds[ind];
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        RoommateAdMiniWidget(
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
                        ),
                        IconButton(
                          onPressed: () async {
                            final res = await removeAdFromFavorite(
                              ad.toJson(),
                              "favorites-roommates-ads",
                            );
                            if (res) {
                              showToast("Ad removed");
                              controller.roommateAds.remove(ad);
                              controller.update();
                            }
                          },
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      );
    });
  }

  @override
  AppBar get appBar {
    final controller = Get.put(_FavoriteTabController());
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      title: const Text('Favorites'),
      centerTitle: false,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            controller._loadFavoritePropertyAds();
            controller._loadFavoriteRoommateAds();
          },
          icon: const Icon(Icons.refresh),
        )
      ],
      bottom: TabBar(
        labelColor: ROOMY_ORANGE,
        indicatorColor: ROOMY_ORANGE,
        unselectedLabelColor: Colors.white,
        tabs: const [
          Tab(text: "Property Ads"),
          Tab(text: "Roommates Ads"),
        ],
        controller: controller._tabController,
        onTap: controller._currentTabIndex,
      ),
    );
  }

  @override
  BottomNavigationBarItem get navigationBarItem {
    return BottomNavigationBarItem(
      activeIcon: Image.asset("assets/icons/home/favorite.png", height: 30),
      icon: Image.asset(
        "assets/icons/home/favorite.png",
        height: 30,
        color: Colors.white,
      ),
      label: 'Favorites'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;

  @override
  void onIndexSelected(int index) {
    final controller = Get.put(_FavoriteTabController());
    controller._loadFavoritePropertyAds();
    controller._loadFavoriteRoommateAds();
  }
}
