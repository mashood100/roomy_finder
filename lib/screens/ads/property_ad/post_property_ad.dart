import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/place_autocomplete.dart';
import 'package:roomy_finder/components/alert.dart';
import 'package:roomy_finder/components/phone_input.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/delete_file_from_url.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/utility_screens/play_video.dart';
import 'package:uuid/uuid.dart';
import "package:path/path.dart" as path;
import 'package:video_thumbnail/video_thumbnail.dart';

class _PostPropertyAdController extends LoadingController {
  // Input controller
  final _informationFormKey = GlobalKey<FormState>();
  final _agentBrokerFormKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();

  final _cityController = TextEditingController();
  final _locationController = TextEditingController();

  late final PageController _pageController;
  final _pageIndex = 0.obs;
  final needsPhotograph = false.obs;

  final PropertyAd? oldData;
  _PostPropertyAdController({this.oldData});

  // Information
  final oldImages = <String>[].obs;
  final images = <XFile>[].obs;

  final oldVideos = <String>[].obs;
  final videos = <XFile>[].obs;

  final amenties = <String>[].obs;

  PhoneNumber agentPhoneNumber = PhoneNumber();
  CameraPosition? cameraPosition;
  PlaceAutoCompletePredicate? autoCompletePredicate;

  final information = <String, Object?>{
    "type": "Bed",
    "quantity": "",
    "preferedRentType": "Monthly",
    "monthlyPrice": "",
    "weeklyPrice": "",
    "dailyPrice": "",
    "deposit": false,
    "depositPrice": null,
    "posterType": "Landlord",
    "description": "",
  }.obs;

  final address = <String, String>{
    "city": "",
    "location": "",
    "buildingNane": "",
    "floorNumber": "",
  }.obs;

  final socialPreferences = {
    "numberOfPeople": "1 to 5",
    "grouping": "Single",
    "gender": "Male",
    "nationality": "Arabs",
    "smoking": false,
    "cooking": false,
    "drinking": false,
    "visitors": false,
  }.obs;

  final agentBrokerInformation = {
    "firstName": "",
    "lastName": "",
    "email": "",
    "phone": "",
  }.obs;

  @override
  void onInit() {
    _pageController = PageController();

    if (oldData != null) {
      oldImages.addAll(oldData!.images);
      oldVideos.addAll(oldData!.videos);

      information["type"] = oldData!.type;
      information["quantity"] = oldData!.quantity.toString();
      information["preferedRentType"] = oldData!.preferedRentType;
      information["monthlyPrice"] = oldData!.monthlyPrice.toString();
      information["weeklyPrice"] = oldData!.weeklyPrice.toString();
      information["dailyPrice"] = oldData!.dailyPrice.toString();
      information["deposit"] = oldData!.deposit;
      if (oldData!.depositPrice != null && oldData!.deposit == true) {
        information["depositPrice"] = oldData!.depositPrice.toString();
      }
      information["description"] = oldData!.description;
      information["posterType"] = oldData!.posterType;

      _cityController.text =
          address["city"] = oldData!.address["city"].toString();
      _locationController.text =
          address["location"] = oldData!.address["location"].toString();
      address["buildingName"] = oldData!.address["buildingName"].toString();
      address["floorNumber"] = oldData!.address["floorNumber"].toString();
      amenties.value = oldData!.amenties;

      if (oldData!.agentInfo != null) {
        agentBrokerInformation(oldData!.agentInfo!);
      }
      cameraPosition = oldData?.cameraPosition;
      autoCompletePredicate = oldData?.autoCompletePredicate;

      socialPreferences(oldData!.socialPreferences);
    }
    super.onInit();
  }

  @override
  void onClose() {
    _pageController.dispose();
    _cityController.dispose();
    _locationController.dispose();
    super.onClose();
  }

