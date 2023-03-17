// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:roomy_finder/classes/place_autocomplete.dart';
import 'package:roomy_finder/controllers/app_controller.dart';

import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/find_roommate_match.dart';

class _SearchRoommateMatchController extends LoadingController {
  final _aboutFormKey = GlobalKey<FormState>();
  final _socialPreferebceFormKey = GlobalKey<FormState>();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();

  _SearchRoommateMatchController();

  final _cityController = TextEditingController();
  final _locationController = TextEditingController();
  final _movingDateController =
      TextEditingController(text: "Please choose choose a date");

  late final PageController _pageController;
  final _pageIndex = 0.obs;

  final locations = <String>[].obs;

  final type = "Studio".obs;
  final gender = "Male".obs;

  // Information
  final images = <XFile>[].obs;
  final videos = <XFile>[].obs;
  final interests = <String>[].obs;
  final languages = <String>["English"].obs;

// Google place search tools
  CameraPosition? cameraPosition;
  PlaceAutoCompletePredicate? autoCompletePredicate;

  PhoneNumber agentPhoneNumber = PhoneNumber();

  final information = <String, Object?>{
    "type": "Studio",
    "rentType": "Monthly",
    "budget": "",
    "description": "",
    "movingDate": "",
  }.obs;

  final aboutYou = <String, Object?>{
    "gender": "Male",
    "astrologicalSign": "ARIES",
    "age": "",
    "occupation": "Student",
  }.obs;

  final address = <String, String>{
    "country": "",
    "city": "",
    "location": "",
  }.obs;

  final socialPreferences = {
    "numberOfPeople": "1 to 5",
    "grouping": "Single",
    "gender": "Male",
    "nationality": "Arabs",
    "smoking": false,
    "cooking": false,
    "drinking": false,
    "swimming": false,
    "friendParty": false,
    "gym": false,
    "wifi": false,
    "tv": false,
  }.obs;

  final cardDetails = {
    "cardNumber": "",
    "expiryDate": "",
    "cardHolderName": "",
    "cvvCode": "",
  }.obs;

  String country = "United Arab Emirates";

  @override
  void onInit() {
    _pageController = PageController();

    super.onInit();
  }

  @override
  void onClose() {
    _pageController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _movingDateController.dispose();
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

  Future<void> pickMovingDate() async {
    final currentValue = DateTime.tryParse("${information['movingDate']}");
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 100)),
    );

    if (date != null) {
      information["movingDate"] = date.toIso8601String();

      _movingDateController.text = Jiffy(date).yMEd;
    }
  }
}

