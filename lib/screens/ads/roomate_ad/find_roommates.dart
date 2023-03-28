import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/get_more_button.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/user/upgrade_plan.dart';
import 'package:roomy_finder/utilities/data.dart';

class _FindRoommatesController extends LoadingController {
  final RxMap<String, String?> filter;

  final RxList<String> interest = <String>[].obs;

  final canSeeDetails = AppController.me.isPremium.obs;

  Future<void> changeCanSeeAds(RoommateAd ad) async {
    Get.to(() => UpgragePlanScreen(
          skipCallback: () {
            canSeeDetails(true);
            Get.to(() => ViewRoommateAdScreen(ad: ad));
          },
        ));
    update();
  }

  _FindRoommatesController({
    Map<String, String?>? filter,
  }) : filter = (filter ?? {}).obs;

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
      update();

      final requestBody = <String, dynamic>{"skip": _skip, ...filter};

      final res = await ApiService.getDio.post(
        "/ads/roommate-ad/available",
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

  Future<void> _showFilter() async {
    final filter = Map<String, String?>.from(this.filter);
    final result = await showModalBottomSheet<Map<String, String?>>(
      isScrollControlled: true,
      context: Get.context!,
      builder: (context) {
        return SizedBox(
          height: Get.height * 0.8,
          child: StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Get.back();
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        const Spacer(),
                        const Text(
                          "Filter",
                          style: TextStyle(
                            fontSize: 18,
                            color: ROOMY_ORANGE,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const Divider(),
                    // Action
                    InlineDropdown<String>(
                      labelText: 'Action'.tr,
                      hintText: 'What you want'.tr,
                      value: filter["action"],
                      items: const ["ALL", "HAVE ROOM", "NEED ROOM"],
                      onChanged: (val) {
                        if (val != null) filter["action"] = val;
                        if (val == "All") filter.remove("action");
                      },
                    ),
                    const SizedBox(height: 20),
                    // Roommate type
                    InlineDropdown<String>(
                      labelText: 'Type'.tr,
                      hintText: 'Preferred roommate'.tr,
                      value: filter["type"],
                      items: const ["All", "Studio", "Appartment", "House"],
                      onChanged: (val) {
                        if (val != null) filter["type"] = val;
                        if (val == "All") filter.remove("type");
                      },
                    ),
                    const SizedBox(height: 20),
                    // Rent type
                    InlineDropdown<String>(
                      labelText: 'Rent'.tr,
                      hintText: 'rentType'.tr,
                      value: filter["rentType"],
                      items: const ["All", "Monthly", "Weekly", "Daily"],
                      onChanged: (val) {
                        if (val != null) filter["rentType"] = val;
                        if (val == "All") filter.remove("rentType");
                      },
                    ),
                    const SizedBox(height: 20),
                    InlineDropdown<String>(
                      labelText: 'City',
                      hintText: AppController.instance.country.value.isUAE
                          ? 'Example : Dubai'
                          : "Example : Riyadh",
                      value: filter["city"],
                      items: CITIES_FROM_CURRENT_COUNTRY,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            filter["location"] = null;
                            filter["city"] = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    InlineDropdown<String>(
                      labelText: 'Area',
                      hintText: "Select for area",
                      value: filter["location"],
                      items: getLocationsFromCity(
                        filter["city"].toString(),
                      ),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            filter["location"] = val;
                          });
                        }
                      },
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
                                  setState(() {
                                    filter["gender"] = (e);
                                  });
                                },
                                child: Card(
                                  elevation: 0,
                                  color: filter["gender"] == e
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
                                          color: filter["gender"] == e
                                              ? Colors.white
                                              : Get.theme.appBarTheme
                                                  .backgroundColor,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          e,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: filter["gender"] == e
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
                    const SizedBox(height: 10),
                    const Text("Budget", style: TextStyle(fontSize: 18)),
                    Row(
                      children: [
                        Expanded(
                          child: InlineTextField(
                            labelWidth: 0,
                            suffixText: AppController
                                .instance.country.value.currencyCode,
                            hintText: 'Minimum',
                            initialValue: filter["minBudget"],
                            enabled: isLoading.isFalse,
                            onChanged: (value) {
                              setState(() {
                                filter["minBudget"] = value;
                              });
                            },
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(priceRegex)
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InlineTextField(
                            labelWidth: 0,
                            suffixText: AppController
                                .instance.country.value.currencyCode,
                            hintText: 'Maximum',
                            initialValue: filter["maxBudget"],
                            enabled: isLoading.isFalse,
                            onChanged: (value) {
                              setState(() {
                                filter["maxBudget"] = value;
                              });
                            },
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(priceRegex)
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            filter.clear();
                            this.filter.clear();
                            _fetchData();
                            Get.back();
                          },
                          child: const Text("Clear Filter"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Get.back(result: filter);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ROOMY_ORANGE,
                          ),
                          child: const Text(
                            "Search",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
    if (result != null) {
      this.filter.clear();
      this.filter.addAll(result);
      _fetchData();
    }
  }
}

class FindRoommatesScreen extends StatelessWidget {
  const FindRoommatesScreen({
    super.key,
    this.filter,
    this.locations,
  });
  final Map<String, String>? filter;

  final List<String>? locations;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_FindRoommatesController(filter: filter));
    return RefreshIndicator(
      onRefresh: controller._fetchData,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Roommates"),
          actions: [
            IconButton(
              onPressed: () {
                controller._showFilter();
              },
              icon: const Icon(Icons.filter_list),
            ),
          ],
        ),
        body: GetBuilder<_FindRoommatesController>(
          builder: (controller) {
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

            return CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  automaticallyImplyLeading: false,
                  toolbarHeight: 0,
                  collapsedHeight: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Image.asset(
                      "assets/images/premium_roommate.png",
                      width: Get.width,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SliverGrid.count(
                  crossAxisCount: 2,
                  children: controller.ads.map((e) {
                    return RoommateAdMiniWidget(
                      ad: e,
                      onTap: () {
                        Get.to(() => ViewRoommateAdScreen(ad: e));
                      },
                    );
                  }).toList(),
                ),
                if (controller.ads.length.remainder(100) == 0)
                  SliverToBoxAdapter(
                    child: GetMoreButton(
                      getMore: () {
                        controller._skip += 100;
                        controller._fetchData();
                      },
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }
}
