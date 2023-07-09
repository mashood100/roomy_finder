import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/advertising.dart';
import 'package:roomy_finder/components/get_more_button.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/user/upgrade_plan.dart';
import 'package:roomy_finder/utilities/data.dart';

class _FindRoommatesController extends LoadingController {
  final RxMap<String, String?> filter;

  final RxList<String> interest = <String>[].obs;

  final canSeeDetails = AppController.me.isPremium.obs;

  Future<void> upgradeToSeeDetails(RoommateAd ad) async {
    await Get.to(() => UpgragePlanScreen(
          skipCallback: () {
            canSeeDetails(true);
            Get.to(() => ViewRoommateAdScreen(ad: ad));
          },
        ));
    update();
  }

  _FindRoommatesController({
    Map<String, String?>? filter,
  }) : filter = ({...?filter}).obs;

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

      final requestBody = <String, dynamic>{
        "skip": _skip,
        "countryCode": AppController.instance.country.value.code,
        ...filter,
      };

      final res = await Dio().post(
        "$API_URL/ads/roommate-ad/available",
        data: requestBody,
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
      if (e is DioException) {}
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
        return GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: Padding(
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
                        // Action

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            {"label": "Need Room", "value": "NEED ROOM"},
                            {"label": "Have Room", "value": "HAVE ROOM"},
                            {"label": "All", "value": null},
                          ].map((e) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (e["value"] != null) {
                                    filter['action'] = e["value"];
                                  } else {
                                    filter.remove("action");
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: filter["action"] == e["value"]
                                      ? ROOMY_ORANGE
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(10.0),
                                child: Text("${e["label"]}"),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),

                        const SizedBox(height: 20),
                        // Roommate type
                        InlineDropdown<String>(
                          labelText: 'Type'.tr,
                          hintText: 'Apartment type'.tr,
                          value: filter["type"],
                          items: const ["All", "Studio", "Apartment", "House"],
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
                          hintText: "Select gender",
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
                        const Text("Budget", style: TextStyle(fontSize: 14)),
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
                                    if (num.tryParse(value) != null) {
                                      filter["minBudget"] = value;
                                    } else {
                                      filter.remove("minBudget");
                                    }
                                  });
                                },
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        signed: true),
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
                                    if (num.tryParse(value) != null) {
                                      filter["maxBudget"] = value;
                                    } else {
                                      filter.remove("maxBudget");
                                    }
                                  });
                                },
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        signed: true),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ROOMY_PURPLE,
                                ),
                                onPressed: () {
                                  filter.clear();
                                  this.filter.clear();
                                  _fetchData();
                                  Get.back();
                                },
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
                                  backgroundColor: ROOMY_PURPLE,
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
            // Builder(builder: (context) {
            //   return IconButton(
            //     onPressed: () {
            //       Scaffold.of(context).openDrawer();
            //     },
            //     icon: const Icon(Icons.menu),
            //   );
            // }),
          ],
        ),
        body: GetBuilder<_FindRoommatesController>(
          builder: (controller) {
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
                              fillColor: Get.theme.scaffoldBackgroundColor,
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
                  SliverGrid.count(
                    crossAxisCount: 2,
                    children: controller.ads.map((ad) {
                      return _AdItem(
                        ad: ad,
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
                              controller.ads
                                  .removeWhere((e) => e.id == deletedId);
                            }
                          }
                        },
                      );
                    }).toList(),
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
          },
        ),
      ),
    );
  }
}

class _AdItem extends StatelessWidget {
  const _AdItem({
    required this.ad,
    this.onTap,
  });

  final RoommateAd ad;

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: ad.images.isEmpty
                            ? Image.asset(
                                "assets/images/default_room.png",
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : LoadingProgressImage(
                                image:
                                    CachedNetworkImageProvider(ad.images.first),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      InkWell(
                        onTap: () async {
                          await addAdToFavorite(
                              ad.toJson(), "favorites-roommate-ads");
                          showToast("Added to favorite");
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: ROOMY_PURPLE,
                          ),
                          child:
                              const Icon(Icons.favorite, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                    color: Colors.white,
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ad.poster.firstName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "${ad.aboutYou["gender"] ?? "N/A"}, ${ad.aboutYou["age"] ?? "N/A"}",
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.room,
                            color: ROOMY_PURPLE,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "${ad.address["location"]}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w100,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              child: Container(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 5,
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.6),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatMoney(ad.budget),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
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
