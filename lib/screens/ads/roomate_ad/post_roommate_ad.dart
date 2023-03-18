// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import "package:path/path.dart" as path;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/label.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/delete_file_from_url.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/utility_screens/play_video.dart';

class _PostRoommateAdController extends LoadingController {
  final bool isPremium;
  final RoommateAd? oldData;

  _PostRoommateAdController({required this.isPremium, this.oldData});

  final _cityController = TextEditingController();
  final _locationController = TextEditingController();
  final _movingDateController =
      TextEditingController(text: "Please choose choose a date");
  final _cardFormKey = GlobalKey<FormState>();

  final _aboutFormKey = GlobalKey<FormState>();

  late final PageController _pageController;
  final _pageIndex = 0.obs;

  // Information
  final oldImages = <String>[].obs;
  final images = <XFile>[].obs;

  final oldVideos = <String>[].obs;
  final videos = <XFile>[].obs;
  final interests = <String>[].obs;
  final languages = <String>[].obs;

  PhoneNumber agentPhoneNumber = PhoneNumber();

  final information = <String, Object?>{
    "type": "Studio",
    "rentType": "Monthly",
    "budget": "",
    "description": "",
    "movingDate": "",
  }.obs;

  final aboutYou = <String, Object?>{
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
    "numberOfPeople": "1",
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

  @override
  void onInit() {
    _pageController = PageController();

    if (oldData != null) {
      oldImages.addAll(oldData!.images);
      oldVideos.addAll(oldData!.videos);

      information["type"] = oldData!.type;
      information["rentType"] = oldData!.rentType;
      information["isPremium"] = oldData!.isPremium;
      information["budget"] = oldData!.budget.toString();
      information["description"] = oldData!.description;
      information["description"] = oldData!.description;
      _movingDateController.text =
          information["movingDate"] = oldData!.movingDate.toIso8601String();

      _cityController.text =
          address["country"] = oldData!.address["country"].toString();
      _locationController.text =
          address["location"] = oldData!.address["location"].toString();

      aboutYou["astrologicalSign"] =
          oldData!.aboutYou["astrologicalSign"].toString();
      aboutYou["age"] = oldData!.aboutYou["age"].toString();
      aboutYou["occupation"] = oldData!.aboutYou["occupation"].toString();

      languages.value =
          List<String>.from(oldData!.aboutYou["languages"] as List);
      interests.value =
          List<String>.from(oldData!.aboutYou["interests"] as List);

      socialPreferences.value = oldData!.socialPreferences;
    }
    super.onInit();
  }

  @override
  void onClose() {
    _pageController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _movingDateController.dispose();
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

  Future<void> _pickPicture({bool gallery = true}) async {
    if (images.length >= 10) return;

    try {
      final ImagePicker picker = ImagePicker();

      if (gallery) {
        final data = await picker.pickMultiImage();
        final sumImages = [...images, ...data];
        images.clear();
        if (sumImages.length <= 10) {
          images.addAll(sumImages);
        } else {
          images.addAll(sumImages.sublist(0, 9));
        }
      } else {
        final image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) images.add(image);
      }
    } catch (e) {
      Get.log("$e");
      showGetSnackbar('someThingWhenWrong'.tr, severity: Severity.error);
    } finally {
      isLoading(false);
    }
  }

  Future<void> _pickVideo() async {
    if (videos.length >= 10) return;

    try {
      final ImagePicker picker = ImagePicker();

      final data = await picker.pickVideo(source: ImageSource.gallery);
      if (data != null) {
        videos.add(data);
      }
    } catch (e) {
      Get.log("$e");
      showGetSnackbar('someThingWhenWrong'.tr, severity: Severity.error);
    } finally {
      isLoading(false);
    }
  }

  void _playVideo(String source, bool isAsset) {
    Get.to(() => PlayVideoScreen(source: source, isAsset: isAsset));
  }

  Future<void> saveAd() async {
    isLoading(true);

    List<String> imagesUrls = [];
    List<String> videosUrls = [];
    try {
      aboutYou["languages"] = languages;
      aboutYou["interests"] = interests;
      address["country"] = AppController.me.country;

      final data = {
        ...information,
        "isPremium": isPremium,
        "address": address,
        "aboutYou": aboutYou,
        "socialPreferences": socialPreferences,
      };

      final imagesTaskFuture = images.map((e) async {
        final imgRef = FirebaseStorage.instance
            .ref()
            .child('images')
            .child('/${const Uuid().v4()}${path.extension(e.path)}');

        final uploadTask = imgRef.putData(await File(e.path).readAsBytes());

        final imageUrl = await (await uploadTask).ref.getDownloadURL();

        return imageUrl;
      }).toList();

      imagesUrls = await Future.wait(imagesTaskFuture);

      final videoTaskFuture = videos.map((e) async {
        final imgRef = FirebaseStorage.instance
            .ref()
            .child('videos')
            .child('/${const Uuid().v4()}${path.extension(e.path)}');

        final uploadTask = imgRef.putData(await File(e.path).readAsBytes());

        final videoUrl = await (await uploadTask).ref.getDownloadURL();

        return videoUrl;
      }).toList();

      videosUrls = await Future.wait(videoTaskFuture);

      data["images"] = [...imagesUrls, ...oldImages];
      data["videos"] = videosUrls;

      if (oldData == null) {
        final res =
            await ApiService.getDio.post("/ads/roommate-ad", data: data);

        if (res.statusCode != 200) {
          deleteManyFilesFromUrl(imagesUrls);
          deleteManyFilesFromUrl(videosUrls);
        }

        switch (res.statusCode) {
          case 200:
            isLoading(false);
            await showConfirmDialog(
              "Ad posted successfully. "
              "You just made another advertisement journey",
              isAlert: true,
            );
            Get.offNamedUntil(
              "/my-roommate-ads",
              ModalRoute.withName('/home'),
            );
            break;
          case 500:
            showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
            break;
          default:
        }
      } else {
        final res = await ApiService.getDio
            .put("/ads/roommate-ad/${oldData?.id}", data: data);

        if (res.statusCode != 200) {
          deleteManyFilesFromUrl(imagesUrls);
          deleteManyFilesFromUrl(videosUrls);
        }

        switch (res.statusCode) {
          case 200:
            isLoading(false);
            await showConfirmDialog("Ad updated successfully.", isAlert: true);

            deleteManyFilesFromUrl(
              oldData!.images.where((e) => !imagesUrls.contains(e)).toList(),
            );
            Get.offNamedUntil(
              "/my-roommate-ads",
              ModalRoute.withName('/home'),
            );
            break;
          case 500:
            showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
            break;
          default:
            showToast("someThingWentWrong".tr);
        }
      }
    } catch (e) {
      Get.log("$e");
      deleteManyFilesFromUrl(imagesUrls);
      deleteManyFilesFromUrl(videosUrls);
    } finally {
      isLoading(false);
    }
  }

  Future<void> addLangues() async {
    final lang = await showModalBottomSheet<String>(
      context: Get.context!,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            children: allLanguages
                .where((e) => !languages.contains(e))
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

    if (lang == null) return;

    languages.add(lang);
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

class PostRoomateAdScreen extends StatelessWidget {
  const PostRoomateAdScreen({super.key, required this.isPremium, this.oldData});

  final bool isPremium;
  final RoommateAd? oldData;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_PostRoommateAdController(
      isPremium: isPremium,
      oldData: oldData,
    ));
    return WillPopScope(
      onWillPop: () async {
        if (controller._pageIndex.value != 0) {
          controller._moveToPreviousPage();
          return false;
        }
        return true;
      },
      child: Obx(() {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              oldData != null
                  ? isPremium
                      ? "Update Premium Ad"
                      : "Update Roommate Match"
                  : isPremium
                      ? "Post Premium Roommate Ad"
                      : "Post Roommate Match",
            ),
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 5,
                  right: 5,
                  top: 5,
                  bottom: 60,
                ),
                child: PageView(
                  controller: controller._pageController,
                  onPageChanged: (index) => controller._pageIndex(index),
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
                              groupValue:
                                  controller.information["type"] as String,
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

                    // About
                    SingleChildScrollView(
                      child: Form(
                        key: controller._aboutFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            // Rent type
                            Text('rentType'.tr),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                hintText: 'Rent type',
                              ),
                              value:
                                  controller.information["rentType"] as String,
                              items: ["Monthly", "Weekly", "Daily"]
                                  .map((e) => DropdownMenuItem<String>(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: controller.isLoading.isTrue
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        controller.information["rentType"] =
                                            val;
                                      }
                                    },
                            ),
                            const SizedBox(height: 10),
                            // Budget
                            Text('budget'.tr),
                            TextFormField(
                              initialValue:
                                  controller.information["budget"] as String,
                              enabled: controller.isLoading.isFalse,
                              decoration: InputDecoration(
                                hintText: 'budget'.tr,
                                suffixText: AppController
                                    .instance.country.value.currencyCode,
                              ),
                              onChanged: (value) =>
                                  controller.information["budget"] = value,
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
                            const SizedBox(height: 10),

                            Text('Moving Date'.tr),
                            TextFormField(
                              readOnly: true,
                              controller: controller._movingDateController,
                              onChanged: (_) {},
                              enabled: controller.isLoading.isFalse,
                              decoration: InputDecoration(
                                hintText: 'Please choose a moving date'.tr,
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
                            // City
                            Text('city'.tr),
                            TypeAheadFormField<String>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: controller._cityController,
                                decoration: InputDecoration(
                                  hintText:
                                      AppController.instance.country.value.isUAE
                                          ? 'Example : Dubai'
                                          : "Example : Riyadh",
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
                                controller._locationController.text =
                                    suggestion;
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

                            // Description
                            Text('description'.tr),
                            TextFormField(
                              initialValue: controller
                                  .information["description"] as String,
                              enabled: controller.isLoading.isFalse,
                              decoration: InputDecoration(
                                hintText: 'Add your add description here'.tr,
                              ),
                              onChanged: (value) =>
                                  controller.information["description"] = value,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'thisFieldIsRequired'.tr;
                                }
                                return null;
                              },
                              minLines: 2,
                              maxLines: 5,
                              maxLength: 500,
                            ),

                            // GetBuilder<_PostRoommateAdController>(
                            //     builder: (controller) {
                            //   return Row(
                            //     children: [
                            //       if (controller.cameraPosition == null)
                            //         Expanded(
                            //           child: Padding(
                            //             padding: const EdgeInsets.symmetric(
                            //                 horizontal: 5),
                            //             child: ElevatedButton.icon(
                            //               style: ElevatedButton.styleFrom(
                            //                 backgroundColor: Colors.blue,
                            //               ),
                            //               onPressed: () async {
                            //                 final pos = await Get.to(
                            //                   () => FlutterGoogleMapScreen(
                            //                     initialPosition:
                            //                         controller.cameraPosition,
                            //                   ),
                            //                 );

                            //                 if (pos is CameraPosition) {
                            //                   controller.cameraPosition = pos;
                            //                   controller.update();
                            //                 }
                            //               },
                            //               icon: const Icon(
                            //                 Icons.map,
                            //                 color: Colors.white,
                            //               ),
                            //               label: const Text('Add map location',
                            //                   style: TextStyle(
                            //                     color: Colors.white,
                            //                   )),
                            //             ),
                            //           ),
                            //         ),
                            //       if (controller.cameraPosition != null)
                            //         Expanded(
                            //           child: Padding(
                            //             padding: const EdgeInsets.symmetric(
                            //                 horizontal: 5),
                            //             child: ElevatedButton.icon(
                            //               style: ElevatedButton.styleFrom(
                            //                 backgroundColor: Colors.red,
                            //               ),
                            //               onPressed: () async {
                            //                 controller.cameraPosition = null;
                            //                 controller.update();
                            //               },
                            //               icon: const Icon(
                            //                 Icons.map,
                            //                 color: Colors.white,
                            //               ),
                            //               label: const Text(
                            //                 "Remove map",
                            //                 style: TextStyle(
                            //                   color: Colors.white,
                            //                 ),
                            //               ),
                            //             ),
                            //           ),
                            //         ),
                            //       if (controller.cameraPosition != null)
                            //         Expanded(
                            //           child: Padding(
                            //             padding: const EdgeInsets.symmetric(
                            //                 horizontal: 5),
                            //             child: ElevatedButton.icon(
                            //               style: ElevatedButton.styleFrom(
                            //                 backgroundColor: Colors.blue,
                            //               ),
                            //               onPressed: () {
                            //                 Get.to(() => FlutterGoogleMapScreen(
                            //                       initialPosition:
                            //                           controller.cameraPosition,
                            //                     ));
                            //               },
                            //               icon: const Icon(
                            //                 Icons.visibility,
                            //                 color: Colors.white,
                            //               ),
                            //               label: GetBuilder<
                            //                       _PostRoommateAdController>(
                            //                   builder: (controller) {
                            //                 return const Text("View location",
                            //                     style: TextStyle(
                            //                       color: Colors.white,
                            //                     ));
                            //               }),
                            //             ),
                            //           ),
                            //         ),
                            //     ],
                            //   );
                            // }),
                            // const SizedBox(height: 10),

                            /// Address
                            Center(child: Text("aboutYou".tr)),
                            const SizedBox(height: 20),

                            /// About you
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
                                        controller
                                            .aboutYou["astrologicalSign"] = val;
                                      }
                                    },
                            ),
                            const SizedBox(height: 20),

                            // Age
                            Text('age'.tr),
                            TextFormField(
                              initialValue:
                                  controller.aboutYou["age"] as String,
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
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*'))
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Occupation
                            Text('occupation'.tr),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                hintText: 'occupation'.tr,
                              ),
                              value:
                                  controller.aboutYou["occupation"].toString(),
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
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ...controller.languages.map((e) {
                                      return Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5),
                                          padding:
                                              const EdgeInsets.only(left: 15),
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.grey),
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(e),
                                              SizedBox(
                                                height: 35,
                                                child: IconButton(
                                                  onPressed: () {
                                                    controller.languages
                                                        .remove(e);
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
                            ),

                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),

                    // Images/Videos

                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              "Images and videos".tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (controller.images.isEmpty &&
                              controller.oldImages.isEmpty &&
                              controller.videos.isEmpty &&
                              controller.oldVideos.isEmpty)
                            Card(
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(10),
                                height: 150,
                                child: const Text(
                                  "Please upload your photos",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          if (controller.images.length +
                                  controller.oldImages.length !=
                              0)
                            GridView.count(
                              crossAxisCount: Get.width > 370 ? 4 : 2,
                              crossAxisSpacing: 10,
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              children: [
                                ...controller.oldImages.map((e) {
                                  return {
                                    "onTap": () =>
                                        controller.oldImages.remove(e),
                                    "imageUrl": e,
                                    "isFile": false,
                                    "onViewImage": () {
                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        context: Get.context!,
                                        builder: (context) {
                                          return SafeArea(
                                            child: CachedNetworkImage(
                                              imageUrl: e,
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  };
                                }),
                                ...controller.images.map((e) {
                                  return {
                                    "onTap": () => controller.images.remove(e),
                                    "imageUrl": e.path,
                                    "isFile": true,
                                    "onViewImage": () {
                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        context: Get.context!,
                                        builder: (context) {
                                          return SafeArea(
                                            child: Image.file(File(e.path)),
                                          );
                                        },
                                      );
                                    }
                                  };
                                }),
                              ]
                                  .map(
                                    (e) => Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        GestureDetector(
                                          onTap: e["onViewImage"] as void
                                              Function()?,
                                          child: Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey,
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            margin: const EdgeInsets.all(5),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              child:
                                                  Builder(builder: (context) {
                                                if (e["isFile"] == true) {
                                                  return Image.file(
                                                    File("${e["imageUrl"]}"),
                                                    fit: BoxFit.cover,
                                                  );
                                                }
                                                return CachedNetworkImage(
                                                  imageUrl: "${e["imageUrl"]}",
                                                  fit: BoxFit.cover,
                                                );
                                              }),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: e["onTap"] as void Function()?,
                                          child: const Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          if (controller.videos.length +
                                  controller.oldVideos.length !=
                              0)
                            GridView.count(
                              crossAxisCount: Get.width > 370 ? 4 : 2,
                              crossAxisSpacing: 10,
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              children: [
                                ...controller.oldVideos.map((e) {
                                  return {
                                    "onTap": () =>
                                        controller.oldVideos.remove(e),
                                    "onPlayVideo": () {
                                      controller._playVideo(e, false);
                                    },
                                    "url": e,
                                    "isFile": false,
                                  };
                                }),
                                ...controller.videos.map((e) {
                                  return {
                                    "onTap": () => controller.videos.remove(e),
                                    "onPlayVideo": () {
                                      controller._playVideo(e.path, false);
                                    },
                                    "url": e.path,
                                    "isFile": true,
                                  };
                                }),
                              ]
                                  .map(
                                    (e) => Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          margin: const EdgeInsets.all(5),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            child: Builder(builder: (context) {
                                              if (e["isFile"] == true) {
                                                return FutureBuilder(
                                                  builder: (ctx, asp) {
                                                    if (asp.hasData) {
                                                      return Image.memory(
                                                        asp.data!,
                                                        fit: BoxFit.cover,
                                                        alignment:
                                                            Alignment.center,
                                                      );
                                                    }
                                                    return Container();
                                                  },
                                                  future: VideoThumbnail
                                                      .thumbnailData(
                                                    video: "${e["url"]}",
                                                  ),
                                                );
                                              }
                                              return FutureBuilder(
                                                builder: (ctx, asp) {
                                                  if (asp.hasData) {
                                                    return Image.file(
                                                      File("${asp.data}"),
                                                      fit: BoxFit.cover,
                                                      alignment:
                                                          Alignment.center,
                                                    );
                                                  }
                                                  return Container();
                                                },
                                                future: VideoThumbnail
                                                    .thumbnailFile(
                                                  video: "${e["url"]}",
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: e["onPlayVideo"] as void
                                              Function()?,
                                          child: const Icon(
                                            Icons.play_arrow,
                                            size: 40,
                                          ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: GestureDetector(
                                            onTap:
                                                e["onTap"] as void Function()?,
                                            child: const Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 35,
                                  child: ElevatedButton.icon(
                                    onPressed: controller.images.length >= 10
                                        ? null
                                        : () => controller._pickPicture(),
                                    icon: const Icon(Icons.image),
                                    label: Text("Images".tr),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: SizedBox(
                                  height: 35,
                                  child: ElevatedButton.icon(
                                    onPressed: controller.images.length >= 10
                                        ? null
                                        : () => controller._pickPicture(
                                            gallery: false),
                                    icon: const Icon(Icons.camera),
                                    label: Text("camera".tr),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: SizedBox(
                                  height: 35,
                                  child: ElevatedButton.icon(
                                    onPressed: controller.images.length >= 10
                                        ? null
                                        : controller._pickVideo,
                                    icon: const Icon(Icons.video_camera_back),
                                    label: Text("Videos".tr),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),

                    // Preference preferences
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPremium) ...[
                            const SizedBox(height: 10),

                            // People Count
                            Text('numberOfPeople'.tr),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                hintText: 'numberOfPeople'.tr,
                                
                              ),
                              value:
                                  controller.socialPreferences["numberOfPeople"]
                                      as String?,
                              items: ["1", "2"]
                                  .map((e) => DropdownMenuItem<String>(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: controller.isLoading.isTrue
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        controller.socialPreferences[
                                            "numberOfPeople"] = val;
                                      }
                                    },
                            ),
                          ],
                          const SizedBox(height: 20),
                          // Nationalities
                          Text('nationality'.tr),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              hintText: 'nationality'.tr,
                            ),
                            value: controller.socialPreferences["nationality"]
                                as String,
                            items: [
                              "Arabs",
                              "Pakistani",
                              "Indian",
                              "European",
                              "Filipinos",
                              "African",
                              "Russian",
                              "Mix",
                            ]
                                .map((e) => DropdownMenuItem<String>(
                                    value: e, child: Text(e)))
                                .toList(),
                            onChanged: controller.isLoading.isTrue
                                ? null
                                : (val) {
                                    if (val != null) {
                                      controller.socialPreferences[
                                          "nationality"] = val;
                                    }
                                  },
                          ),
                          const SizedBox(height: 20),
                          // Gender
                          Text('gender'.tr),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              hintText: 'gender'.tr,
                             
                            ),
                            value: controller.socialPreferences["gender"]
                                as String,
                            items: ["Male", "Female", "Mix"]
                                .map((e) => DropdownMenuItem<String>(
                                    value: e, child: Text(e)))
                                .toList(),
                            onChanged: controller.isLoading.isTrue
                                ? null
                                : (val) {
                                    if (val != null) {
                                      controller.socialPreferences["gender"] =
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item.tr,
                                      style: const TextStyle(fontSize: 16)),
                                  FlutterSwitch(
                                    value: controller.socialPreferences[item]
                                        as bool,
                                    onToggle: (value) {
                                      controller.socialPreferences[item] =
                                          value;
                                    },
                                  )
                                ],
                              ),
                            ),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),

                    //  Present payment
                    SingleChildScrollView(
                      child: Column(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset("assets/images/premium.png"),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          child: Text(
                            "Pay 200 AED to publish premium roommate AD",
                            style: TextStyle(fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]),
                    ),

                    //  Make payment
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Payment details",
                            style: TextStyle(fontSize: 18),
                          ),
                          const Label(label: "Ad fee", value: '200 AED'),
                          const Label(label: "VAT", value: '5%'),
                          const Label(label: "Admin fee", value: '3%'),
                          const Label(label: "Total", value: 'AED xxx'),
                          CreditCardForm(
                            formKey: controller._cardFormKey,
                            cardNumber: controller.cardDetails["cardNumber"]!,
                            expiryDate: controller.cardDetails["expiryDate"]!,
                            cardHolderName:
                                controller.cardDetails["cardHolderName"]!,
                            cvvCode: controller.cardDetails["cvvCode"]!,
                            onCreditCardModelChange: (card) {
                              controller.cardDetails["cardNumber"] =
                                  card.cardNumber;
                              controller.cardDetails["cvvCode"] = card.cvvCode;
                              controller.cardDetails["expiryDate"] =
                                  card.expiryDate;
                              controller.cardDetails["cardHolderName"] =
                                  card.cardHolderName;
                            },
                            themeColor: Colors.purple,
                            textColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                final isValid = controller
                                    ._cardFormKey.currentState
                                    ?.validate();

                                if (isValid == true) {
                                  controller.saveAd();
                                }
                              },
                              child: const Text("Pay to publish"),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.isLoading.isTrue) const LinearProgressIndicator(),
            ],
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
                    value: (controller._pageIndex.value + 1) / 4,
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

                                    if (controller.languages.isEmpty) {
                                      showGetSnackbar(
                                        "You need to chose atleast one langue",
                                        severity: Severity.error,
                                      );
                                      return;
                                    }

                                    controller._moveToNextPage();

                                    break;
                                  case 2:
                                    if (controller.images.isEmpty &&
                                        controller.oldImages.isEmpty) {
                                      showGetSnackbar(
                                        "You need atleast one image",
                                        severity: Severity.error,
                                      );
                                      return;
                                    }
                                    controller._moveToNextPage();
                                    break;
                                  case 3:
                                    // if (isPremium) {
                                    //   controller._moveToNextPage();
                                    // } else {
                                    // }
                                    controller.saveAd();
                                    break;
                                  case 4:
                                    controller._moveToNextPage();
                                    break;
                                  case 5:
                                    // controller.saveAd();
                                    break;

                                  default:
                                }
                              },
                        child: controller._pageIndex.value == 3
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
      }),
    );
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
