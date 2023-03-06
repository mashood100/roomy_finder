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

class _FindRoommateMatchController extends LoadingController {
  final Map<String, String>? budget;
  final String? gender;
  final List<String>? locations;
  final String? type;

  final canSeeDetails = AppController.me.isPremium.obs;

  Future<void> upGrade() async {
    final result = await Get.to(() => const DepositScreen());
    update();

    if (result == true) {
      canSeeDetails(true);
    }
  }

  _FindRoommateMatchController({
    this.budget,
    this.gender,
    this.type,
    this.locations,
  });

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
      if (gender != null) requestBody["gender"] = gender;
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
      child: Scaffold(
        appBar: AppBar(title: const Text("Roommates Match")),
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
          return GetBuilder<_FindRoommateMatchController>(
              builder: (controller) {
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
                  onUpgrade: controller.upGrade,
                );
              },
              itemCount: controller.ads.length + 1,
            );
          });
        }),
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
            child: Image.network(
              ad.images[0],
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, trace) {
                return const SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: Icon(
                    Icons.broken_image,
                    size: 50,
                  ),
                );
              },
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
