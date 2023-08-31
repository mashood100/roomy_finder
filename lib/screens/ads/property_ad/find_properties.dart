import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/advertising.dart';
import 'package:roomy_finder/components/get_more_button.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/filter.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/utilities/data.dart';

class _FindPropertiesController extends LoadingController {
  final RxMap<String, dynamic> filter = <String, dynamic>{}.obs;

  _FindPropertiesController(
      {Map<String, String?>? initialFilter, this.initialSkip}) {
    if (initialFilter != null) filter.addAll(initialFilter);
  }

  final RxList<PropertyAd> ads = <PropertyAd>[].obs;
  final int? initialSkip;

  @override
  void onInit() {
    _skip = initialSkip ?? 0;
    _fetchData();
    super.onInit();
  }

  int _skip = 0;

  Future<void> _fetchData({bool isReFresh = false}) async {
    try {
      isLoading(true);
      hasFetchError(false);
      if (isReFresh) {
        _skip = 0;
      }

      final requestBody = <String, dynamic>{
        "skip": _skip,
        "countryCode": AppController.instance.country.value.code,
        ...filter,
      };

      Map? preferences;

      if (filter["preferences"] != null) {
        preferences = {};

        for (var item in List.from(filter["preferences"])) {
          preferences[item['value']] = true;
        }
        if (preferences.isNotEmpty) requestBody["preferences"] = preferences;
      } else {
        requestBody.remove("preferences");
      }

      final res = await Dio().post(
        "$API_URL/ads/property-ad/available",
        data: requestBody,
      );

      final data = (res.data as List).map((e) {
        try {
          var propertyAd = PropertyAd.fromMap(e);
          return propertyAd;
        } catch (e, trace) {
          Get.log("$trace");
          return null;
        }
      });
      if (isReFresh) {
        ads.clear();
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

  Future<void> _showFilter() async {
    final result =
        await Get.to(() => PropertyAdsFilterScreen(oldFilter: filter));
    if (result is Map<String, dynamic>) {
      filter.clear();
      filter.addAll(result);
      _fetchData(isReFresh: true);
    }
  }
}

class FindPropertiesAdsScreen extends StatelessWidget {
  const FindPropertiesAdsScreen({super.key, this.filter, this.initialSkip});
  final Map<String, String?>? filter;
  final int? initialSkip;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_FindPropertiesController(
        initialFilter: filter, initialSkip: initialSkip));
    final crossAxisCount = MediaQuery.sizeOf(context).width ~/ 300;
    return RefreshIndicator(
      onRefresh: () => controller._fetchData(isReFresh: true),
      child: Obx(() {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
            title: Text("properpyAds".tr),
            actions: [
              TextButton(
                onPressed: () async {
                  await changeAppCountry(context);
                  controller.filter.remove('city');
                  controller.filter.remove('location');
                  controller._fetchData(isReFresh: true);
                },
                // icon: const Icon(Icons.arrow_drop_down, size: 40),
                child: Text(
                  AppController.instance.country.value.flag,
                  style: const TextStyle(fontSize: 25),
                ),
              )
            ],
          ),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    backgroundColor: Colors.white,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 0,
                    collapsedHeight: 0,
                    expandedHeight: AppController.me.isGuest ? 330 : 280,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Column(
                        children: [
                          if (AppController.me.isGuest)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Get.offAllNamed("/login");
                                  },
                                  child: const Text(
                                    "REGISTER",
                                    style: TextStyle(
                                      color: ROOMY_PURPLE,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.offAllNamed("/login");
                                  },
                                  child: const Text(
                                    "LOGIN",
                                    style: TextStyle(
                                      color: ROOMY_ORANGE,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const Expanded(child: AdvertisingWidget()),
                          Container(
                            color: Get.theme.scaffoldBackgroundColor,
                            padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                            child: TextField(
                              readOnly: true,
                              onTap: controller._showFilter,
                              decoration: InputDecoration(
                                fillColor: Colors.white,
                                hintText: "Filter by gender, budget",
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GestureDetector(
                                    onTap: controller._showFilter,
                                    child: Image.asset(
                                      "assets/icons/filter.png",
                                      height: 30,
                                      width: 30,
                                    ),
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets.fromLTRB(12, 10, 12, 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              textInputAction: TextInputAction.search,
                            ),
                          ),
                          Container(color: Colors.white, height: 10),
                        ],
                      ),
                    ),
                  ),
                  if (controller.hasFetchError.isTrue)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          children: [
                            const Text("Failed to fetch data"),
                            OutlinedButton(
                              onPressed: () {
                                controller._fetchData(isReFresh: true);
                              },
                              child: const Text("Refresh"),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (controller.ads.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          children: [
                            const Text("No data."),
                            OutlinedButton(
                              onPressed: () {
                                controller._fetchData(isReFresh: true);
                              },
                              child: const Text("Refresh"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverGrid.builder(
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
                                controller.ads
                                    .removeWhere((e) => e.id == deletedId);
                              }
                            }
                            controller.update();
                          },
                        ),
                      );
                    },
                    itemCount: controller.ads.length,
                  ),
                  if (controller.ads.length.remainder(100) == 0 &&
                      controller.ads.isNotEmpty)
                    SliverToBoxAdapter(
                      child: GetMoreButton(
                        getMore: () {
                          controller._skip += 100;
                          controller._fetchData();
                        },
                      ),
                    )
                ],
              ),
              if (controller.isLoading.isTrue) const LoadingPlaceholder()
            ],
          ),
        );
      }),
    );
  }
}
