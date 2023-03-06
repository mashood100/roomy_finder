import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/data/cities.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/find_roommate_match.dart';

class _RoommateAdSearchQueryScreenController extends GetxController {
  _RoommateAdSearchQueryScreenController();

  late final PageController _pageController;
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  final city = _listOfCountries[0]["value"]!.obs;
  final _pageIndex = 0.obs;

  final locations = <String>[].obs;

  final type = "Studio".obs;
  final gender = "Male".obs;
  final locationSortKey = "".obs;
  final location = "".obs;
  final citySortKey = "".obs;

  @override
  void onInit() {
    _pageController = PageController();
    super.onInit();
  }

  List<String> get _areasBasedOnCity {
    switch (city.value) {
      case "Dubai":
        return dubaiCities;
      case "Abu Dhabi":
        return abuDahbiCities;
      case "Sharjah":
        return sharjahCities;
      case "Umm al-Quwain":
      case "Fujairah":
      case "Ajam":
        return [...jeddahCities, ...meccaCities, ...riyadhCities];
      default:
        return [
          ...jeddahCities,
          ...meccaCities,
          ...riyadhCities,
          ...dubaiCities,
          ...abuDahbiCities,
          ...sharjahCities,
        ];
    }
  }

  @override
  void onClose() {
    _pageController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.onClose();
  }

