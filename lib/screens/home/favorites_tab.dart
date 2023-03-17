import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: unused_element
class _FavoriteTabController extends LoadingController {
  final ads = <PropertyAd>[];

  @override
  void onInit() {
    super.onInit();
    _loadFavoritePropertyAd();
  }

  Future<void> _loadFavoritePropertyAd() async {
    try {
      isLoading(true);
      update();
      final pref = await SharedPreferences.getInstance();

      final favorites = pref.getStringList("favorites-property-ads") ?? [];

      if (favorites.isEmpty) return;
      ads.clear();
      ads.addAll(favorites.map((e) => PropertyAd.fromJson(e)));
    } catch (_) {
    } finally {
      isLoading(false);
      update();
    }
  }

  _removeFromFavorite(PropertyAd ad) async {
    try {
      update();
      final pref = await SharedPreferences.getInstance();

      final favorites = pref.getStringList("favorites-property-ads") ?? [];
      favorites.remove(ad.toJson());
      pref.setStringList("favorites-property-ads", favorites);

      ads.remove(ad);
    } catch (e, trace) {
      Get.log("$e\n$trace");
    } finally {
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
                onPressed: controller._loadFavoritePropertyAd,
                child: const Text("Refresh"),
              ),
            ],
          ),
        );
      }
      if (controller.ads.isEmpty) {
        return Center(
          child: Column(
            children: [
              const Text("No data."),
              OutlinedButton(
                onPressed: controller._loadFavoritePropertyAd,
                child: const Text("Refresh"),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        itemBuilder: (context, index) {
          final ad = controller.ads[index];
          return PropertyAdWidget(
            ad: ad,
            onFavoriteTap: () => controller._removeFromFavorite(ad),
            onTap: () async {
              await Get.to(() => ViewPropertyAd(ad: ad));
              controller.update();
            },
          );
        },
        itemCount: controller.ads.length,
      );
    });
  }

  @override
  AppBar get appBar {
    final controller = Get.put(_FavoriteTabController());
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      automaticallyImplyLeading: false,
      title: const Text('Favorites'),
      centerTitle: false,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: controller._loadFavoritePropertyAd,
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
