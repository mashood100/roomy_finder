import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/get_more_button.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/deposit_screen.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';

const _defaultColor = Color.fromRGBO(255, 123, 77, 1);

class _FindRoommateMatchController extends LoadingController {
  final Map<String, String>? budget;
  final List<String>? locations;
  final String? type;

  final RxList<String> interest = <String>[].obs;

  final RxString gender;

  final canSeeDetails = AppController.me.isPremium.obs;

  final showFilter = false.obs;

  Future<void> upGradePlan() async {
    final result = await Get.to(() => const DepositScreen());
    update();

    if (result == true) {
      canSeeDetails(true);
    }
  }

  _FindRoommateMatchController({
    this.budget,
    String? gender,
    this.type,
    this.locations,
  }) : gender = (gender ?? "Mix").obs;

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

      if (budget != null) requestBody["minBudget"] = budget!["min"];
      if (budget != null) requestBody["maxBudget"] = budget!["max"];
      requestBody["gender"] = gender.value;
      if (type != null) requestBody["type"] = type;
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

class FindRoommateMatchsScreen extends StatelessWidget {
  const FindRoommateMatchsScreen({
    super.key,
    this.budget,
    this.type,
    this.locations,
    this.gender,
  });
  final Map<String, String>? budget;
  final String? type;
  final List<String>? locations;
  final String? gender;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_FindRoommateMatchController(
      gender: gender,
      type: type,
      budget: budget,
      locations: locations,
    ));
    return RefreshIndicator(
      onRefresh: controller._fetchData,
      child: Obx(() {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Roommates Match"),
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
          body: GetBuilder<_FindRoommateMatchController>(
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
                  return RoommateMatchWidget(
                    ad: ad,
                    onSeeDetails: () =>
                        Get.to(() => ViewRoommateAdScreen(ad: ad)),
                    canSeeDetails: controller.canSeeDetails.value,
                    onUpgrade: controller.upGradePlan,
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

class RommateAdFilter extends StatelessWidget {
  const RommateAdFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_FindRoommateMatchController());
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
                    color: Colors.blue,
                  ),
                ),
                const Text(
                  "Find roommates",
                  style: TextStyle(
                    color: Colors.blue,
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
                          color: Colors.blue,
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
                      color: Colors.blue,
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
                  backgroundColor: Colors.blue,
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
