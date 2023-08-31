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
import 'package:roomy_finder/helpers/roomy_notification.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/filter.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/view_ad.dart';
import 'package:roomy_finder/screens/chat/chat_room/chat_room_screen.dart';
import 'package:roomy_finder/screens/user/upgrade_plan.dart';
import 'package:roomy_finder/utilities/data.dart';

class _FindRoommatesAdsController extends LoadingController {
  final RxMap<String, dynamic> filter = <String, dynamic>{}.obs;

  _FindRoommatesAdsController(
      {Map<String, String?>? initialFilter, this.initialSkip}) {
    if (initialFilter != null) filter.addAll(initialFilter);
  }

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

  final RxList<RoommateAd> ads = <RoommateAd>[].obs;
  final int? initialSkip;

  final _filterIsApplied = false.obs;
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
      update();

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
        "$API_URL/ads/roommate-ad/available",
        data: requestBody,
      );

      final data = (res.data as List).map((e) {
        try {
          var propertyAd = RoommateAd.fromMap(e);
          return propertyAd;
        } catch (e, trace) {
          Get.log("$trace");
          return null;
        }
      });

      if (isReFresh) {
        ads.clear();
        _filterIsApplied(false);
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
    final result =
        await Get.to(() => RoommatesAdsFilterScreen(oldFilter: filter));
    if (result is Map<String, dynamic>) {
      filter.clear();
      filter.addAll(result);
      _fetchData(isReFresh: true);
    }
  }
}

class FindRoommateAdsScreen extends StatelessWidget {
  const FindRoommateAdsScreen(
      {super.key, this.filter, this.locations, this.initialSkip});
  final Map<String, String>? filter;

  final List<String>? locations;
  final int? initialSkip;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_FindRoommatesAdsController(
        initialFilter: filter, initialSkip: initialSkip));

    return RefreshIndicator(
      onRefresh: () => controller._fetchData(isReFresh: true),
      child: Obx(() {
        final crossAxisCount = MediaQuery.sizeOf(context).width ~/
            (controller._filterIsApplied.isFalse ? 300 : 150);
        return Scaffold(
          appBar: AppBar(
            title: const Text("Roommates"),
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
                        child: RoommateAdWidget(
                          ad: ad,
                          isMiniView: controller._filterIsApplied.isTrue,
                          onChat: () {
                            if (AppController.me.isGuest) {
                              RoomyNotificationHelper
                                  .showRegistrationRequiredToChat();
                            } else {
                              moveToChatRoom(AppController.me, ad.poster);
                            }
                          },
                          onTap: () async {
                            if (AppController.me.isGuest) {
                              showToast("Please register to see ad details");
                              return;
                            }
                            final result = await Get.to(
                                () => ViewRoommateAdScreen(ad: ad));
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

// class _AdItem extends StatelessWidget {
//   const _AdItem({
//     required this.ad,
//     this.onTap,
//   });

//   final RoommateAd ad;

//   final void Function()? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Card(
//         child: Stack(
//           alignment: Alignment.bottomLeft,
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Stack(
//                     alignment: Alignment.bottomRight,
//                     children: [
//                       ClipRRect(
//                         borderRadius: const BorderRadius.vertical(
//                           top: Radius.circular(10),
//                         ),
//                         child: ad.images.isEmpty
//                             ? Image.asset(
//                                 "assets/images/default_room.png",
//                                 width: double.infinity,
//                                 fit: BoxFit.cover,
//                               )
//                             : LoadingProgressImage(
//                                 image:
//                                     CachedNetworkImageProvider(ad.images.first),
//                                 width: double.infinity,
//                                 fit: BoxFit.cover,
//                               ),
//                       ),
//                       InkWell(
//                         onTap: () async {
//                           await addAdToFavorite(
//                               ad.toJson(), "favorites-roommate-ads");
//                           showToast("Added to favorite");
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(5),
//                           decoration: const BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: ROOMY_PURPLE,
//                           ),
//                           child:
//                               const Icon(Icons.favorite, color: Colors.white),
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//                 Container(
//                   decoration: const BoxDecoration(
//                     borderRadius: BorderRadius.vertical(
//                       bottom: Radius.circular(10),
//                     ),
//                     color: Colors.white,
//                   ),
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(5.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         ad.poster.firstName,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                         ),
//                       ),
//                       Text(
//                         "${ad.aboutYou["gender"] ?? "N/A"}, ${ad.aboutYou["age"] ?? "N/A"}",
//                         style: const TextStyle(
//                           fontSize: 16,
//                         ),
//                       ),
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(
//                             Icons.room,
//                             color: ROOMY_PURPLE,
//                             size: 18,
//                           ),
//                           const SizedBox(width: 5),
//                           Text(
//                             "${ad.address["location"]}",
//                             style: const TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w100,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             Positioned(
//               child: Container(
//                 alignment: Alignment.centerLeft,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 5,
//                     horizontal: 5,
//                   ),
//                   margin: const EdgeInsets.only(bottom: 20),
//                   decoration: BoxDecoration(
//                     color: Colors.red.withOpacity(0.6),
//                     borderRadius: const BorderRadius.horizontal(
//                       right: Radius.circular(20),
//                     ),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         formatMoney(ad.budget),
//                         style: const TextStyle(
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
