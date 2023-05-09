// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/cupertino.dart';
import "package:path/path.dart" as path;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/data/static.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:roomy_finder/classes/api_service.dart';
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
  final RoommateAd? oldData;

  _PostRoommateAdController({this.oldData});

  final _movingDateController = TextEditingController();

  final _aboutPropertyFormKey = GlobalKey<FormState>();
  final _aboutYouFormKey = GlobalKey<FormState>();

  late final PageController _pageController;
  final _pageIndex = 0.obs;

  // Information
  final oldImages = <String>[].obs;
  final images = <XFile>[].obs;

  final oldVideos = <String>[].obs;
  final videos = <XFile>[].obs;
  final interests = <String>[].obs;
  final languages = <String>[].obs;

  final amenities = <String>[].obs;

  PhoneNumber agentPhoneNumber = PhoneNumber();

  final information = <String, Object?>{
    "type": "Studio",
    "rentType": "Monthly",
    "action": "HAVE ROOM",
  }.obs;

  final aboutYou = <String, Object?>{
    // "nationality": "Arab",
    // "astrologicalSign": "ARIES",
    "gender": AppController.me.gender,
    // "age": "",
    // "occupation": "Professional",
    // "lifeStyle": "Early Bird",
  }.obs;

  final address = <String, String>{
    // "city": "",
    // "location": "",
    "countryCode": AppController.instance.country.value.code,
  }.obs;

  final socialPreferences = {
    "grouping": "Single",
    "gender": "Male",
    "nationality": "Arab",
    "smoking": false,
    "cooking": false,
    "drinking": false,
    "swimming": false,
    "friendParty": false,
    "gym": false,
    "wifi": false,
    "tv": false,
    "pet": false,
  }.obs;

  @override
  void onInit() {
    if (oldData != null) {
      oldImages.addAll(oldData!.images);
      oldVideos.addAll(oldData!.videos);

      information["type"] = oldData!.type;
      information["rentType"] = oldData!.rentType;
      information["action"] = oldData!.action;
      information["budget"] = oldData!.budget.toString();
      information["description"] = oldData!.description;
      _movingDateController.text =
          _movingDateController.text = Jiffy(oldData!.movingDate).yMEd;
      if (oldData!.movingDate != null) {
        information["movingDate"] = oldData!.movingDate?.toIso8601String();
      }

      address["city"] = oldData!.address["city"] as String;
      address["location"] = oldData!.address["location"] as String;
      address["countryCode"] = oldData!.address["countryCode"] as String;

      aboutYou["nationality"] = oldData!.aboutYou["nationality"] as String?;
      aboutYou["astrologicalSign"] =
          oldData!.aboutYou["astrologicalSign"] as String?;
      aboutYou["gender"] = oldData!.aboutYou["gender"] as String?;
      if (oldData!.aboutYou["age"] != null) {
        aboutYou["age"] = oldData!.aboutYou["age"].toString();
      }
      aboutYou["occupation"] = oldData!.aboutYou["occupation"] as String?;
      aboutYou["lifeStyle"] = oldData!.aboutYou["lifeStyle"] as String?;

      languages.value =
          List<String>.from(oldData!.aboutYou["languages"] as List);
      amenities.value = List<String>.from(oldData!.amenities);
      interests.value = List<String>.from(oldData!.interests);

      socialPreferences.value = oldData!.socialPreferences;
    }
    super.onInit();
    _pageController = PageController();
  }

  @override
  void onClose() {
    _pageController.dispose();
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

      final data = {
        ...information,
        "address": address,
        "aboutYou": aboutYou,
        "socialPreferences": socialPreferences,
        "amenities": amenities,
        "interests": interests,
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

      if (data["description"] == null ||
          "${data["description"]}".trim().isEmpty) data.remove("description");

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

            await showSuccessDialog("Your Ad is posted.", isAlert: true);
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
        // print(res.data["details"]);
        if (res.statusCode != 200) {
          deleteManyFilesFromUrl(imagesUrls);
          deleteManyFilesFromUrl(videosUrls);
        }

        switch (res.statusCode) {
          case 200:
            isLoading(false);
            await showSuccessDialog("Ad updated successfully.", isAlert: true);

            deleteManyFilesFromUrl(
              oldData!.images.where((e) => !oldImages.contains(e)).toList(),
            );
            deleteManyFilesFromUrl(
              oldData!.videos.where((e) => !oldVideos.contains(e)).toList(),
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

class PostRoommateAdScreen extends StatelessWidget {
  const PostRoommateAdScreen({super.key, this.oldData});

  final RoommateAd? oldData;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_PostRoommateAdController(
      oldData: oldData,
    ));
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
        var lifeStyleWidget = Column(
          children: [
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/icons/lifestyle.png",
                  height: 50,
                ),
                const SizedBox(width: 10),
                const Text(
                  "Your LIFESTYLE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: ROOMY_PURPLE,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                {
                  "value": "Early Brird",
                  "asset": "assets/icons/bird.png",
                },
                {
                  "value": "Night Owl",
                  "asset": "assets/icons/owl.png",
                },
              ].map((e) {
                return GestureDetector(
                  onTap: () {
                    controller.aboutYou["lifeStyle"] = "${e["value"]}";
                  },
                  child: Container(
                    decoration: shadowedBoxDecoration,
                    padding: const EdgeInsets.all(10),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            "${e["asset"]}",
                            color:
                                controller.aboutYou["lifeStyle"] == e["value"]
                                    ? null
                                    : Colors.grey,
                          ),
                        ),
                        Text(
                          "${e["value"]}",
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
            const Spacer(),
          ],
        );
        final imagesWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Please add IMAGES/VIDEOS",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: ROOMY_PURPLE,
                  ),
                ),
              ),
              const Divider(height: 30),
              // if (controller.images.isEmpty &&
              //     controller.oldImages.isEmpty &&
              //     controller.videos.isEmpty &&
              //     controller.oldVideos.isEmpty)
              //   Card(
              //     child: Container(
              //       alignment: Alignment.center,
              //       padding: const EdgeInsets.all(10),
              //       height: 150,
              //       child: const Text(
              //         "Please upload your photos",
              //         textAlign: TextAlign.center,
              //       ),
              //     ),
              //   ),
              if (controller.images.length + controller.oldImages.length != 0)
                GridView.count(
                  crossAxisCount: Get.width > 370 ? 4 : 2,
                  crossAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: [
                    ...controller.oldImages.map((e) {
                      return {
                        "onTap": () => controller.oldImages.remove(e),
                        "imageUrl": e,
                        "isFile": false,
                        "onViewImage": () {
                          Get.to(transition: Transition.zoom, () {
                            return ViewImages(
                              images: controller.oldImages
                                  .map((e) => CachedNetworkImageProvider(e))
                                  .toList(),
                              initialIndex: controller.oldImages.indexOf(e),
                              title: oldData == null ? "Images" : "Old images",
                            );
                          });
                        }
                      };
                    }),
                    ...controller.images.map((e) {
                      return {
                        "onTap": () => controller.images.remove(e),
                        "imageUrl": e.path,
                        "isFile": true,
                        "onViewImage": () {
                          Get.to(transition: Transition.zoom, () {
                            return ViewImages(
                              images: controller.images
                                  .map((e) => FileImage(File(e.path)))
                                  .toList(),
                              initialIndex: controller.images.indexOf(e),
                              title: oldData == null ? "Images" : "New images",
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
                              onTap: e["onViewImage"] as void Function()?,
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                margin: const EdgeInsets.all(5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Builder(builder: (context) {
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
              if (controller.videos.length + controller.oldVideos.length != 0)
                GridView.count(
                  crossAxisCount: Get.width > 370 ? 4 : 2,
                  crossAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: [
                    ...controller.oldVideos.map((e) {
                      return {
                        "onTap": () => controller.oldVideos.remove(e),
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
                                borderRadius: BorderRadius.circular(5),
                              ),
                              margin: const EdgeInsets.all(5),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Builder(builder: (context) {
                                  if (e["isFile"] == true) {
                                    return FutureBuilder(
                                      builder: (ctx, asp) {
                                        if (asp.hasData) {
                                          return Image.memory(
                                            asp.data!,
                                            fit: BoxFit.cover,
                                            alignment: Alignment.center,
                                          );
                                        }
                                        return Container();
                                      },
                                      future: VideoThumbnail.thumbnailData(
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
                                          alignment: Alignment.center,
                                        );
                                      }
                                      return Container();
                                    },
                                    future: VideoThumbnail.thumbnailFile(
                                      video: "${e["url"]}",
                                    ),
                                  );
                                }),
                              ),
                            ),
                            GestureDetector(
                              onTap: e["onPlayVideo"] as void Function()?,
                              child: const Icon(
                                Icons.play_arrow,
                                size: 40,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: e["onTap"] as void Function()?,
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
                          style: const TextStyle(
                            fontSize: 12,
                          ),
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
                            : () => controller._pickPicture(gallery: false),
                        icon: const Icon(Icons.camera),
                        label: Text(
                          "camera".tr,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
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
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 50),
            ],
          ),
        );
        final aboutRoommateWidget = SingleChildScrollView(
          child: Form(
            key: controller._aboutPropertyFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    controller.information["action"] == "HAVE ROOM"
                        ? "Please fill in \nPROPERTY DETAILS:"
                        : "Please fill in \nPREFERRED ROOM DETAILS:",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: ROOMY_PURPLE,
                    ),
                  ),
                ),
                const Divider(height: 30),
                // Roommate type
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Property type",
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ...["Studio", "Appartment", "House"].map((e) {
                      return Container(
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: controller.information["type"] == e
                              ? ROOMY_ORANGE
                              : Colors.grey.shade200,
                        ),
                        child: InkWell(
                          onTap: () {
                            controller.information["type"] = e;
                          },
                          child: Text(e),
                        ),
                      );
                    }).toList()
                  ],
                ),

                const SizedBox(height: 20),
                // Rent type
                InlineDropdown<String>(
                  labelText: 'rentType'.tr,
                  value: controller.information["rentType"] as String?,
                  items: const ["Monthly", "Weekly", "Daily"],
                  onChanged: controller.isLoading.isTrue
                      ? null
                      : (val) {
                          if (val != null) {
                            controller.information["rentType"] = val;
                          }
                        },
                ),
                const SizedBox(height: 20),
                // Budget

                InlineTextField(
                  labelText: 'budget'.tr,
                  suffixText: AppController.instance.country.value.currencyCode,
                  hintText:
                      'Example 5000 ${AppController.instance.country.value.currencyCode}',
                  initialValue: controller.information["budget"] as String?,
                  enabled: controller.isLoading.isFalse,
                  onChanged: (value) =>
                      controller.information["budget"] = value,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(priceRegex)
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'thisFieldIsRequired'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                InlineTextField(
                  labelText: 'Moving Date'.tr,
                  hintText: 'Choose a moving date'.tr,
                  suffixIcon: const Icon(Icons.calendar_month),
                  readOnly: true,
                  controller: controller._movingDateController,
                  onChanged: (_) {},
                  enabled: controller.isLoading.isFalse,
                  onTap: controller.pickMovingDate,
                ),
                const Divider(height: 40),
                // City
                InlineDropdown<String>(
                  labelText: 'City',
                  hintText: AppController.instance.country.value.isUAE
                      ? 'Example : Dubai'
                      : "Example : Riyadh",
                  value: controller.address["city"]?.isEmpty == true
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
                  value: controller.address["location"]?.isEmpty == true
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

                const Divider(),
              ],
            ),
          ),
        );
        final amenitiesWidget = SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(
                  controller.information["action"] == "HAVE ROOM"
                      ? "Please choose AMENITIES \nof your property:"
                      : "Please select \nPREFERRED AMENITIES:",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                          if (controller.amenities.contains(e["value"])) {
                            controller.amenities.remove(e["value"]);
                          } else {
                            controller.amenities.add("${e["value"]}");
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
                                  color:
                                      controller.amenities.contains(e["value"])
                                          ? ROOMY_ORANGE
                                          : Colors.grey,
                                ),
                              ),
                              Text(
                                "${e["value"]}",
                                style: const TextStyle(
                                  color: ROOMY_PURPLE,
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
        );
        final propertyPreferencesWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(
                  (controller.information["action"] == "HAVE ROOM")
                      ? "Please fill in the details of your\n PREFERRED ROOMMATE:"
                      : "Please select your\n PREFERENCES:",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: ROOMY_PURPLE,
                  ),
                ),
              ),
              const Divider(height: 30),

              InlineDropdown<String>(
                labelText: 'gender'.tr,
                value: controller.socialPreferences["gender"] as String?,
                items: const ["Male", "Female", "Mix"],
                onChanged: controller.isLoading.isTrue
                    ? null
                    : (val) {
                        if (val != null) {
                          controller.socialPreferences["gender"] = val;
                        }
                      },
              ),
              const SizedBox(height: 20),
              // Nationalities
              InlineDropdown<String>(
                labelText: 'nationality'.tr,
                value: controller.socialPreferences["nationality"] as String?,
                items: allNationalities,
                onChanged: controller.isLoading.isTrue
                    ? null
                    : (val) {
                        if (val != null) {
                          controller.socialPreferences["nationality"] = val;
                        }
                      },
              ),
              const SizedBox(height: 20),
              // Lifestyle
              InlineDropdown<String>(
                labelText: 'Lifestyle'.tr,
                hintText: 'Select lifestyle',
                value: controller.socialPreferences["lifeStyle"] as String?,
                items: const ["Early Brird", "Night Owl"],
                onChanged: controller.isLoading.isTrue
                    ? null
                    : (val) {
                        if (val != null) {
                          controller.socialPreferences["lifeStyle"] = val;
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.5,
                  children: allSocialPreferences.map((e) {
                    return GestureDetector(
                      onTap: () {
                        if (controller.socialPreferences[e["value"]] == true) {
                          controller.socialPreferences["${e["value"]}"] = false;
                        } else {
                          controller.socialPreferences["${e["value"]}"] = true;
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
                                color:
                                    controller.socialPreferences[e["value"]] ==
                                            true
                                        ? ROOMY_ORANGE
                                        : Colors.grey,
                              ),
                            ),
                            Text(
                              "${e["label"]}",
                              style: const TextStyle(
                                color: ROOMY_PURPLE,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
        final aboutYouWidget = SingleChildScrollView(
          child: Form(
            key: controller._aboutYouFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    "Please tell us about yourself:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: ROOMY_PURPLE,
                    ),
                  ),
                ),
                const Divider(height: 30),
                // Gender
                InlineDropdown<String>(
                  labelText: 'gender'.tr,
                  value: controller.aboutYou["gender"] as String?,
                  items: const ["Male", "Female"],
                  onChanged: controller.isLoading.isTrue
                      ? null
                      : (val) {
                          if (val != null) {
                            controller.aboutYou["gender"] = val;
                          }
                        },
                ),
                const SizedBox(height: 20),
                // Age
                InlineTextField(
                  labelText: 'age'.tr,
                  suffixText: "Years old",
                  hintText: "Enter your age",
                  initialValue: controller.aboutYou["age"] as String?,
                  enabled: controller.isLoading.isFalse,
                  onChanged: (value) {
                    controller.aboutYou["age"] = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    final numValue = int.tryParse(value);

                    if (numValue == null || numValue > 80) {
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
                InlineDropdown<String>(
                  labelText: 'occupation'.tr,
                  value: controller.aboutYou["occupation"] as String?,
                  items: const ["Professional", "Student", "Other"],
                  onChanged: controller.isLoading.isTrue
                      ? null
                      : (val) {
                          if (val != null) {
                            controller.aboutYou["occupation"] = val;
                          }
                        },
                ),
                const SizedBox(height: 20),
                // Nationalities
                InlineDropdown<String>(
                  labelText: 'nationality'.tr,
                  value: controller.aboutYou["nationality"] as String?,
                  items: allNationalities,
                  onChanged: controller.isLoading.isTrue
                      ? null
                      : (val) {
                          if (val != null) {
                            controller.aboutYou["nationality"] = val;
                          }
                        },
                ),
                const SizedBox(height: 20),
                // astrologicalSign
                InlineDropdown<String>(
                  labelText: 'astrologicalSign'.tr,
                  value: controller.aboutYou["astrologicalSign"] as String?,
                  items: astrologicalSigns,
                  onChanged: controller.isLoading.isTrue
                      ? null
                      : (val) {
                          if (val != null) {
                            controller.aboutYou["astrologicalSign"] = val;
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
                            margin: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
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

                const Divider(height: 40),
                // Description
                if (controller.information["action"] == "HAVE ROOM")
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText:
                            (controller.information["action"] == "NEED ROOM")
                                ? "Please tell us more about yourself, your"
                                    " preferred roommate & housing details"
                                : 'Add description here'.tr,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey
                                : Colors.grey.shade200,
                      ),
                      initialValue:
                          controller.information["description"] as String?,
                      enabled: controller.isLoading.isFalse,
                      onChanged: (value) =>
                          controller.information["description"] = value,
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
        );
        final interestWidget = SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Please choose your \nHOBBIES/INTERESTS:",
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
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: roommateInterests
                    .map(
                      (e) => GestureDetector(
                        onTap: () {
                          if (controller.interests.contains(e["value"])) {
                            controller.interests.remove(e["value"]);
                          } else {
                            controller.interests.add("${e["value"]}");
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
                                  color:
                                      controller.interests.contains(e["value"])
                                          ? null
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
        );
        final descriptionWidget = SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Text(
                  (controller.information["action"] == "NEED ROOM")
                      ? "Please tell us more about yourself, your"
                          " preferred roommate & housing details"
                      : 'Add description here'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: ROOMY_PURPLE,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Description
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TextFormField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type...",
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey
                        : Colors.grey.shade200,
                  ),
                  initialValue:
                      controller.information["description"] as String?,
                  enabled: controller.isLoading.isFalse,
                  onChanged: (value) =>
                      controller.information["description"] = value,
                  validator: (value) {
                    return null;
                  },
                  minLines: 5,
                  maxLines: 10,
                ),
              ),

              const Divider(height: 30),
              if (controller.information["action"] == "NEED ROOM")
                TextButton(
                  onPressed: () {
                    controller.saveAd();
                  },
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      color: ROOMY_PURPLE,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
            ],
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(oldData == null
                ? "${controller.information["action"]}"
                : "Update Roommate Ad"),
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
                    bottom: 60,
                  ),
                  child: PageView(
                    controller: controller._pageController,
                    onPageChanged: (index) => controller._pageIndex(index),
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Action
                      Column(
                        children: [
                          const Spacer(),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.5,
                            children: ["HAVE ROOM", "NEED ROOM"].map((e) {
                              return GestureDetector(
                                onTap: () {
                                  if (controller.oldData != null) return;
                                  controller.information["action"] = e;
                                  controller.images.clear();
                                },
                                child: Card(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 3,
                                          blurStyle: BlurStyle.outer,
                                          color: Colors.black54,
                                          spreadRadius: -1,
                                        ),
                                      ],
                                      color:
                                          controller.information["action"] == e
                                              ? ROOMY_ORANGE
                                              : null,
                                    ),
                                    child: Text(
                                      e,
                                      style: const TextStyle(
                                        color: ROOMY_PURPLE,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const Spacer(),
                        ],
                      ),

                      // Images/Videos (Have Room)
                      if (controller.information["action"] == "HAVE ROOM") ...[
                        imagesWidget,
                        aboutRoommateWidget,
                        amenitiesWidget,
                        propertyPreferencesWidget,
                        aboutYouWidget,
                        interestWidget,
                        lifeStyleWidget,
                      ] else ...[
                        aboutYouWidget,
                        imagesWidget,
                        lifeStyleWidget,
                        interestWidget,
                        aboutRoommateWidget,
                        amenitiesWidget,
                        propertyPreferencesWidget,
                        descriptionWidget
                      ],
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
                          if (controller.information["action"] == "HAVE ROOM") {
                            switch (controller._pageIndex.value) {
                              case 0:
                                controller._moveToNextPage();
                                break;
                              case 1:
                                controller._moveToNextPage();
                                break;
                              case 2:
                                final isValid = controller
                                    ._aboutPropertyFormKey.currentState
                                    ?.validate();

                                if (isValid != true) return;

                                controller._moveToNextPage();

                                break;
                              case 3:
                              case 4:
                                controller._moveToNextPage();
                                break;
                              case 5:
                                final isValid = controller
                                    ._aboutYouFormKey.currentState
                                    ?.validate();

                                if (isValid != true) return;

                                controller._moveToNextPage();

                                break;
                              case 6:
                                controller._moveToNextPage();
                                break;
                              case 7:
                                controller.saveAd();
                                break;
                              default:
                            }
                          } else if (controller.information["action"] ==
                              "NEED ROOM") {
                            switch (controller._pageIndex.value) {
                              case 0:
                                controller._moveToNextPage();
                                break;

                              case 1:
                                final isValid = controller
                                    ._aboutYouFormKey.currentState
                                    ?.validate();

                                if (isValid != true) return;

                                controller._moveToNextPage();
                                break;
                              case 2:
                                controller._moveToNextPage();

                                break;

                              case 3:
                              case 4:
                                controller._moveToNextPage();
                                break;
                              case 5:
                                final isValid = controller
                                    ._aboutPropertyFormKey.currentState
                                    ?.validate();

                                if (isValid != true) return;

                                controller._moveToNextPage();
                                break;
                              case 6:
                              case 7:
                                controller._moveToNextPage();
                                break;
                              case 8:
                                controller.saveAd();
                                break;
                              default:
                            }
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
