import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/phone_input.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/static.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/delete_file_from_url.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/utility_screens/play_video.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/utilities/data.dart';
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
    "buildingName": "",
    "floorNumber": "",
    "countryCode": AppController.instance.country.value.code,
  }.obs;

  final socialPreferences = {
    "numberOfPeople": "1 to 5",
    "grouping": "Single",
    "gender": "Mix",
    "nationality": "Mix",
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
      information["depositPrice"] = oldData!.depositPrice;

      information["description"] = oldData!.description;
      information["posterType"] = oldData!.posterType;

      _cityController.text =
          address["city"] = oldData!.address["city"].toString();
      _locationController.text =
          address["location"] = oldData!.address["location"].toString();
      address["buildingName"] = oldData!.address["buildingName"].toString();
      address["floorNumber"] = oldData!.address["floorNumber"].toString();
      address["countryCode"] = oldData!.address["countryCode"].toString();
      address["appartmentNumber"] =
          oldData!.address["appartmentNumber"].toString();
      amenties.value = oldData!.amenities;

      if (oldData!.agentInfo != null) {
        agentBrokerInformation(oldData!.agentInfo!);
      }

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
      if (information["description"] == null ||
          "${information["description"]}".trim().isEmpty) {
        information.remove("description");
      }
      final data = {
        ...information,
        "address": address,
        "amenities": amenties,
        "agentInfo": agentBrokerInformation,
        "socialPreferences": socialPreferences,
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

      if (data["posterType"] != "Landlord") {
        data.remove("agentInfo");
      }

      final res = await ApiService.getDio.post("/ads/property-ad", data: data);

      if (res.statusCode != 200) {
        deleteManyFilesFromUrl(imagesUrls);
        deleteManyFilesFromUrl(videosUrls);
      }

      switch (res.statusCode) {
        case 200:
          await showSuccessDialog("Your property is added.", isAlert: true);

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

    if (information["description"] == null ||
        "${information["description"]}".trim().isEmpty) {
      information.remove("description");
    }
    try {
      final data = {
        ...information,
        "address": address,
        "amenities": amenties,
        "agentInfo": agentBrokerInformation,
        "socialPreferences": socialPreferences,
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

      // print(res.data["details"]);

      if (res.statusCode != 200) {
        deleteManyFilesFromUrl(imagesUrls);
        deleteManyFilesFromUrl(videosUrls);
      }

      switch (res.statusCode) {
        case 200:
          isLoading(false);
          await showSuccessDialog("Ad updated successfully. ", isAlert: true);

          deleteManyFilesFromUrl(
            oldData!.images.where((e) => !oldImages.contains(e)).toList(),
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
          FocusScope.of(context).requestFocus(FocusNode());
          controller._moveToPreviousPage();
          return false;
        }
        return true;
      },
      child: Obx(() {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              oldData != null ? "Update Property" : "Post Property",
            ),
            backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 5,
                    bottom: 50,
                  ),
                  child: PageView(
                    controller: controller._pageController,
                    onPageChanged: (index) => controller._pageIndex(index),
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Property address
                      SingleChildScrollView(
                        child: Form(
                          key: controller._addressFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              const Center(
                                child: Text(
                                  "Please choose LOCATION \nof your property:",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: ROOMY_PURPLE,
                                  ),
                                ),
                              ),
                              const Divider(height: 30),
                              // City
                              InlineDropdown<String>(
                                labelText: 'City',
                                hintText:
                                    AppController.instance.country.value.isUAE
                                        ? 'Example : Dubai'
                                        : "Example : Riyadh",
                                value: controller.address["city"]!.isEmpty
                                    ? null
                                    : controller.address["city"],
                                items: CITIES_FROM_CURRENT_COUNTRY,
                                onChanged: controller.isLoading.isTrue
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          controller.address["location"] = "";
                                          controller.address["city"] = val;
                                        }
                                      },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              // Area
                              InlineDropdown<String>(
                                labelText: 'Area',
                                hintText: "Select for area",
                                value: controller.address["location"]!.isEmpty
                                    ? null
                                    : controller.address["location"],
                                items: getLocationsFromCity(
                                  controller.address["city"].toString(),
                                ),
                                onChanged: controller.isLoading.isTrue
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          controller.address["location"] = val;
                                        }
                                      },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Building Name
                              InlineTextField(
                                labelText: "Tower name",
                                enabled: controller.isLoading.isFalse,
                                initialValue:
                                    controller.address["buildingName"],
                                onChanged: (value) {
                                  controller.address["buildingName"] = value;
                                },
                                labelStyle: const TextStyle(
                                  fontSize: 15,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Appartment number
                              InlineTextField(
                                labelText: "Appartment number",
                                enabled: controller.isLoading.isFalse,
                                initialValue:
                                    controller.address["appartmentNumber"],
                                onChanged: (value) {
                                  controller.address["appartmentNumber"] =
                                      value;
                                },
                                labelStyle: const TextStyle(
                                  fontSize: 15,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*'),
                                  )
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Floor number
                              InlineTextField(
                                labelText: "Floor number",
                                enabled: controller.isLoading.isFalse,
                                initialValue: controller.address["floorNumber"],
                                onChanged: (value) {
                                  controller.address["floorNumber"] = value;
                                },
                                labelStyle: const TextStyle(
                                  fontSize: 15,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*'),
                                  )
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // Property type
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                "Please choose \nPROPERTY TYPE:",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: ROOMY_PURPLE,
                                ),
                              ),
                            ),
                            const Divider(height: 30),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              children: [
                                {
                                  "value": "Bed",
                                  "label": "Bed Space",
                                  "asset": "assets/icons/bed.png",
                                },
                                {
                                  "value": "Partition",
                                  "label": "Partition",
                                  "asset": "assets/icons/partition.png",
                                },
                                {
                                  "value": "Room",
                                  "label": "Regular Room",
                                  "asset": "assets/icons/master_room.png",
                                },
                                {
                                  "value": "Master Room",
                                  "label": "Master Room",
                                  "asset": "assets/icons/regular_room.png",
                                },
                                // "Mix"
                              ].map((e) {
                                return GestureDetector(
                                  onTap: () {
                                    controller.information["type"] =
                                        "${e["value"]}";
                                  },
                                  child: Container(
                                    decoration: shadowedBoxDecoration,
                                    padding: const EdgeInsets.all(10),
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 20),
                                        Expanded(
                                          child: Image.asset(
                                            "${e["asset"]}",
                                            color: controller
                                                        .information["type"] !=
                                                    e["value"]
                                                ? Colors.grey
                                                : null,
                                          ),
                                        ),
                                        Text(
                                          "${e["label"]}",
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
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
                              const Center(
                                child: Text(
                                  "Please fill in \nRENT DETAILS:",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: ROOMY_PURPLE,
                                  ),
                                ),
                              ),
                              const Divider(height: 30),
                              // Quantity
                              InlineTextField(
                                labelWidth: Get.width * 0.3,
                                labelText: 'Number of units'.tr,
                                hintText: 'maximum : 500'.tr,
                                initialValue: controller.information["quantity"]
                                    as String,
                                enabled: controller.isLoading.isFalse,
                                onChanged: (value) =>
                                    controller.information["quantity"] = value,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'thisFieldIsRequired'.tr;
                                  }
                                  final numValue = int.tryParse(value);

                                  if (numValue == null || numValue < 1) {
                                    return 'invalidPropertyAdQuantityMessage'
                                        .tr;
                                  }
                                  if (numValue > 500) {
                                    return 'Quantity must be less than 500'.tr;
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
                              Row(
                                children: [
                                  const Text(
                                    "Rent period",
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Spacer(),
                                  ...["Monthly", "Weekly", "Daily"].map((e) {
                                    return Container(
                                      margin: const EdgeInsets.only(left: 10),
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: controller.information[
                                                    "preferedRentType"] ==
                                                e
                                            ? ROOMY_ORANGE
                                            : Colors.grey.shade200,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          controller.information[
                                              "preferedRentType"] = e;
                                        },
                                        child: Text(e),
                                      ),
                                    );
                                  }).toList()
                                ],
                              ),

                              const SizedBox(height: 20),

                              const Text(
                                "Prices",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),

                              // Price
                              for (final item in [
                                {
                                  'value': "monthlyPrice",
                                  'label': "Monthly",
                                },
                                {
                                  'value': "weeklyPrice",
                                  'label': "Weekly",
                                },
                                {
                                  'value': "dailyPrice",
                                  'label': "Daily",
                                },
                              ]) ...[
                                InlineTextField(
                                  labelWidth: Get.width * 0.3,
                                  labelStyle: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                  labelText: item['label']!,
                                  suffixText: "AED",
                                  initialValue: controller
                                      .information[item['value']] as String,
                                  enabled: controller.isLoading.isFalse,
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
                                      final weeklyPrice = int.tryParse(
                                          controller.information["weeklyPrice"]
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
                                    FilteringTextInputFormatter.allow(
                                        priceRegex)
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Deposit
                              GestureDetector(
                                onTap: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  if (controller.information["deposit"] ==
                                      true) {
                                    controller.information["deposit"] = false;
                                  } else {
                                    controller.information["deposit"] = true;
                                  }
                                },
                                child: Row(
                                  children: [
                                    const Text(
                                      "Deposit",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      controller.information["deposit"] == true
                                          ? Icons.check_circle_outline_outlined
                                          : Icons.circle_outlined,
                                      color: ROOMY_ORANGE,
                                    )
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),
                              if (controller.information["deposit"] == true)
                                InlineTextField(
                                  labelWidth: Get.width * 0.3,
                                  labelText: "Deposit price",
                                  initialValue: controller
                                              .information["depositPrice"] ==
                                          null
                                      ? ''
                                      : controller.information["depositPrice"]
                                          .toString(),
                                  labelStyle: const TextStyle(fontSize: 15),
                                  enabled: controller.isLoading.isFalse,
                                  suffixText: "AED",
                                  onChanged: (value) => controller
                                      .information["depositPrice"] = value,
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
                                    FilteringTextInputFormatter.allow(
                                        priceRegex)
                                  ],
                                ),
                              const SizedBox(height: 10),
                              // // Description
                              // Text('description'.tr),
                              // TextFormField(
                              //   initialValue: controller
                              //       .information["description"] as String,
                              //   enabled: controller.isLoading.isFalse,
                              //   decoration: InputDecoration(
                              //     hintText: 'Add your ad description here'.tr,
                              //   ),
                              //   onChanged: (value) =>
                              //       controller.information["description"] = value,
                              //   validator: (value) {
                              //     if (value == null || value.trim().isEmpty) {
                              //       return 'thisFieldIsRequired'.tr;
                              //     }
                              //     return null;
                              //   },
                              //   minLines: 2,
                              //   maxLines: 5,
                              //   maxLength: 500,
                              // ),
                            ],
                          ),
                        ),
                      ),

                      // Who are you
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                "Please fill in IF you are \nan AGENT or BROKER:",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: ROOMY_PURPLE,
                                ),
                              ),
                            ),
                            const Divider(height: 30),
                            Row(
                              children: [
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    controller.information["posterType"] =
                                        "Landlord";
                                  },
                                  child: Icon(
                                    controller.information["posterType"] ==
                                            "Landlord"
                                        ? Icons.check_circle_outline_outlined
                                        : Icons.circle_outlined,
                                    color: ROOMY_ORANGE,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    controller.information["posterType"] =
                                        "Landlord";
                                  },
                                  child: const Text(
                                    "Landlord",
                                    style: TextStyle(
                                      color: ROOMY_PURPLE,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    controller.information["posterType"] =
                                        "Agent/Broker";
                                  },
                                  child: Icon(
                                    controller.information["posterType"] ==
                                            "Agent/Broker"
                                        ? Icons.check_circle_outline_outlined
                                        : Icons.circle_outlined,
                                    color: ROOMY_ORANGE,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    controller.information["posterType"] =
                                        "Agent/Broker";
                                  },
                                  child: const Text(
                                    "Agent/Broker",
                                    style: TextStyle(
                                      color: ROOMY_PURPLE,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 20), // Poster type

                            if (controller.information["posterType"] ==
                                "Agent/Broker")
                              Form(
                                key: controller._agentBrokerFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 10),

                                    // First name
                                    InlineTextField(
                                      labelWidth: Get.width * 0.3,
                                      labelText: "firstName".tr,
                                      initialValue: controller
                                          .agentBrokerInformation["firstName"],
                                      enabled: controller.isLoading.isFalse,
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
                                    InlineTextField(
                                      labelWidth: Get.width * 0.3,
                                      labelText: "lastName".tr,
                                      initialValue: controller
                                          .agentBrokerInformation["lastName"],
                                      enabled: controller.isLoading.isFalse,
                                      onChanged: (value) {
                                        controller.agentBrokerInformation[
                                            "lastName"] = value;
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'thisFieldIsRequired'.tr;
                                        }

                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    // Email
                                    InlineTextField(
                                      labelWidth: Get.width * 0.3,
                                      labelText: "email".tr,
                                      initialValue: controller
                                          .agentBrokerInformation["email"],
                                      enabled: controller.isLoading.isFalse,
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
                                    InlinePhoneNumberInput(
                                      labelStyle: const TextStyle(fontSize: 15),
                                      labelText: 'phoneNumber'.tr,
                                      initialValue: controller.agentPhoneNumber,
                                      hintText: "phoneNumber".tr,
                                      onChange: (phoneNumber) {
                                        controller.agentPhoneNumber =
                                            phoneNumber;
                                      },
                                    ),
                                  ],
                                ),
                              )
                            else
                              const Center(
                                child: Text(
                                  "Continue",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),

                      // property preferences
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                "Please specify TENANT details :",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: ROOMY_PURPLE,
                                ),
                              ),
                            ),
                            const Divider(height: 30),

                            // People Count
                            InlineDropdown<String>(
                              // labelWidth: Get.width * 0.3,
                              labelText: 'numberOfPeople'.tr,
                              value:
                                  controller.socialPreferences["numberOfPeople"]
                                      as String,
                              items: const [
                                "1 to 5",
                                "5 to 10",
                                "10 to 15",
                                "15 to 20",
                                "+20",
                              ],
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
                            // Gender
                            InlineDropdown<String>(
                              labelText: 'gender'.tr,
                              value: controller.socialPreferences["gender"]
                                  as String,
                              items: const ["Male", "Female", "Mix"],
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
                            // Nationalities
                            InlineDropdown<String>(
                              labelText: 'nationality'.tr,
                              value: controller.socialPreferences["nationality"]
                                  as String,
                              items: allNationalities,
                              onChanged: controller.isLoading.isTrue
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        controller.socialPreferences[
                                            "nationality"] = val;
                                      }
                                    },
                            ),
                            const Divider(height: 40),

                            const Center(
                              child: Text(
                                "Comfortable with :",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: ROOMY_PURPLE,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              children: [
                                {
                                  "value": "smoking",
                                  "label": "Smoking",
                                  "asset": "assets/icons/smoking.png",
                                },
                                {
                                  "value": "drinking",
                                  "label": "Drinking",
                                  "asset": "assets/icons/drink.png",
                                },
                                {
                                  "value": "visitors",
                                  "label": "Visitors",
                                  "asset": "assets/icons/people.png",
                                },

                                // "Mix"
                              ].map((e) {
                                return GestureDetector(
                                  onTap: () {
                                    if (controller
                                            .socialPreferences[e["value"]] ==
                                        true) {
                                      controller.socialPreferences[
                                          "${e["value"]}"] = false;
                                    } else {
                                      controller.socialPreferences[
                                          "${e["value"]}"] = true;
                                    }
                                  },
                                  child: Container(
                                    decoration: shadowedBoxDecoration,
                                    padding: const EdgeInsets.all(10),
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: Image.asset(
                                            "${e["asset"]}",
                                            color: controller.socialPreferences[
                                                        e["value"]] ==
                                                    true
                                                ? ROOMY_ORANGE
                                                : null,
                                          ),
                                        ),
                                        Text(
                                          "${e["label"]}",
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      // Amenities
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                "Please choose AMENITIES \nof your property:",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: ROOMY_PURPLE,
                                ),
                              ),
                            ),
                            const Divider(height: 30),
                            const SizedBox(height: 10),
                            GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: 3,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              children: allAmenities
                                  .map(
                                    (e) => GestureDetector(
                                      onTap: () {
                                        if (controller.amenties
                                            .contains(e["value"])) {
                                          controller.amenties
                                              .remove(e["value"]);
                                        } else {
                                          controller.amenties
                                              .add("${e["value"]}");
                                        }
                                      },
                                      child: Container(
                                        decoration: shadowedBoxDecoration,
                                        padding: const EdgeInsets.all(10),
                                        alignment: Alignment.center,
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 10),
                                            Expanded(
                                              child: Image.asset(
                                                "${e["asset"]}",
                                                color: controller.amenties
                                                        .contains(e["value"])
                                                    ? ROOMY_ORANGE
                                                    : Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              "${e["value"]}",
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),

                      // Images/Videos
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                "IMAGES & VIDEOS:",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: ROOMY_PURPLE,
                                ),
                              ),
                            ),
                            const Divider(height: 30),
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
                                        Get.to(transition: Transition.zoom, () {
                                          return ViewImages(
                                            images: controller.oldImages
                                                .map((e) =>
                                                    CachedNetworkImageProvider(
                                                        e))
                                                .toList(),
                                            initialIndex:
                                                controller.oldImages.indexOf(e),
                                            title: oldData == null
                                                ? "Images"
                                                : "Old images",
                                          );
                                        });
                                      }
                                    };
                                  }),
                                  ...controller.images.map((e) {
                                    return {
                                      "onTap": () =>
                                          controller.images.remove(e),
                                      "imageUrl": e.path,
                                      "isFile": true,
                                      "onViewImage": () {
                                        Get.to(transition: Transition.zoom, () {
                                          return ViewImages(
                                            images: controller.images
                                                .map((e) =>
                                                    FileImage(File(e.path)))
                                                .toList(),
                                            initialIndex:
                                                controller.images.indexOf(e),
                                            title: oldData == null
                                                ? "Images"
                                                : "New images",
                                          );
                                        });
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
                                                    imageUrl:
                                                        "${e["imageUrl"]}",
                                                    fit: BoxFit.cover,
                                                  );
                                                }),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap:
                                                e["onTap"] as void Function()?,
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
                                      "onTap": () =>
                                          controller.videos.remove(e),
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
                                              child:
                                                  Builder(builder: (context) {
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
                                              onTap: e["onTap"] as void
                                                  Function()?,
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
                                      label: Text(
                                        "Images".tr,
                                        style: const TextStyle(fontSize: 12),
                                      ),
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
                                      label: Text(
                                        "camera".tr,
                                        style: const TextStyle(fontSize: 12),
                                      ),
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
                                      label: Text(
                                        "Videos".tr,
                                        style: const TextStyle(fontSize: 12),
                                      ),
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
                                Text("Need photographer?".tr),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),

                      // Description
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                "Please add description to your\n property:",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: ROOMY_PURPLE,
                                ),
                              ),
                            ),
                            const Divider(height: 30),

                            // Description
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: TextFormField(
                                initialValue: controller
                                    .information["description"] as String?,
                                enabled: controller.isLoading.isFalse,
                                decoration: InputDecoration(
                                  hintText: 'Type...'.tr,
                                  border: InputBorder.none,
                                  fillColor: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey
                                      : Colors.grey.shade200,
                                ),
                                onChanged: (value) => controller
                                    .information["description"] = value,
                                validator: (value) {
                                  return null;
                                },
                                minLines: 5,
                                maxLines: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.isLoading.isTrue)
                  const LinearProgressIndicator(),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Container(
            decoration: const BoxDecoration(
              color: ROOMY_PURPLE,
              borderRadius: BorderRadius.vertical(
                top: Radius.elliptical(30, 10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(),

                IconButton(
                  onPressed: controller.isLoading.isTrue
                      ? null
                      : () {
                          FocusScope.of(context).requestFocus(FocusNode());
                          switch (controller._pageIndex.value) {
                            case 0:
                              if (controller._addressFormKey.currentState
                                      ?.validate() ==
                                  true) {
                                controller._moveToNextPage();
                              }
                              break;

                            case 1:
                              controller._moveToNextPage();
                              break;
                            case 2:
                              if (controller._informationFormKey.currentState
                                      ?.validate() ==
                                  true) {
                                controller._moveToNextPage();
                              }
                              break;

                            case 3:
                              if (controller.information['posterType'] ==
                                  "Agent/Broker") {
                                var validate = controller
                                    ._agentBrokerFormKey.currentState
                                    ?.validate();

                                if (validate == true) {
                                  controller._moveToNextPage();
                                }
                              } else {
                                controller._moveToNextPage();
                              }

                              break;
                            case 4:
                              controller._moveToNextPage();
                              break;
                            case 5:
                              controller._moveToNextPage();
                              break;
                            case 6:
                              controller._moveToNextPage();
                              break;
                            case 7:
                              if (oldData != null) {
                                controller._upatePropertyAd();
                              } else {
                                controller._savePropertyAd();
                              }
                              break;
                            default:
                          }
                          controller.update();
                        },
                  icon: const Icon(
                    CupertinoIcons.chevron_right_circle,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                // const Icon(Icons.arrow_right),
              ],
            ),
          ),
        );
      }),
    );
  }
}
