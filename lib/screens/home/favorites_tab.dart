import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: unused_element
class _FavoriteTabController extends LoadingController {
  final propertyAds = <PropertyAd>[];
  final roommateAds = <RoommateAd>[];

  @override
  void onInit() {
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

      final favorites = pref.getStringList("favorites-roommate-ads") ?? [];

      if (favorites.isEmpty) return;
      roommateAds.clear();
      roommateAds.addAll(favorites.map((e) => RoommateAd.fromJson(e)));
    } catch (_) {
    } finally {
      isLoading(false);
      update();
    }
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
                onPressed: controller._loadFavoritePropertyAds,
                child: const Text("Refresh"),
              ),
            ],
          ),
        );
      }
      if (controller.propertyAds.isEmpty) {
        return Center(
          child: Column(
            children: [
              const Text("No data."),
              OutlinedButton(
                onPressed: controller._loadFavoritePropertyAds,
                child: const Text("Refresh"),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        itemBuilder: (context, index) {
          final ad = controller.propertyAds[index];
          return PropertyAdWidget(
            ad: ad,
            onFavoriteTap: () async {
              removeAdFromFavorite(ad.toJson(), "favorites-property-ads");
              showToast("Removed from favorite");
            },
            onTap: () async {
              await Get.to(() => ViewPropertyAd(ad: ad));
              controller.update();
            },
          );
        },
        itemCount: controller.propertyAds.length,
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
          onPressed: controller._loadFavoritePropertyAds,
          icon: const Icon(Icons.refresh),
        )
      ],
    );
  }

  @override
  BottomNavigationBarItem get navigationBarItem {
    return BottomNavigationBarItem(
      icon: const Icon(CupertinoIcons.heart_fill),
      label: 'Favorites'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;
}