  void _moveToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  void _moveToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  Future<void> addLoctions() async {
    final loc = await showModalBottomSheet<String>(
      context: Get.context!,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            children: _areasBasedOnCity
                .where((e) => !locations.contains(e))
                .map(
                  (e) => GestureDetector(
                    onTap: () {
                      Get.back(result: e);
                    },
                    child: Card(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amber.shade900,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        height: 100,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          e,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (loc == null) return;

    locations.add(loc);
  }
}

class RoommateAdSearchQueryScreen extends StatelessWidget {
  const RoommateAdSearchQueryScreen({super.key, this.isPremium = false});
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_RoommateAdSearchQueryScreenController());
    return Scaffold(
      appBar: AppBar(
        title: isPremium
            ? const Text("Premium roommates filter")
            : const Text("Roommates filter"),
        bottom: controller._pageIndex.value == 1
            ? PreferredSize(
                preferredSize: Size(Get.width, kToolbarHeight),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "search",
                      isDense: true,
                    ),
                    onChanged: controller.locationSortKey,
                  ),
                ),
              )
            : null,
      ),
      body: Obx(() {
        return Padding(
          padding: const EdgeInsets.only(left: 5, right: 5, bottom: 50),
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: controller._pageIndex,
            controller: controller._pageController,
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        "What do you want?",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                          children: ["Studio", "Appartment", "House"].map((e) {
                        return RadioListTile<String>(
                          value: e,
                          groupValue: controller.type.value,
                          onChanged: (value) {
                            if (value != null) {
                              controller.type(value);
                            }
                          },
                          title: Text(e),
                        );
                      }).toList()),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        "What is your budget",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller._minBudgetController,
                            decoration: InputDecoration(
                              labelText: 'Min'.tr,
                              suffixText: 'AED',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'thisFieldIsRequired'.tr;
                              }
                              final numValue = int.tryParse(value);

                              if (numValue == null || numValue < 0) {
                                return 'invalidRoommateAdBudgetMessage'.tr;
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(priceRegex)
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: controller._maxBudgetController,
                            decoration: InputDecoration(
                              labelText: 'Max'.tr,
                              suffixText: 'AED',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'thisFieldIsRequired'.tr;
                              }
                              final numValue = int.tryParse(value);

                              if (numValue == null || numValue < 0) {
                                return 'invalidRoommateAdBudgetMessage'.tr;
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(priceRegex)
                            ],
                          ),
                        ),
                      ],
                    ),
                    // const SizedBox(height: 10),
                    // const Center(
                    //   child: Text(
                    //     "What gender do you prefer",
                    //     style: TextStyle(fontSize: 14),
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 10,
                    //     vertical: 5,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     borderRadius:
                    //         const BorderRadius.all(Radius.circular(20)),
                    //     border: Border.all(color: Colors.black54, width: 1),
                    //   ),
                    //   child: Row(
                    //     // mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       const Text("Gender"),
                    //       const Spacer(flex: 2),
                    //       Radio(
                    //         // title: const Text("Male"),
                    //         value: "Male",
                    //         groupValue: controller.gender.value,
                    //         onChanged: (value) {
                    //           if (value != null) controller.gender(value);
                    //         },
                    //       ),
                    //       const Text("Male"),
                    //       const Spacer(flex: 1),
                    //       Radio(
                    //         // title: const Text("Female"),
                    //         value: "Female",
                    //         groupValue: controller.gender.value,
                    //         onChanged: (value) {
                    //           if (value != null) controller.gender(value);
                    //         },
                    //       ),
                    //       const Text("Female"),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        "In which city do want to search?",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _listOfCountries.where((e) {
                        if (controller.citySortKey.trim().isEmpty) {
                          return true;
                        } else {
                          return e["value"]!
                              .toLowerCase()
                              .contains(controller.citySortKey.toLowerCase());
                        }
                      }).map((e) {
                        return GestureDetector(
                          onTap: () {
                            controller.city(e["value"]);
                          },
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Image.asset(
                                e["asset"]!,
                              ),
                              Container(
                                color: Colors.purple.withOpacity(0.5),
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      e["value"]!,
                                      textAlign: TextAlign.center,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    if (controller.city.value == e["value"])
                                      const Icon(Icons.circle,
                                          color: Colors.white)
                                    else
                                      const Icon(
                                        Icons.circle_outlined,
                                        color: Colors.white,
                                      )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text('In which locations do want to search?'.tr),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      // padding: const EdgeInsets.all(10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...controller.locations.map((e) {
                              return Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  padding: const EdgeInsets.only(left: 15),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(e),
                                      IconButton(
                                        onPressed: () {
                                          controller.locations.remove(e);
                                        },
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                      )
                                    ],
                                  ));
                            }).toList(),
                            IconButton(
                              onPressed: controller.addLoctions,
                              icon: const Icon(Icons.add_circle),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
              //
            ],
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Builder(builder: (context) {
          if (MediaQuery.of(context).viewInsets.bottom > 50) {
            return const SizedBox();
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  if (controller._pageIndex.value == 0) {
                    Get.back();
                  } else {
                    controller._moveToPreviousPage();
                  }
                },
                // icon: const Icon(Icons.arrow_left),
                child: controller._pageIndex.value == 0
                    ? Text("back".tr)
                    : Text("previous".tr),
              ),
              TextButton(
                onPressed: () {
                  switch (controller._pageIndex.value) {
                    case 0:
                      if (controller._minBudgetController.text.isEmpty) {
                        showToast("Min is required");
                        return;
                      }
                      if (controller._maxBudgetController.text.isEmpty) {
                        showToast("Max is required");
                        return;
                      }
                      controller._moveToNextPage();
                      break;
                    case 1:
                      if (controller.locations.isNotEmpty) {
                        Get.to(
                          () => FindRoommateMatchsScreen(
                            type: controller.type.value,
                            gender: controller.gender.value,
                            budget: {
                              "min": controller._minBudgetController.text,
                              "max": controller._maxBudgetController.text,
                            },
                            locations: controller.locations,
                          ),
                        );
                      } else {
                        showToast('Choose location');
                      }
                      break;

                    default:
                  }
                },
                child: Text("next".tr),
              ),
              // const Icon(Icons.arrow_right),
            ],
          );
        }),
      ),
    );
  }
}

const _listOfCountries = [
  {
    "value": "Dubai",
    "asset": "assets/images/dubai.png",
  },
  {
    "value": "Abu Dhabi",
    "asset": "assets/images/abu_dhabi.png",
  },
  {
    "value": "Sharjah",
    "asset": "assets/images/sharjah.png",
  },
  {
    "value": "Umm al-Quwain",
    "asset": "assets/images/umm_al_quwain.png",
  },
  {
    "value": "Fujairah",
    "asset": "assets/images/fujairah.png",
  },
  {
    "value": "Ajam",
    "asset": "assets/images/ajman.png",
  },
];