class SearchRoommateMatchScreen extends StatelessWidget {
  const SearchRoommateMatchScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_SearchRoommateMatchController());
    return Obx(() {
      return WillPopScope(
        onWillPop: () async {
          if (controller._pageIndex.value != 0) {
            controller._moveToPreviousPage();
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Register Roommate Match"),
          ),
          body: Padding(
            padding: const EdgeInsets.only(right: 5, left: 5, bottom: 50),
            child: PageView(
              controller: controller._pageController,
              onPageChanged: (index) {
                controller._pageIndex(index);
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Property type
                SingleChildScrollView(
                  child: Column(
                    children: ["Studio", "Appartment", "House"].map((e) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: RadioListTile<String>(
                          value: e,
                          groupValue: controller.information["type"] as String,
                          onChanged: (value) {
                            if (value != null) {
                              controller.information["type"] = value;
                            }
                          },
                          title: Text(e),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // About you
                SingleChildScrollView(
                  child: Form(
                    key: controller._aboutFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Age

                        Text('age'.tr),
                        TextFormField(
                          initialValue: controller.aboutYou["age"] as String,
                          enabled: controller.isLoading.isFalse,
                          decoration: InputDecoration(hintText: 'age'.tr),
                          onChanged: (value) {
                            controller.aboutYou["age"] = value;
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'thisFieldIsRequired'.tr;
                            }
                            final numValue = int.tryParse(value);

                            if (numValue == null || numValue < 1) {
                              return 'invalidPropertyAdQuantityMessage'.tr;
                            }
                            if (numValue > 80) {
                              return 'The maximum age is 80'.tr;
                            }
                            return null;
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*'))
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Occupation
                        Text('occupation'.tr),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: 'occupation'.tr,
                          ),
                          value: controller.aboutYou["occupation"].toString(),
                          items: ["Student", "Professional", "Other"]
                              .map((e) => DropdownMenuItem<String>(
                                  value: e, child: Text(e)))
                              .toList(),
                          onChanged: controller.isLoading.isTrue
                              ? null
                              : (val) {
                                  if (val != null) {
                                    controller.aboutYou["occupation"] = val;
                                  }
                                },
                        ),
                        const SizedBox(height: 20),

                        Text('Languages you speak'.tr),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          // padding: const EdgeInsets.all(10),
                          child: Wrap(
                            children: [
                              ...controller.languages.map((e) {
                                return Container(
                                    margin: const EdgeInsets.all(5),
                                    padding: const EdgeInsets.only(left: 15),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(e),
                                        SizedBox(
                                          height: 35,
                                          child: IconButton(
                                            onPressed: () {
                                              controller.languages.remove(e);
                                            },
                                            icon: const Icon(
                                              Icons.cancel,
                                              color: Colors.red,
                                            ),
                                          ),
                                        )
                                      ],
                                    ));
                              }).toList(),
                              IconButton(
                                onPressed: () async {
                                  FocusScope.of(context).unfocus();
                                  final result = await filterListData(
                                    allLanguages,
                                    excluded: controller.languages,
                                  );
                                  controller.languages.addAll(result);
                                },
                                icon: const Icon(Icons.add_circle),
                              )
                            ],
                          ),
                        ),

                        // TextFormField(
                        //   enabled: controller.isLoading.isFalse,
                        //   decoration: InputDecoration(
                        //     hintText: 'Language'.tr,
                        //   ),
                        // ),
                        const SizedBox(height: 10),
                        // Container(
                        //   margin: const EdgeInsets.symmetric(vertical: 5),
                        //   // padding: const EdgeInsets.all(10),
                        //   child: SingleChildScrollView(
                        //     scrollDirection: Axis.horizontal,
                        //     child: Row(
                        //       children: [
                        //         ...controller.languages.map((e) {
                        //           return Container(
                        //               margin: const EdgeInsets.symmetric(
                        //                   horizontal: 5),
                        //               padding: const EdgeInsets.only(left: 15),
                        //               decoration: BoxDecoration(
                        //                 border: Border.all(color: Colors.grey),
                        //                 borderRadius: BorderRadius.circular(25),
                        //               ),
                        //               child: Row(
                        //                 mainAxisSize: MainAxisSize.min,
                        //                 children: [
                        //                   Text(e),
                        //                   IconButton(
                        //                     onPressed: () {
                        //                       controller.languages.remove(e);
                        //                     },
                        //                     icon: const Icon(
                        //                       Icons.cancel,
                        //                       color: Colors.red,
                        //                     ),
                        //                   )
                        //                 ],
                        //               ));
                        //         }).toList(),
                        //         IconButton(
                        //           onPressed: controller.addLangues,
                        //           icon: const Icon(Icons.add_circle),
                        //         )
                        //       ],
                        //     ),
                        //   ),
                        // ),

                        Text('gender'.tr),
                        DropdownButtonFormField<String>(
                          value: controller.aboutYou["gender"].toString(),
                          items: ["Male", "Female"]
                              .map((e) => DropdownMenuItem<String>(
                                  value: e, child: Text(e)))
                              .toList(),
                          onChanged: controller.isLoading.isTrue
                              ? null
                              : (val) {
                                  if (val != null) {
                                    controller.aboutYou["gender"] = val;
                                    controller.gender(val);
                                  }
                                },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller._minBudgetController,
                                decoration: InputDecoration(
                                  labelText: 'Min'.tr,
                                  suffixText: AppController
                                      .instance.country.value.currencyCode,
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
                                  suffixText: AppController
                                      .instance.country.value.currencyCode,
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

                        // TextFormField(
                        //   initialValue:
                        //       controller.information["budget"] as String,
                        //   enabled: controller.isLoading.isFalse,
                        //   decoration: InputDecoration(
                        //     hintText: 'budget'.tr,
                        //     suffixText : AppController.instance.country.value.currencyCode,
                        //   ),
                        //   onChanged: (value) =>
                        //       controller.information["budget"] = value,
                        //   validator: (value) {
                        //     if (value == null || value.isEmpty) {
                        //       return 'thisFieldIsRequired'.tr;
                        //     }
                        //     final numValue = int.tryParse(value);

                        //     if (numValue == null || numValue < 0) {
                        //       return 'invalidRoommateAdBudgetMessage'.tr;
                        //     }
                        //     return null;
                        //   },
                        //   keyboardType: TextInputType.number,
                        //   inputFormatters: [
                        //     FilteringTextInputFormatter.allow(priceRegex)
                        //   ],
                        // ),
                        const SizedBox(height: 10),

                        // Rent type
                        Text('rentType'.tr),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            hintText: 'Rent type',
                          ),
                          value: controller.information["rentType"] as String,
                          items: ["Monthly", "Weekly", "Daily"]
                              .map((e) => DropdownMenuItem<String>(
                                  value: e, child: Text(e)))
                              .toList(),
                          onChanged: controller.isLoading.isTrue
                              ? null
                              : (val) {
                                  if (val != null) {
                                    controller.information["rentType"] = val;
                                  }
                                },
                        ),
                        const SizedBox(height: 10),
                        // Budget

                        Text('Moving Date'.tr),
                        TextFormField(
                          readOnly: true,
                          controller: controller._movingDateController,
                          onChanged: (_) {},
                          enabled: controller.isLoading.isFalse,
                          decoration: InputDecoration(
                            hintText: 'Please choose moving a date'.tr,
                            suffixIcon: const Icon(Icons.calendar_month),
                          ),
                          validator: (value) {
                            final date = DateTime.tryParse(
                                "${controller.information["movingDate"]}");
                            if (date == null) {
                              return 'thisFieldIsRequired'.tr;
                            }
                            return null;
                          },
                          onTap: controller.pickMovingDate,
                        ),
                        const SizedBox(height: 10),

                        Text('Interests'.tr),
                        TextFormField(
                          enabled: controller.isLoading.isFalse,
                          decoration: InputDecoration(
                            hintText: 'interest'.tr,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // astrologicalSign
                        Text('astrologicalSign'.tr),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            hintText: 'astrologicalSign'.tr,
                          ),
                          value: controller.aboutYou["astrologicalSign"]
                              .toString(),
                          items: astrologicalSigns
                              .map((e) => DropdownMenuItem<String>(
                                  value: e, child: Text(e)))
                              .toList(),
                          onChanged: controller.isLoading.isTrue
                              ? null
                              : (val) {
                                  if (val != null) {
                                    controller.aboutYou["astrologicalSign"] =
                                        val;
                                  }
                                },
                        ),
                        const SizedBox(height: 10),

                        Text('Interest'.tr),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          // padding: const EdgeInsets.all(10),
                          child: Wrap(
                            children: [
                              ...controller.interests.map((e) {
                                return Container(
                                    margin: const EdgeInsets.all(5),
                                    padding: const EdgeInsets.only(left: 15),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(e),
                                        SizedBox(
                                          height: 35,
                                          child: IconButton(
                                            onPressed: () {
                                              controller.interests.remove(e);
                                            },
                                            icon: const Icon(
                                              Icons.cancel,
                                              color: Colors.red,
                                            ),
                                          ),
                                        )
                                      ],
                                    ));
                              }).toList(),
                              IconButton(
                                onPressed: () async {
                                  FocusScope.of(context).unfocus();
                                  final result = await filterListData(
                                    allInterests,
                                    excluded: controller.interests,
                                  );
                                  controller.interests.addAll(result);
                                },
                                icon: const Icon(Icons.add_circle),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Preference preferences
                SingleChildScrollView(
                  child: Form(
                    key: controller._socialPreferebceFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // City
                        Text('city'.tr),
                        TypeAheadFormField<String>(
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: controller._cityController,
                            decoration: InputDecoration(
                              hintText: 'city'.tr,
                            ),
                          ),
                          itemBuilder: (context, itemData) {
                            return ListTile(
                              dense: true,
                              title: Text(itemData),
                            );
                          },
                          onSuggestionSelected: (suggestion) {
                            controller.address["city"] = suggestion;
                            controller._cityController.text = suggestion;
                          },
                          suggestionsCallback: (pattern) {
                            return citiesFromCurrentCountry.where(
                              (e) {
                                final lowerPattern =
                                    pattern.toLowerCase().trim();
                                final lowerSearch = e.toLowerCase().trim();
                                return lowerSearch.contains(lowerPattern) ||
                                    lowerSearch == lowerPattern;
                              },
                            );
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'thisFieldIsRequired'.tr;
                            }
                            return null;
                          },
                          onSaved: (newValue) {
                            if (newValue != null) {
                              controller.address["city"] = newValue;
                              controller._cityController.text = newValue;
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        // Location
                        Text('location'.tr),
                        TypeAheadField<String>(
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: controller._locationController,
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
                            controller.address["location"] = suggestion;
                            controller._locationController.text = suggestion;
                          },
                          suggestionsCallback: (pattern) {
                            return getLocationsFromCity(
                                    controller.address["city"].toString())
                                .where(
                              (e) => e
                                  .toLowerCase()
                                  .toLowerCase()
                                  .contains(pattern),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        // Grouping
                        Text('Single/Couple'.tr),
                        DropdownButtonFormField<String>(
                          value: controller.socialPreferences["grouping"]
                              as String,
                          items: ["Single", "Couple"]
                              .map((e) => DropdownMenuItem<String>(
                                  value: e, child: Text(e)))
                              .toList(),
                          onChanged: controller.isLoading.isTrue
                              ? null
                              : (val) {
                                  if (val != null) {
                                    controller.socialPreferences["grouping"] =
                                        val;
                                  }
                                },
                        ),
                        const SizedBox(height: 20),
                        for (final item in [
                          "smoking",
                          "cooking",
                          "drinking",
                          "swimming",
                          "friendParty",
                          "gym",
                          "wifi",
                          "tv"
                        ])
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                width: 1,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.tr,
                                    style: const TextStyle(fontSize: 16)),
                                FlutterSwitch(
                                  value: controller.socialPreferences[item]
                                      as bool,
                                  onToggle: (value) {
                                    controller.socialPreferences[item] = value;
                                  },
                                )
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),
                        // Description
                        Text('description'.tr),
                        TextFormField(
                          initialValue:
                              controller.information["description"] as String,
                          enabled: controller.isLoading.isFalse,
                          decoration: InputDecoration(
                            hintText: 'description'.tr,
                          ),
                          onChanged: (value) =>
                              controller.information["description"] = value,
                          // validator: (value) {
                          //   if (value == null || value.trim().isEmpty) {
                          //     return 'thisFieldIsRequired'.tr;
                          //   }
                          //   return null;
                          // },
                          minLines: 2,
                          maxLines: 5,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Builder(builder: (context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    color: const Color.fromRGBO(255, 123, 77, 1),
                    value: (controller._pageIndex.value + 1) / 3,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // const SizedBox(width: 10),
                      TextButton(
                        onPressed: controller.isLoading.isTrue
                            ? null
                            : () {
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
                        onPressed: controller.isLoading.isTrue
                            ? null
                            : () {
                                switch (controller._pageIndex.value) {
                                  case 0:
                                    controller._moveToNextPage();
                                    break;
                                  case 1:
                                    final isValid = controller
                                        ._aboutFormKey.currentState
                                        ?.validate();

                                    if (isValid != true) return;

                                    controller._moveToNextPage();
                                    break;
                                  case 2:
                                    final isValid = controller
                                        ._socialPreferebceFormKey.currentState
                                        ?.validate();

                                    if (isValid != true) return;
                                    Get.to(() => FindRoommateMatchsScreen(
                                          type: controller.type.value,
                                          gender: controller.gender.value,
                                          budget: {
                                            "min": controller
                                                ._minBudgetController.text,
                                            "max": controller
                                                ._maxBudgetController.text,
                                          },
                                          locations: [
                                            "${controller.address["location"]}"
                                          ],
                                        ));

                                    break;
                                }
                              },
                        child: Text("next".tr),
                      ),
                      // const Icon(Icons.arrow_right),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      );
    });
  }
}

const astrologicalSigns = [
  "ARIES",
  "TAURUS",
  "GEMINI",
  "CANCER",
  "LEO",
  "VIRGO",
  "LIBRA",
  "SCORPIO",
  "SAGITTARIUS",
  "CAPRICORN",
  "AQUARIUS",
  "PISCES",
];

const allInterests = [
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

const allLanguages = [
  "Arabic",
  "English",
  "French",
  "Hindi",
  "Indian",
  "Persian",
  "Russian",
  "Ukrainian",
];
