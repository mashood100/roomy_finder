import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/ads.dart';
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
      final requestBody = <String, dynamic>{"skip": _skip, ...filter};
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
            Obx(() {
              return TextButton(
                onPressed: () async {
                  await changeAppCountry(context);
                  controller.filter.remove('city');
                  controller.filter.remove('location');
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
                automaticallyImplyLeading: false,
                toolbarHeight: 0,
                collapsedHeight: 0,
                expandedHeight: AppController.me.isGuest ? 300 : 250,
                flexibleSpace: FlexibleSpaceBar(
                  background: Builder(builder: (context) {
                    const list = [
                      "assets/images/roommates_1.jpg",
                      "assets/images/roommates_2.jpg",
                      "assets/images/roommates_3.jpg",
                    ];
                    return Column(
                      children: [
                        if (AppController.me.isGuest)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Get.offAllNamed("/registration");
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
                        TextField(
                          readOnly: true,
                          onTap: controller._showFilter,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            hintText: "Filter by gender, budget",
                            suffixIcon: IconButton(
                              onPressed: controller._showFilter,
                              icon: const Icon(Icons.filter_list),
                            ),
                            contentPadding:
                                const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          textInputAction: TextInputAction.search,
                        ),
                        Expanded(
                          child: CarouselSlider(
                            items: list.map((e) {
                              return Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Image.asset(
                                    e,
                                    width: Get.width,
                                    fit: BoxFit.cover,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(list.length, (ind) {
                                      return Text(
                                        "•",
                                        style: TextStyle(
                                          color: ind == list.indexOf(e)
                                              ? ROOMY_PURPLE
                                              : Colors.grey,
                                          fontSize: 50,
                                        ),
                                      );
                                    }),
                                  )
                                ],
                              );
                            }).toList(),
                            options: CarouselOptions(
                              autoPlayInterval: const Duration(seconds: 10),
                              pageSnapping: true,
                              autoPlay: true,
                              viewportFraction: 1,
                            ),
                            disableGesture: true,
                          ),
                        ),
                      ],
                    );
                  }),
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
                      return PropertyAdWidget(
                        ad: ad,
                        onTap: () async {
                          if (AppController.me.isGuest) {
                            showToast("Please register to see ad details");
                            return;
                          }
                          await Get.to(() => ViewPropertyAd(ad: ad));
                          controller.update();
                        },
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
