import 'package:flutter/material.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/place_autocomplete.dart';
import 'package:roomy_finder/components/place_seach_delagate.dart';
import 'package:roomy_finder/data/cities.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/screens/ads/property_ad/find_properties.dart';

class _PropertyAdSearchQueryScreenController extends GetxController {
  _PropertyAdSearchQueryScreenController();

  final _minBudgetController = TextEditingController();
  final _cityController = TextEditingController();

  final citySortKey = "".obs;
  final rentType = "Monthly".obs;
  final city = _listOfUAECities[0]["value"]!.obs;
  final location = "".obs;

  @override
  void onInit() {
    unitedArabEmiteLocations.sort((a, b) => a.compareTo(b));
    super.onInit();
  }

  @override
  void onClose() {
    _minBudgetController.dispose();
    super.onClose();
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  children: _listOfUAECities.where((e) {
                    if (controller.citySortKey.trim().isEmpty) {
                      return true;
                    } else {
                      return "${e["value"]}"
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
                            "${e["asset"]}",
                          ),
                          Container(
                            color: Colors.purple.withOpacity(0.5),
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${e["value"]}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (controller.city.value == e["value"])
                                  const Icon(Icons.circle, color: Colors.white)
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
                TextFormField(
                  readOnly: true,
                  controller: controller._cityController,
                  decoration: InputDecoration(
                    hintText:
                        '20 Dhabyan Street - Abu Dhabi -United Arab Emirate'.tr,
                    suffixIcon: IconButton(
                      onPressed: () {
                        controller.location('');
                        controller._cityController.clear();
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'thisFieldIsRequired'.tr;
                    }
                    return null;
                  },
                  onTap: () async {
                    final result = await showSearch(
                      context: context,
                      delegate: PlaceSearchDelegate(
                        initialstring: controller.location.value,
                      ),
                    );

                    if (result is PlaceAutoCompletePredicate) {
                      controller.location(result.mainText);
                      controller._cityController.text = result.mainText;
                    }
                  },
                ),

                // TypeAheadField<String>(
                //   textFieldConfiguration: TextFieldConfiguration(
                //     controller: controller._cityController,
                //     decoration: const InputDecoration(
                //       hintText: "Search for area",
                //     ),
                //   ),
                //   itemBuilder: (context, itemData) {
                //     return ListTile(
                //       dense: true,
                //       title: Text(itemData),
                //     );
                //   },
                //   onSuggestionSelected: (suggestion) {
                //     controller.location(suggestion);
                //     controller._cityController.text = suggestion;
                //   },
                //   suggestionsCallback: (pattern) {
                //     return controller._areasBasedOnCity.where(
                //       (e) => e.toLowerCase().toLowerCase().contains(pattern),
                //     );
                //   },
                // ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
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
                  onPressed: () => Get.back(),
                  // icon: const Icon(Icons.arrow_left),
                  child: Text("back".tr),
                ),
                // Text('${controller._pageIndex.value + 1}/2'),
                TextButton(
                  onPressed: () {
                    if (controller.location.isNotEmpty) {
                      Get.to(
                        () => FindPropertiesAdsScreen(
                          city: "${controller.city.value}",
                          location: controller.location.value,
                        ),
                      );
                    } else {
                      showToast('Area is required');
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
    });
  }
}

const _listOfUAECities = [
  {
    "value": "Dubai",
    "asset": "assets/images/dubai.png",
    "cities": dubaiCities,
  },
  {
    "value": "Abu Dhabi",
    "asset": "assets/images/abu_dhabi.png",
    "cities": abuDahbiCities,
  },
  {
    "value": "Sharjah",
    "asset": "assets/images/sharjah.png",
    "cities": sharjahCities,
  },
  {
    "value": "Umm al-Quwain",
    "asset": "assets/images/umm_al_quwain.png",
    "cities": "Umm al-Quwain",
  },
  {
    "value": "Fujairah",
    "asset": "assets/images/fujairah.png",
    "cities": "Fujairah",
  },
  {
    "value": "Ajman",
    "asset": "assets/images/ajman.png",
    "cities": "Ajman",
  },
];