  void _moveToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );
  }

  void _moveToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 100),
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

  Future<void> _savePropertyAd() async {
    isLoading(true);

    List<String> imagesUrls = [];
    List<String> videosUrls = [];
    try {
      final data = {
        ...information,
        "address": address,
        "amenties": amenties,
        "agentInfo": agentBrokerInformation,
        "socialPreferences": socialPreferences,
        "cameraPosition": cameraPosition?.toMap(),
        "autoCompletePredicate": autoCompletePredicate?.toMap(),
        "needsPhotograph": needsPhotograph.value,
      };

      if (data["deposit"] != true) data.remove("depositPrice");

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

      data["images"] = imagesUrls;
      data["videos"] = videosUrls;

      final res = await ApiService.getDio.post("/ads/property-ad", data: data);

      if (res.statusCode != 200) {
        deleteManyFilesFromUrl(imagesUrls);
        deleteManyFilesFromUrl(videosUrls);
      }

      switch (res.statusCode) {
        case 200:
          Get.offNamedUntil(
            "/my-property-ads",
            ModalRoute.withName('/home'),
          );

          break;
        default:
          showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
      }
    } catch (e) {
      Get.log("$e");
      deleteManyFilesFromUrl(imagesUrls);
      deleteManyFilesFromUrl(videosUrls);
    } finally {
      isLoading(false);
    }
  }

  Future<void> _upatePropertyAd() async {
    isLoading(true);

    List<String> imagesUrls = [];
    List<String> videosUrls = [];
    try {
      final data = {
        ...information,
        "address": address,
        "amenties": amenties,
        "agentInfo": agentBrokerInformation,
        "socialPreferences": socialPreferences,
        "cameraPosition": cameraPosition?.toMap(),
        "autoCompletePredicate": autoCompletePredicate?.toMap(),
      };

      if (data["deposit"] != true) data.remove("depositPrice");

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

      data["images"] = [...oldImages, ...imagesUrls];
      data["videos"] = [...oldVideos, ...videosUrls];

      final res = await ApiService.getDio
          .put("/ads/property-ad/${oldData?.id}", data: data);

      if (res.statusCode != 200) {
        deleteManyFilesFromUrl(imagesUrls);
        deleteManyFilesFromUrl(videosUrls);
      }

      switch (res.statusCode) {
        case 200:
          isLoading(false);
          await showConfirmDialog("Ad updated successfully. ", isAlert: true);

          deleteManyFilesFromUrl(
            oldData!.images.where((e) => !imagesUrls.contains(e)).toList(),
          );
          deleteManyFilesFromUrl(
            oldData!.videos.where((e) => !oldVideos.contains(e)).toList(),
          );
          Get.offNamedUntil(
            "/my-property-ads",
            ModalRoute.withName('/home'),
          );
          break;
        case 500:
          showGetSnackbar("someThingWentWrong".tr, severity: Severity.error);
          break;
        default:
          showToast("someThingWentWrong".tr);
      }
    } catch (e) {
      Get.log("$e");
      deleteManyFilesFromUrl(imagesUrls);
      deleteManyFilesFromUrl(videosUrls);
    } finally {
      isLoading(false);
    }
  }
}

