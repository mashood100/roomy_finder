import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';

class _MyRoommateAdsController extends LoadingController {
  final RxList<RoommateAd> ads = <RoommateAd>[].obs;
  @override
  void onInit() {
    _fetchData();
    super.onInit();
  }

  int _skip = 0;

  Future<void> _fetchData({bool isReFresh = true}) async {
    try {
      isLoading(true);
      hasFetchError(false);
      final query = {"ship": _skip};

      final res = await ApiService.getDio.get(
        "/ads/roommate-ad/my-ads",
        queryParameters: query,
      );

      final data = (res.data as List).map((e) {
        try {
          var propertyAd = RoommateAd.fromMap(e);
          return propertyAd;
        } catch (e) {
          return null;
        }
      });

      if (isReFresh) {
        ads.clear();
        _skip = 0;
      }
      ads.addAll(data.whereType<RoommateAd>());
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      hasFetchError(true);
    } finally {
      isLoading(false);
    }
  }
}

class MyRoommateAdsScreen extends StatelessWidget {
  const MyRoommateAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_MyRoommateAdsController());
    final crossAxisCount = MediaQuery.sizeOf(context).width ~/ 300;
    return RefreshIndicator(
      onRefresh: controller._fetchData,
      child: Scaffold(
        appBar: AppBar(
          title: Text("My Roommate ads".tr),
          actions: [
            Obx(() {
              return IconButton(
                onPressed:
                    controller.isLoading.isTrue ? null : controller._fetchData,
                icon: const Icon(Icons.refresh),
              );
            }),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (controller.hasFetchError.isTrue) {
            return Center(
              child: Column(
                children: [
                  const Text("Failed to fetch data"),
                  OutlinedButton(
                    onPressed: controller._fetchData,
                    child: const Text("Refresh"),
                  ),
                ],
              ),
            );
          }

          final data = controller.ads;

          if (data.isEmpty) {
            return const Center(child: Text("No data"));
          }

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              final ad = controller.ads[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: RoommateAdWidget(
                  ad: ad,
                  // isMiniView: true,
                  onTap: () async {
                    if (AppController.me.isGuest) {
                      showToast("Please register to see ad details");
                      return;
                    }
                    final result =
                        await Get.to(() => ViewRoommateAdScreen(ad: ad));
                    if (result is Map<String, dynamic>) {
                      final deletedId = result["deletedId"];
                      if (deletedId != null) {
                        controller.ads.removeWhere((e) => e.id == deletedId);
                      }
                    }
                    controller.update();
                  },
                ),
              );
            },
            itemCount: controller.ads.length,
          );
        }),
        floatingActionButton: controller.ads.length.isGreaterThan(100)
            ? FloatingActionButton(
                onPressed: () {
                  controller._skip += 100;
                  controller._fetchData();
                },
              )
            : null,
      ),
    );
  }
}
