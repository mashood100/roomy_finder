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
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/view_ad.dart';
import 'package:roomy_finder/utilities/data.dart';

class _FindPropertiesController extends LoadingController {
  final RxMap<String, String?> filter;

  _FindPropertiesController({
    Map<String, String?>? filter,
  }) : filter = (filter ?? {}).obs;

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
      final requestBody = <String, dynamic>{"skip": _skip, ...filter};
      final res = await ApiService.getDio.post(
        "/ads/property-ad/available",
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

                    // Property type
                    InlineDropdown<String>(
                      labelText: 'Type'.tr,
                      hintText: 'Want do you want'.tr,
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
            IconButton(
              onPressed: () {
                controller._showFilter();
              },
              icon: const Icon(Icons.filter_list),
            ),
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
              return PropertyAdWidget(
                ad: ad,
                onTap: () async {
                  await Get.to(() => ViewPropertyAd(ad: ad));
                  controller.update();
                },
              );
            },
            itemCount: controller.ads.length + 1,
          );
        }),
      ),
    );
  }
}
