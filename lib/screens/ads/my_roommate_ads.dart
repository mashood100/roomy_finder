import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/get_more_button.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';

class _MyRoommateAdsController extends LoadingController
    with GetSingleTickerProviderStateMixin {
  late final TabController _tabController;
  final RxList<RoommateAd> ads = <RoommateAd>[].obs;
  @override
  void onInit() {
    _tabController = TabController(length: 2, vsync: this);
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

      final data = (res.data as List).map((e) => RoommateAd.fromMap(e));

      if (isReFresh) {
        ads.clear();
        _skip = 0;
      }
      ads.addAll(data);
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
    return RefreshIndicator(
      onRefresh: controller._fetchData,
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 25,
          title: Text("My Ads".tr),
          actions: [
            Obx(() {
              return IconButton(
                onPressed:
                    controller.isLoading.isTrue ? null : controller._fetchData,
                icon: const Icon(Icons.refresh),
              );
            }),
          ],
          bottom: TabBar(
            controller: controller._tabController,
            tabs: const [
              Tab(child: Text("Premium Ads")),
              Tab(child: Text("Roommate match")),
            ],
          ),
        ),
        body: TabBarView(
            controller: controller._tabController,
            children: List.generate(2, (genIndex) {
              return Obx(() {
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

                final data = controller.ads.where((ad) {
                  if (genIndex == 0) return ad.isPremium;
                  return !ad.isPremium;
                }).toList();

                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Text(genIndex == 0
                            ? "No premium ads"
                            : "No roommate match"),
                        OutlinedButton(
                          onPressed: controller._fetchData,
                          child: const Text("Refresh"),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemBuilder: (context, index) {
                    if (index == data.length) {
                      if (data.length.remainder(100) == 0) {
                        return GetMoreButton(
                          getMore: () {
                            controller._skip += 100;
                            controller._fetchData();
                          },
                        );
                      } else {
                        return const SizedBox();
                      }
                    }
                    final ad = data[index];
                    return RoommateAdWidget(
                      ad: ad,
                      onTap: () => Get.to(() => ViewRoommateAdScreen(ad: ad)),
                    );
                  },
                  itemCount: data.length + 1,
                );
              });
            })),
      ),
    );
  }
}
