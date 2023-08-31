import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';

class _MyPropertyAdsController extends LoadingController {
  final RxList<PropertyAd> ads = <PropertyAd>[].obs;
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
        "/ads/property-ad/my-ads",
        queryParameters: query,
      );

      final data = (res.data as List).map((e) {
        try {
          var propertyAd = PropertyAd.fromMap(e);
          return propertyAd;
        } catch (e) {
          return null;
        }
      });

      if (isReFresh) {
        ads.clear();
        _skip = 0;
      }
      ads.addAll(data.whereType<PropertyAd>());
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      hasFetchError(true);
    } finally {
      isLoading(false);
    }
  }
}

class MyPropertyAdsScreen extends StatelessWidget {
  const MyPropertyAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_MyPropertyAdsController());
    final crossAxisCount = MediaQuery.sizeOf(context).width ~/ 300;

    return RefreshIndicator(
      onRefresh: controller._fetchData,
      child: Scaffold(
        appBar: AppBar(
          title: Text("My Property Ads".tr),
          backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
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

          if (controller.ads.isEmpty) {
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
                child: PropertyAdWidget(
                  ad: ad,
                  // isMiniView: true,
                  onTap: () async {
                    if (AppController.me.isGuest) {
                      showToast("Please register to see ad details");
                      return;
                    }
                    final result = await Get.to(() => ViewPropertyAd(ad: ad));
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
      ),
    );
  }
}
