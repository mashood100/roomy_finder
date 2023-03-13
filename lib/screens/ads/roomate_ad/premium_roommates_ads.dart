import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/get_more_button.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/user/upgrade_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PremiumRoommatesController extends LoadingController {
  final RxList<String> interest = <String>[].obs;

  final RxString gender = "Mix".obs;

  final showFilter = false.obs;

  final canSeeDetails = AppController.me.isPremium.obs;
  Future<void> changeCanSeeAds() async {
    final result = await Get.to(
      () => UpgragePlanScreen(
        skipCallback: () {
          canSeeDetails(true);
          showToast("You can now see ad details");
        },
      ),
    );
    switch (result) {
      case "ALREADY_PREMIUM":
        canSeeDetails(true);
        AppController.instance.user.update((val) {
          if (val == null) return;
          val.isPremium = true;
        });
        final pref = await SharedPreferences.getInstance();
        if (pref.get("user") != null) {
          AppController.instance.saveUser();
        }
        break;
      default:
    }
  }

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
      final requestBody = <String, dynamic>{"skip": _skip};

      // if (budget != null) requestBody["minBudget"] = budget!["min"];
      // if (budget != null) requestBody["maxBudget"] = budget!["max"];
      // if (gender != null) requestBody["gender"] = gender;
      // if (locations != null) requestBody["locations"] = locations;

      final res = await ApiService.getDio.post(
        "/ads/roommate-ad/premium",
        data: requestBody,
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
      update();
    }
  }
}

class PremiumRoommatesAdsScreen extends StatelessWidget {
  const PremiumRoommatesAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_PremiumRoommatesController());
    return RefreshIndicator(
      onRefresh: controller._fetchData,
      child: Obx(() {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Premium Roommates"),
            toolbarHeight: controller.showFilter.isTrue ? 0 : kToolbarHeight,
            actions: [
              IconButton(
                onPressed: () {
                  controller.showFilter(true);
                },
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
          body: GetBuilder<_PremiumRoommatesController>(
            builder: (context) {
              if (controller.showFilter.isTrue) {
                return const PremiumRommateAdFilter();
              }
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
                return Center(
                  child: Column(
                    children: [
                      const Text("No data."),
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
                  if (index == controller.ads.length) {
                    if (controller.ads.length.remainder(100) == 0) {
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
                  final ad = controller.ads[index];
                  return RoommateAdWidget(
                    ad: ad,
                    onTap: () {
                      if (controller.canSeeDetails.isFalse) {
                        controller.changeCanSeeAds();
                      } else {
                        Get.to(() => ViewRoommateAdScreen(ad: ad));
                      }
                    },
                  );
                },
                itemCount: controller.ads.length + 1,
              );
            },
          ),
        );
      }),
    );
  }
}

class PremiumRommateAdFilter extends StatelessWidget {
  const PremiumRommateAdFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_PremiumRoommatesController());
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.isLoading.isTrue) const SizedBox(),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    controller.showFilter(false);
                    controller.update();
                  },
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 40,
                    color: _defaultColor,
                  ),
                ),
                const Text(
                  "Find roommates",
                  style: TextStyle(
                    color: _defaultColor,
                    fontSize: 25,
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            const Text("Location", style: TextStyle(fontSize: 18)),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Search location",
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        suffixIcon: Icon(
                          Icons.search,
                          size: 25,
                          color: _defaultColor,
                        ),
                      ),
                      onChanged: (val) {},
                    ),
                  ),
                ),
                Card(
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.room_outlined,
                      color: _defaultColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Gender", style: TextStyle(fontSize: 18)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...["Female", "Male", "Mix"].map(
                    (e) {
                      return GestureDetector(
                        onTap: () {
                          controller.gender(e);
                        },
                        child: Card(
                          elevation: 0,
                          color: controller.gender.value == e
                              ? Get.theme.appBarTheme.backgroundColor
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  e == "Female"
                                      ? Icons.person_4_outlined
                                      : e == "Male"
                                          ? Icons.person_outlined
                                          : Icons.group_outlined,
                                  size: 30,
                                  color: controller.gender.value == e
                                      ? Colors.white
                                      : Get.theme.appBarTheme.backgroundColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  e,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: controller.gender.value == e
                                        ? Colors.white
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Interest
            const SizedBox(height: 10),
            const Text("Interest", style: TextStyle(fontSize: 18)),
            GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                ..._allInterests.map(
                  (e) {
                    return GestureDetector(
                      onTap: () {
                        if (controller.interest.contains(e)) {
                          controller.interest.remove(e);
                        } else {
                          controller.interest.add(e);
                        }
                      },
                      child: Card(
                        color: controller.interest.contains(e)
                            ? _defaultColor
                            : null,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.only(
                            right: 10,
                            left: 5,
                          ),
                          child: Text(
                            e,
                            style: TextStyle(
                              fontSize: 14,
                              color: controller.interest.contains(e)
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.showFilter(false);
                  controller._fetchData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _defaultColor,
                ),
                child: const Text(
                  "Search",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _defaultColor = Color.fromRGBO(255, 123, 77, 1);
const _allInterests = [
  "Music",
  "Reading",
  "Art",
  "Dance",
  "Yoga",
  "Sports",
  "Travel",
  "Shopping",
  "Learning",
  "Podcasting",
  "Blogging",
  "Marketing",
  "Writing",
  "Focus",
  "Chess",
  "Design",
  "Football",
  "Basketball",
  "Boardgames",
  "sketching",
  "Photography",
];
