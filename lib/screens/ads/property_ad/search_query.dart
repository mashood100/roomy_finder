import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/data/cities.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/screens/ads/property_ad/find_properties.dart';

class _PropertyAdSearchQueryScreenController extends GetxController {
  _PropertyAdSearchQueryScreenController();

  late final PageController _pageController;
  final _minBudgetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pageIndex = 0.obs;

  final citySortKey = "".obs;
  final rentType = "Monthly".obs;
  final city = _listOfCountries[0]["value"]!.obs;
  final location = "".obs;

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
  void onInit() {
    _pageController = PageController();
    unitedArabEmiteLocations.sort((a, b) => a.compareTo(b));
    super.onInit();
  }

  @override
  void onClose() {
    _pageController.dispose();
    _minBudgetController.dispose();
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
}

class PropertyAdSearchQueryScreen extends StatelessWidget {
  const PropertyAdSearchQueryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_PropertyAdSearchQueryScreenController());
    return Obx(() {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Looking for Properties"),
          backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            left: 5,
            right: 5,
            bottom: 50,
          ),
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
                        "Which rent period do yo want?",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    ...["Monthly", "Weekly", "Daily"].map((e) {
                      return InkWell(
                        onTap: () => controller.rentType(e),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Radio(
                                value: e,
                                groupValue: controller.rentType.value,
                                onChanged: (value) {
                                  controller.rentType(e);
                                },
                              ),
                              Text(
                                e,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "In which city do want to search?",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Search for location",
                        isDense: true,
                      ),
                      onChanged: controller.citySortKey,
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
                    const Text("Area"),
                    TypeAheadField<String>(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: controller._cityController,
                        decoration: const InputDecoration(
                          hintText: "Search for area",
                        ),
                      ),
                      itemBuilder: (context, itemData) {
                        return ListTile(
                          dense: true,
                          title: Text(itemData),
                        );
                      },
                      onSuggestionSelected: (suggestion) {
                        controller.location(suggestion);
                        controller._cityController.text = suggestion;
                      },
                      suggestionsCallback: (pattern) {
                        return controller._areasBasedOnCity.where(
                          (e) =>
                              e.toLowerCase().toLowerCase().contains(pattern),
                        );
                      },
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Builder(builder: (context) {
            if (MediaQuery.of(context).viewInsets.bottom > 50) {
              return const SizedBox();
            }
            final progress = controller._pageIndex.value.toDouble() + 1;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  color: const Color.fromRGBO(96, 15, 116, 1),
                  value: progress / 2,
                ),
                Row(
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
                    // Text('${controller._pageIndex.value + 1}/2'),
                    TextButton(
                      onPressed: () {
                        switch (controller._pageIndex.value) {
                          case 0:
                            controller._moveToNextPage();
                            break;
                          case 1:
                            if (controller.location.isNotEmpty) {
                              Get.to(
                                () => FindPropertiesAdsScreen(
                                  city: controller.city.value,
                                  location: controller.location.value,
                                ),
                              );
                            } else {
                              showToast('Area is required');
                            }
                            break;

                          default:
                        }
                      },
                      child: controller._pageIndex.value == 6
                          ? Text("save".tr)
                          : Text("next".tr),
                    ),
                    // const Icon(Icons.arrow_right),
                  ],
                ),
              ],
            );
          }),
        ),
      );
    });
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
