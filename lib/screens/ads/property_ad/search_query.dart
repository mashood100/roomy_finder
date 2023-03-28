import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/country.dart';
import 'package:roomy_finder/screens/ads/property_ad/find_properties.dart';

class _PropertyAdSearchQueryScreenController extends GetxController {
  _PropertyAdSearchQueryScreenController();

  final _minBudgetController = TextEditingController();
  final _locationController = TextEditingController();

  final citySortKey = "".obs;
  final rentType = "Monthly".obs;
  final city = "".obs;
  final location = "".obs;

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
          title: const Text("Find Room"),
          backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 10,
            left: 5,
            right: 5,
            bottom: 50,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card(
                //   child: Padding(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 10,
                //       vertical: 5,
                //     ),
                //     child: TextField(
                //       decoration: const InputDecoration(
                //         hintText: "Search city",
                //         border: InputBorder.none,
                //         fillColor: Colors.transparent,
                //       ),
                //       onChanged: controller.citySortKey,
                //     ),
                //   ),
                // ),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: (AppController.instance.country.value == Country.UAE
                          ? _uAECities
                          : _saudiArabiaCities)
                      .where((e) {
                    if (controller.citySortKey.trim().isEmpty) {
                      return true;
                    } else {
                      return "${e['value']}"
                          .toLowerCase()
                          .contains(controller.citySortKey.toLowerCase());
                    }
                  }).map((e) {
                    return GestureDetector(
                      onTap: () {
                        controller.city("${e['value']}");
                        controller.location('');
                        controller._locationController.clear();
                      },
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Image.asset(
                            "${e["asset"]}",
                            fit: BoxFit.fill,
                            width: double.infinity,
                            height: double.infinity,
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: TypeAheadField<String>(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: controller._locationController,
                        decoration: const InputDecoration(
                          hintText: "Search location",
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
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
                        controller._locationController.text = suggestion;
                      },
                      suggestionsCallback: (pattern) {
                        return getLocationsFromCity(controller.city.value)
                            .where(
                          (e) =>
                              e.toLowerCase().toLowerCase().contains(pattern),
                        );
                      },
                    ),
                  ),
                ),
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
                    if (controller.city.isEmpty) {
                      return showToast("please select a city");
                    }
                    if (controller.location.isNotEmpty) {
                      Get.to(
                        () => FindPropertiesAdsScreen(
                          filter: {
                            "city": controller.city.value,
                            "location": controller.location.value,
                          },
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

const _uAECities = [
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
    "value": "Ajman",
    "asset": "assets/images/ajman.png",
  },
];
const _saudiArabiaCities = [
  {
    "value": "Jeddah",
    "asset": "assets/images/jeddah.jpg",
  },
  {
    "value": "Mecca",
    "asset": "assets/images/mecca.jpg",
  },
  {
    "value": "Riyadh",
    "asset": "assets/images/riyadh.jpg",
  },
];
