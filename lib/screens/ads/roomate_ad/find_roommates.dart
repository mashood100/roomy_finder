import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/ads.dart';
import 'package:roomy_finder/components/get_more_button.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/user/upgrade_plan.dart';
import 'package:roomy_finder/utilities/data.dart';

class _FindRoommatesController extends LoadingController {
  final RxMap<String, String> filter;
  final List<String>? locations;

  final RxList<String> interest = <String>[].obs;

  final canSeeDetails = AppController.me.isPremium.obs;

  final showFilter = false.obs;

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
    Map<String, String>? filter,
    this.locations,
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
      final requestBody = <String, dynamic>{"skip": _skip, ...filter};

      if (locations != null) requestBody["locations"] = locations;

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
                controller.showFilter(true);
                controller.update();
              },
              icon: const Icon(Icons.filter_list),
            ),
          ],
        ),
        body: GetBuilder<_FindRoommatesController>(
          builder: (controller) {
            if (controller.showFilter.isTrue) {
              return const RommateAdFilter();
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

class RommateAdFilter extends StatelessWidget {
  const RommateAdFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_FindRoommatesController());
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
                    color: ROOMY_ORANGE,
                  ),
                ),
                const Text(
                  "Find roommates",
                  style: TextStyle(
                    color: ROOMY_ORANGE,
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
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: "Search location",
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
                          suffixIcon: Icon(
                            Icons.search,
                            size: 25,
                            color: ROOMY_ORANGE,
                          ),
                        ),
                        onChanged: (val) {},
                      ),
                    ),
                  ),
                ),
                Card(
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.room_outlined,
                      color: ROOMY_ORANGE,
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
                          controller.filter["gender"] = (e);
                          controller.update();
                        },
                        child: Card(
                          elevation: 0,
                          color: controller.filter["gender"] == e
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
                                  color: controller.filter["gender"] == e
                                      ? Colors.white
                                      : Get.theme.appBarTheme.backgroundColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  e,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: controller.filter["gender"] == e
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
                    suffixText:
                        AppController.instance.country.value.currencyCode,
                    hintText: 'Minimum',
                    initialValue: controller.filter["minBudget"],
                    enabled: controller.isLoading.isFalse,
                    onChanged: (value) =>
                        controller.filter["minBudget"] = value,
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
                    suffixText:
                        AppController.instance.country.value.currencyCode,
                    hintText: 'Maximum',
                    initialValue: controller.filter["maxBudget"],
                    enabled: controller.isLoading.isFalse,
                    onChanged: (value) {
                      controller.filter["maxBudget"] = value;
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  controller.showFilter(false);
                  controller._fetchData();
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
      ),
    );
  }
}

class RoommateMatchWidget extends StatelessWidget {
  const RoommateMatchWidget({
    super.key,
    required this.ad,
    required this.canSeeDetails,
    this.onSeeDetails,
    this.onUpgrade,
  });

  final RoommateAd ad;
  final bool canSeeDetails;
  final void Function()? onSeeDetails;
  final void Function()? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10),
            ),
            child: CachedNetworkImage(
              imageUrl: ad.images[0],
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Looking for a roommate",
                      style: TextStyle(fontSize: 14),
                    ),
                    Text("${ad.aboutYou["occupation"]},"
                        " Age(${ad.aboutYou["age"]})"),
                    Text("${ad.address["country"]}, ${ad.address["location"]}"),
                  ],
                ),
                const Spacer(),
                if (!canSeeDetails)
                  ElevatedButton(
                    onPressed: onUpgrade,
                    child: const Text("Upgrage"),
                  )
                else
                  ElevatedButton(
                    onPressed: onSeeDetails,
                    child: const Text("See Details"),
                  )
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(
              left: 5,
              bottom: 10,
              right: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Budget"),
                    Text(
                      "${ad.budget} AED",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Moving date"),
                    Text(
                      Jiffy(ad.movingDate).yMMMEd,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