class PostPropertyAdScreen extends StatelessWidget {
  const PostPropertyAdScreen({super.key, this.oldData});
  final PropertyAd? oldData;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_PostPropertyAdController(oldData: oldData));
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
              oldData != null ? "Update Property Ad" : "Post Property Ad",
            ),
            backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 50),
                child: PageView(
                  controller: controller._pageController,
                  onPageChanged: (index) => controller._pageIndex(index),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Property type
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          "Bed",
                          "Partition",
                          "Room",
                          "Master Room",
                          "Mix"
                        ].map((e) {
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

                    // Information
                    SingleChildScrollView(
                      child: Form(
                        key: controller._informationFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            // Quantity
                            Text('quantity'.tr),
                            TextFormField(
                              initialValue:
                                  controller.information["quantity"] as String,
                              enabled: controller.isLoading.isFalse,
                              decoration:
                                  InputDecoration(hintText: 'quantity'.tr),
                              onChanged: (value) =>
                                  controller.information["quantity"] = value,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'thisFieldIsRequired'.tr;
                                }
                                final numValue = int.tryParse(value);

                                if (numValue == null || numValue < 1) {
                                  return 'invalidPropertyAdQuantityMessage'.tr;
                                }
                                if (numValue > 200) {
                                  return 'Quantity must be less than 200'.tr;
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
                            // Rent type
                            Text('Prefered rent type'.tr),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                hintText: 'Rent type',
                              ),
                              value: controller.information["preferedRentType"]
                                  as String,
                              items: ["Monthly", "Weekly", "Daily"]
                                  .map((e) => DropdownMenuItem<String>(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: controller.isLoading.isTrue
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        controller.information[
                                            "preferedRentType"] = val;
                                      }
                                    },
                            ),
                            const SizedBox(height: 20),
                            // Price
                            for (final item in [
                              {
                                'value': "monthlyPrice",
                                'label': "Monthly rent price",
                              },
                              {
                                'value': "weeklyPrice",
                                'label': "Weekly rent price",
                              },
                              {
                                'value': "dailyPrice",
                                'label': "Daily rent price",
                              },
                            ]) ...[
                              Text(item['label']!),
                              TextFormField(
                                initialValue: controller
                                    .information[item['value']] as String,
                                enabled: controller.isLoading.isFalse,
                                decoration: InputDecoration(
                                  hintText: item['label'],
                                  suffixText: "AED",
                                ),
                                onChanged: (value) => controller
                                    .information[item['value']!] = value,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }

                                  final numValue = int.tryParse(value);

                                  if (numValue == null || numValue < 0) {
                                    return 'invalidValue'.tr;
                                  }

                                  if (item["value"] == "weeklyPrice") {
                                    final monthPrice = int.tryParse(controller
                                        .information["monthlyPrice"]
                                        .toString());

                                    if (monthPrice != null &&
                                        numValue > monthPrice) {
                                      return 'Weekly price must best less than Monthly price';
                                    }
                                  } else if (item["value"] == "dailyPrice") {
                                    final weeklyPrice = int.tryParse(controller
                                        .information["weeklyPrice"]
                                        .toString());

                                    if (weeklyPrice != null &&
                                        numValue > weeklyPrice) {
                                      return 'Daily price must best less than Weekly price';
                                    }
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(priceRegex)
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Deposit
                            // Text('deposit'.tr),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  width: 1,
                                  color: Colors.grey,
                                ),
                              ),
                              child: CheckboxListTile(
                                value:
                                    controller.information["deposit"] as bool,
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.information["deposit"] = val;
                                  }
                                },
                                title: Text('deposit'.tr),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (controller.information["deposit"] == true)
                              // Deposit fee
                              Text('depositFee'.tr),
                            if (controller.information["deposit"] == true)
                              TextFormField(
                                initialValue:
                                    controller.information["depositFee"] == null
                                        ? ''
                                        : controller.information["depositFee"]
                                            as String,
                                enabled: controller.isLoading.isFalse,
                                decoration: InputDecoration(
                                  hintText: 'Example 100 AED'.tr,
                                  suffixText: AppController
                                      .instance.country.value.currencyCode,
                                ),
                                onChanged: (value) => controller
                                    .information["depositFee"] = value,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }

                                  final numValue = int.tryParse(value);

                                  if (numValue == null || numValue < 0) {
                                    return 'invalidValue'.tr;
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(priceRegex)
                                ],
                              ),
                            const SizedBox(height: 10),
                            // Description
                            Text('description'.tr),
                            TextFormField(
                              initialValue: controller
                                  .information["description"] as String,
                              enabled: controller.isLoading.isFalse,
                              decoration: InputDecoration(
                                hintText: 'Add your ad description here'.tr,
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
                          ],
                        ),
                      ),
                    ),

                    // Who are you
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          // Poster type
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: ["Landlord", "Agent/Broker"].map((e) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: RadioListTile<String>(
                                  value: e,
                                  groupValue: controller
                                      .information["posterType"] as String,
                                  onChanged: (value) {
                                    if (value != null) {
                                      controller.information["posterType"] =
                                          value;
                                    }
                                  },
                                  title: Text(e),
                                ),
                              );
                            }).toList(),
                          ),
                          if (controller.information["posterType"] ==
                              "Agent/Broker")
                            Form(
                              key: controller._agentBrokerFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Text(
                                        'You are an Agent/Broker right? Tell us about you'
                                            .tr),
                                  ),
                                  const SizedBox(height: 10),
                                  // First name
                                  Text('firstName'.tr),
                                  TextFormField(
                                    initialValue: controller
                                        .agentBrokerInformation["firstName"],
                                    enabled: controller.isLoading.isFalse,
                                    decoration: InputDecoration(
                                        hintText: 'firstName'.tr),
                                    onChanged: (value) =>
                                        controller.agentBrokerInformation[
                                            "firstName"] = value,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'thisFieldIsRequired'.tr;
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 10),
                                  // Last name
                                  Text('lastName'.tr),
                                  TextFormField(
                                    initialValue: controller
                                        .agentBrokerInformation["lastName"],
                                    enabled: controller.isLoading.isFalse,
                                    decoration: InputDecoration(
                                        hintText: 'lastName'.tr),
                                    onChanged: (value) =>
                                        controller.agentBrokerInformation[
                                            "lastName"] = value,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'thisFieldIsRequired'.tr;
                                      }

                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  // Email
                                  Text('email'.tr),
                                  TextFormField(
                                    initialValue: controller
                                        .agentBrokerInformation["email"],
                                    enabled: controller.isLoading.isFalse,
                                    decoration:
                                        InputDecoration(hintText: 'email'.tr),
                                    onChanged: (value) => controller
                                            .agentBrokerInformation["email"] =
                                        value,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'thisFieldIsRequired'.tr;
                                      }
                                      if (!value.isEmail) {
                                        return 'invalidEmail'.tr;
                                      }

                                      return null;
                                    },
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 10),
                                  Text('phoneNumber'.tr),
                                  PhoneNumberInput(
                                    initialValue: controller.agentPhoneNumber,
                                    hintText: "phoneNumber".tr,
                                    onChange: (phoneNumber) {
                                      controller.agentPhoneNumber = phoneNumber;
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Property address
                    SingleChildScrollView(
                      child: Form(
                        key: controller._addressFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            // City
                            Text('city'.tr),
                            TypeAheadFormField<String>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: controller._cityController,
                                decoration: const InputDecoration(
                                  hintText: 'Example : Dubai',
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

                            const SizedBox(height: 20),
                            // Location
                            Text('location'.tr),
                            TypeAheadField<String>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: controller._locationController,
                                decoration: const InputDecoration(
                                  hintText: "Search for location",
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
                            // Building Name
                            Text('buildingName'.tr),
                            TextFormField(
                              initialValue: controller.address["buildingName"],
                              enabled: controller.isLoading.isFalse,
                              decoration: InputDecoration(
                                  hintText: 'Your property building'.tr),
                              onChanged: (value) =>
                                  controller.address["buildingName"] = value,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'thisFieldIsRequired'.tr;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            // Floor number
                            Text('floorNumber'.tr),
                            TextFormField(
                              initialValue: controller.address["floorNumber"],
                              enabled: controller.isLoading.isFalse,
                              decoration:
                                  InputDecoration(hintText: 'Examlple : 17'.tr),
                              onChanged: (value) =>
                                  controller.address["floorNumber"] = value,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'thisFieldIsRequired'.tr;
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*'))
                              ],
                            ),
                            const SizedBox(height: 10),
                            const SizedBox(height: 10),
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
                                  "Help everyone imagine What it's like "
                                  "to live at your property upload clear"
                                  " photo and video of your property",
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
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                child: Checkbox(
                                  value: controller.needsPhotograph.isTrue,
                                  onChanged: controller.isLoading.isTrue
                                      ? null
                                      : (_) =>
                                          controller.needsPhotograph.toggle(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text("Nedd photographer?".tr),
                              const Spacer(),
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
                          const SizedBox(height: 10),

                          // Center(child: Text('otherPreferences'.tr)),
                          // const SizedBox(height: 10),

                          // People Count
                          Text("numberOfPeople".tr),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              hintText: 'numberOfPeople'.tr,
                            ),
                            value: controller
                                .socialPreferences["numberOfPeople"] as String,
                            items: [
                              "1 to 5",
                              "5 to 10",
                              "10 to 15",
                              "15 to 20",
                              "+20",
                            ]
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
                          const SizedBox(height: 20),
                          // Nationalities
                          Text("nationality".tr),
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
                          const SizedBox(height: 10),
                          // Gender
                          Text("gender".tr),
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
                            "visitors",
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
                        ],
                      ),
                    ),

                    // Amenties
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Alert(text: "Your property amenties".tr),
                          const SizedBox(height: 10),
                          GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            childAspectRatio: 1.6,
                            physics: const NeverScrollableScrollPhysics(),
                            children: allAmenties
                                .map(
                                  (e) => GestureDetector(
                                    onTap: () {
                                      if (controller.amenties.contains(e)) {
                                        controller.amenties.remove(e);
                                      } else {
                                        controller.amenties.add(e);
                                      }
                                    },
                                    child: Card(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: controller.amenties.contains(e)
                                              ? Colors.amber.shade900
                                              : Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        height: 100,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.all(10),
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
              if (MediaQuery.of(context).viewInsets.bottom > 50) {
                return const SizedBox();
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    color: const Color.fromRGBO(96, 15, 116, 1),
                    value: (controller._pageIndex.value + 1) /
                        (oldData != null ? 7 : 10),
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
                      // Slider(
                      //   value: controller._pageIndex.value + 1,
                      //   onChanged: (_) {},
                      //   min: 0,
                      //   max: 6,
                      //   divisions: 6,
                      // ),
                      // const Spacer(),
                      // Text('${controller._pageIndex.value + 1}/7'),
                      TextButton(
                        onPressed: controller.isLoading.isTrue
                            ? null
                            : () {
                                switch (controller._pageIndex.value) {
                                  case 0:
                                    controller._moveToNextPage();
                                    break;
                                  case 1:
                                    if (controller
                                            ._informationFormKey.currentState
                                            ?.validate() ==
                                        true) {
                                      controller._moveToNextPage();
                                    }
                                    break;
                                  case 2:
                                    if (controller.information['posterType'] ==
                                        "Agent/Broker") {
                                      if (controller
                                              ._agentBrokerFormKey.currentState
                                              ?.validate() ==
                                          true) {
                                        controller._moveToNextPage();
                                      }
                                    } else {
                                      controller._moveToNextPage();
                                    }
                                    break;
                                  case 3:
                                    if (controller._addressFormKey.currentState
                                            ?.validate() ==
                                        true) {
                                      controller._moveToNextPage();
                                    }
                                    break;
                                  case 4:
                                    if (controller.images.isEmpty &&
                                        controller.oldImages.isEmpty) {
                                      showGetSnackbar(
                                        "You need atleast one image",
                                        severity: Severity.error,
                                      );
                                    } else {
                                      controller._moveToNextPage();
                                    }
                                    break;
                                  case 5:
                                    controller._moveToNextPage();
                                    break;
                                  case 6:
                                    if (oldData != null) {
                                      controller._upatePropertyAd();
                                    } else {
                                      controller._savePropertyAd();
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
      }),
    );
  }
}

final allAmenties = <String>[
  "Close to metro",
  "Balcony",
  "Kitchen appliances",
  "Parking",
  "WIFI",
  "TV",
  "Shared gym",
  "Washer",
  "Cleaning included",
  "Near to supermarket",
  "Shared swimming pool",
  "Near to pharmacy",
];
