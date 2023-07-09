import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/advertising.dart';
import 'package:roomy_finder/components/get_more_button.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/utilities/data.dart';

class _FindPropertiesController extends LoadingController {
  final RxMap<String, String?> filter;

  _FindPropertiesController({
    Map<String, String?>? filter,
  }) : filter = ({...?filter}).obs;

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
      final requestBody = <String, dynamic>{
        "skip": _skip,
        "countryCode": AppController.instance.country.value.code,
        ...filter,
      };
      final res = await Dio().post(
        "$API_URL/ads/property-ad/available",
        data: requestBody,
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

  Future<void> _showFilter() async {
    final filter = Map<String, String?>.from(this.filter);
    final result = await showModalBottomSheet<Map<String, String?>>(
      isScrollControlled: true,
      context: Get.context!,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
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

                      // Property type
                      InlineDropdown<String>(
                        labelText: 'Type'.tr,
                        hintText: 'What do you want'.tr,
                        value: filter["type"],
                        items: const [
                          "All",
                          "Bed",
                          "Partition",
                          "Room",
                          "Master Room"
                        ],
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
                        value: filter["preferedRentType"],
                        items: const ["All", "Monthly", "Weekly", "Daily"],
                        onChanged: (val) {
                          if (val != null) filter["preferedRentType"] = val;
                          if (val == "All") filter.remove("preferedRentType");
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
                              filter.remove("location");
                              filter["city"] = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      InlineDropdown<String>(
                        labelText: 'Area',
                        hintText: "Select the location",
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
                      const SizedBox(height: 20),
                      InlineDropdown<String>(
                        labelText: 'Gender',
                        hintText: "Gender you prefer",
                        value: filter["gender"],
                        items: const ["Female", "Male", "Mix"],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              filter["gender"] = val;
                            });
                          }
                        },
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
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed: () {
                                filter.clear();
                                this.filter.clear();
                                _fetchData();
                                Get.back();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ROOMY_ORANGE,
                              ),
                              child: const Text(
                                "Clear Filter",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
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

class FindPropertiesAdsScreen extends StatelessWidget {
  const FindPropertiesAdsScreen({super.key, this.filter});
  final Map<String, String?>? filter;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_FindPropertiesController(filter: filter));
    return RefreshIndicator(
      onRefresh: controller._fetchData,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
          title: Text("properpyAds".tr),
          actions: [
            Obx(() {
              return TextButton(
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
              );
            }),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CupertinoActivityIndicator());
          }

          return CustomScrollView(
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
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
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
                    childCount: controller.ads.length,
                  ),
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
          );
        }),
      ),
    );
  }
}
