import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/helpers/favorite_helper.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/user/upgrade_plan.dart';
import 'package:roomy_finder/utilities/data.dart';

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

      var data = await FovoritePropertyAdHelper.getAllFavorites();
      propertyAds.clear();
      propertyAds.addAll(data);
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

      var data = await FovoriteRoommateAdHelper.getAllFavorites();
      roommateAds.clear();
      roommateAds.addAll(data);
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

class FavoriteScreen extends StatelessWidget implements HomeScreenSupportable {
  const FavoriteScreen({super.key});

  @override
  void onTabIndexSelected(int index) {
    final controller = Get.find<_FavoriteTabController>();

    controller._loadFavoritePropertyAds();
    controller._loadFavoriteRoommateAds();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_FavoriteTabController());
    return Scaffold(
      appBar: AppBar(
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
        bottom: AppController.me.isRoommate
            ? TabBar(
                labelColor: ROOMY_ORANGE,
                indicatorColor: ROOMY_ORANGE,
                unselectedLabelColor: Colors.white,
                tabs: const [
                  Tab(text: "Property Ads"),
                  Tab(text: "Roommates Ads"),
                ],
                controller: controller._tabController,
                onTap: controller._currentTabIndex,
              )
            : null,
      ),
      body: GetBuilder<_FavoriteTabController>(builder: (controller) {
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
          physics: !AppController.me.isRoommate
              ? const NeverScrollableScrollPhysics()
              : null,
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
                          PropertyAdWidget(
                            ad: ad,
                            isMiniView: true,
                            onTap: () async {
                              await Get.to(() => ViewPropertyAd(ad: ad));
                              controller._loadFavoritePropertyAds();
                            },
                          ),
                          IconButton(
                            onPressed: () async {
                              final res = await FovoritePropertyAdHelper
                                  .removeFromFavorites(ad.id);
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
                          RoommateAdWidget(
                            ad: ad,
                            isMiniView: true,
                            onTap: () async {
                              if (AppController.me.isGuest) {
                                Get.offAllNamed("/login");
                                return;
                              }
                              await Get.to(() => ViewRoommateAdScreen(ad: ad));
                              controller._loadFavoriteRoommateAds();
                            },
                          ),
                          IconButton(
                            onPressed: () async {
                              final res = await FovoriteRoommateAdHelper
                                  .removeFromFavorites(ad.id);
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
      }),
      // bottomNavigationBar: const HomeBottomNavigationBar(),
    );
  }
}
