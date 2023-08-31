// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/cupertino.dart';
import "package:path/path.dart" as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/components/alert.dart';
import 'package:roomy_finder/components/image_grid.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/data/static.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/create_datetime_filename.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/firebase_file_helper.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/screens/utility_screens/play_video.dart';
import 'package:cached_network_image/cached_network_image.dart';

part "./post_ad_controller.dart";

class PostRoommateAdScreen extends StatelessWidget {
  const PostRoommateAdScreen({super.key, this.oldData, required this.action});

  final RoommateAd? oldData;

  /// Either **NEED ROOM** or **HAVE ROOM**
  final String action;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_PostRoomAdController(
      oldData: oldData,
      action: action,
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
      child: GetBuilder<_PostRoomAdController>(builder: (controller) {
        int bigSizeGridCount = MediaQuery.sizeOf(context).width ~/ 150;
        int smallSizeGridCount = MediaQuery.sizeOf(context).width ~/ 100;
        var isNeedRoomPost = controller.information["action"] == "NEED ROOM";

        var personalInformation = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNeedRoomPost)
                const InputPageHeader(
                  title: "INTRODUCE YOUR SELF",
                  subtitle: "First, tell us about yourself",
                )
              else
                const InputPageHeader(
                  title: "INTRODUCE YOUR SELF",
                  subtitle: "Now tell us about yourself!",
                ),

              const SizedBox(height: 20),
              // Gender
              const Text("Gender"),
              InlineSelector(
                items: const ["Male", "Female"],
                value: controller.aboutYou["gender"],
                onChanged: (value) {
                  controller.aboutYou["gender"] = value;
                  controller.update();
                },
              ),

              const SizedBox(height: 20),

              // Nationality
              const Text("Nationality"),
              InlineDropdown<String>(
                hintText: "Indian",
                value: controller.aboutYou["nationality"] as String?,
                items: ALL_NATIONALITIES,
                onChanged: controller.isLoading.isTrue
                    ? null
                    : (val) {
                        if (val != null) {
                          controller.aboutYou["nationality"] = val;
                        }
                      },
              ),

              const SizedBox(height: 20),
              // Age
              const Text("Age"),
              InlineTextField(
                suffixText: "Years old",
                hintText: "28",
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
                          ALL_LANGUAGUES,
                          excluded: controller.languages,
                        );
                        controller.languages.addAll(result);

                        controller.update();
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    )
                  ],
                ),
              ),
            ],
          ),
        );

        var imagesWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNeedRoomPost)
                const InputPageHeader(
                  title: "INTRODUCE YOUR SELF",
                  subtitle: "Upload your pictures!",
                )
              else
                const InputPageHeader(
                  title: "DESCRIBE YOUR PLACE",
                  subtitle: "Add pictures of your room",
                ),

              // Images
              if (controller.images.isEmpty && controller.oldImages.isEmpty)
                Center(
                  child: Image.asset(
                    isNeedRoomPost
                        ? AssetImages.defaultFemalePNG
                        : AssetImages.defaultRoomPNG,
                    height: 150,
                  ),
                )
              else ...[
                ImageGrid(
                  items: controller.oldImages,
                  getImage: (item) => CachedNetworkImageProvider(item),
                  onItemRemoved: (item) {
                    controller.oldImages.remove(item);
                    controller.update();
                  },
                  noDataMessage: "",
                ),
                ImageGrid(
                  items: controller.images,
                  getImage: (item) => FileImage(File(item.path)),
                  onItemRemoved: (item) {
                    controller.images.remove(item);
                    controller.update();
                  },
                  noDataMessage: "",
                ),
              ],

              // Old Videos
              FutureBuilder(
                future: Future.wait(controller.oldVideos
                    .map((e) => VideoThumbnail.thumbnailData(video: e))),
                builder: (context, asp) {
                  if (asp.connectionState == ConnectionState.done) {
                    final data = asp.data!;

                    return ImageGrid(
                      items: data,
                      isVideo: true,
                      getImage: (item) => MemoryImage(item!),
                      onItemRemoved: (item) {
                        controller.oldVideos.removeAt(data.indexOf(item));
                        controller.update();
                      },
                      noDataMessage: "",
                      onItemTap: (item) {
                        controller._playVideo(
                          controller.oldVideos[data.indexOf(item)],
                          false,
                        );
                      },
                    );
                  }

                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              ),

              // New videos
              FutureBuilder(
                future: Future.wait(
                  controller.videos.map((e) {
                    return VideoThumbnail.thumbnailData(video: e.path);
                  }),
                ),
                builder: (context, asp) {
                  if (asp.connectionState == ConnectionState.done) {
                    final data = asp.data!;

                    return ImageGrid(
                      items: data,
                      isVideo: true,
                      getImage: (item) => MemoryImage(item!),
                      onItemRemoved: (item) {
                        controller.videos.removeAt(data.indexOf(item));
                        controller.update();
                      },
                      noDataMessage: "",
                      onItemTap: (item) {
                        controller._playVideo(
                          controller.videos[data.indexOf(item)].path,
                          false,
                        );
                      },
                    );
                  }

                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  isNeedRoomPost
                      ? "Add photos / videos"
                      : "Show off your place!",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  (
                    label: "Images",
                    asset: AssetIcons.galleryPNG,
                    onPressed: () => controller._pickPicture(),
                  ),
                  (
                    label: "Camera",
                    asset: AssetIcons.camera2PNG,
                    onPressed: () => controller._pickPicture(gallery: false),
                  ),
                  (
                    label: "Video",
                    asset: AssetIcons.videoPNG,
                    onPressed: () => controller._pickVideo(),
                  ),
                ].map((e) {
                  return OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        side: BorderSide(color: ROOMY_PURPLE),
                        borderRadius: BorderRadius.all(
                          Radius.circular(5),
                        ),
                      ),
                    ),
                    onPressed: e.onPressed,
                    icon: Image.asset(e.asset, height: 15),
                    label: Text(
                      e.label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 100),
              CustomTooltip(
                message: isNeedRoomPost
                    ? _needRoomImagetoolTiptext
                    : _haveRoomImagetoolTiptext,
              ),
            ],
          ),
        );

        var lifeStyleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InputPageHeader(
              title: "INTRODUCE YOUR SELF",
              subtitle: "What's your lifestyle?",
            ),
            const SizedBox(height: 30),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: [
                (
                  value: "Early Bird",
                  asset: AssetIcons.birdPNG,
                ),
                (
                  value: "Night Owl",
                  asset: AssetIcons.owlPNG,
                ),
              ].map((e) {
                var isSelected = e.value == controller.aboutYou["lifeStyle"];

                return GestureDetector(
                  onTap: () {
                    controller.aboutYou["lifeStyle"] = e.value;
                    controller.update();
                  },
                  child: Container(
                    decoration: shadowedBoxDecoration.copyWith(
                      border: isSelected
                          ? Border.all(width: 2, color: ROOMY_PURPLE)
                          : Border.all(width: 1),
                    ),
                    padding: const EdgeInsets.all(10),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            e.asset,
                            color: isSelected ? ROOMY_ORANGE : Colors.grey,
                          ),
                        ),
                        Text(
                          e.value,
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
        );

        var employmentWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InputPageHeader(
                title: "INTRODUCE YOUR SELF",
                subtitle: "What's your employment status?",
              ),
              const SizedBox(height: 30),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: bigSizeGridCount,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.2,
                children: ALL_EMPLOYMENTS.map((e) {
                  var isSelected = controller.aboutYou["occupation"] == e.value;
                  return GestureDetector(
                    onTap: () {
                      controller.aboutYou["occupation"] = e.value;
                      controller.update();
                    },
                    child: Container(
                      decoration: shadowedBoxDecoration.copyWith(
                        border: isSelected
                            ? Border.all(width: 2, color: ROOMY_PURPLE)
                            : Border.all(width: 1),
                      ),
                      padding: const EdgeInsets.all(5),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Image.asset(
                              e.asset,
                              color: isSelected ? ROOMY_ORANGE : null,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                e.value,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
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
        );

        var astrologicalSignWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InputPageHeader(
                title: "INTRODUCE YOUR SELF",
                subtitle: "What's your astrological sign?",
              ),
              const SizedBox(height: 30),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: smallSizeGridCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: ASTROLOGICAL_SIGNS.map((e) {
                  var isSelected =
                      controller.aboutYou["astrologicalSign"] == e.value;
                  return GestureDetector(
                    onTap: () {
                      controller.aboutYou["astrologicalSign"] = e.value;
                      controller.update();
                    },
                    child: Container(
                      decoration: shadowedBoxDecoration.copyWith(
                        border: isSelected
                            ? Border.all(width: 2, color: ROOMY_PURPLE)
                            : Border.all(width: 1),
                      ),
                      padding: const EdgeInsets.all(5),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Image.asset(
                                e.asset,
                                color: isSelected ? ROOMY_ORANGE : null,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
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
        );

        var interestWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InputPageHeader(
                title: "INTRODUCE YOUR SELF",
                subtitle: "What are your interest / hobbies?",
              ),
              const SizedBox(height: 30),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: smallSizeGridCount,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: ROOMMATE_INTERESTS.map((e) {
                  var isSelected = controller.interests.contains(e["value"]);
                  return GestureDetector(
                    onTap: () {
                      if (controller.interests.contains(e["value"])) {
                        controller.interests.remove(e["value"]);
                      } else {
                        controller.interests.add("${e["value"]}");
                      }

                      controller.update();
                    },
                    child: Container(
                      decoration: shadowedBoxDecoration.copyWith(
                        border: isSelected
                            ? Border.all(width: 1, color: ROOMY_PURPLE)
                            : Border.all(width: 1),
                      ),
                      padding: const EdgeInsets.all(10),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Expanded(
                            child: Image.asset(
                              "${e["asset"]}",
                              color: controller.interests.contains(e["value"])
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
                  );
                }).toList(),
              ),
            ],
          ),
        );

        var roomtypeWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNeedRoomPost)
                const InputPageHeader(
                  title: "Now let us find you a place",
                  subtitle: "What type of accommodation are you looking for?",
                )
              else
                const InputPageHeader(
                  title: "DESCRIBE YOUR PLACE",
                  subtitle:
                      "Let's Start!\nWhat type of accommodation are you offering?",
                ),
              const SizedBox(height: 30),
              ...[
                (
                  value: "Private room",
                  asset: AssetIcons.bigBed1PNG,
                  description: "Own room in a shared accomodation",
                ),
                (
                  value: "Shared room",
                  asset: AssetIcons.doubleBedsPNG,
                  description: "Bed space in a shared accomodation",
                ),
              ].map((e) {
                var isSelected = controller.information['type'] == e.value;
                return GestureDetector(
                  onTap: () {
                    controller.information["type"] = e.value;
                    controller.update();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: ROOMY_PURPLE, width: 2)
                          : Border.all(width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 10,
                    ),
                    margin: const EdgeInsets.only(
                      bottom: 20,
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          e.asset,
                          height: 50,
                          width: 50,
                          color: isSelected ? ROOMY_ORANGE : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                e.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                e.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList()
            ],
          ),
        );

        var preferenceWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InputPageHeader(
                title: "DESCRIBE YOUR PREFERRED PLACE",
                subtitle: "What's your preferred rent type?",
              ),

              // Rent type
              const SizedBox(height: 10),
              InlineSelector(
                items: const ["Monthly", "Weekly", "Daily"],
                value: controller.information["rentType"],
                onChanged: (value) {
                  controller.information["rentType"] = value;
                  controller.update();
                },
              ),

              // Budget
              const SizedBox(height: 20),
              const InputPageHeader(
                subtitle: "What is your budget?",
              ),
              const SizedBox(height: 10),
              InlineTextField(
                suffixText: "AED",
                hintText: 'Example 3000',
                initialValue: controller.information["budget"] as String?,
                enabled: controller.isLoading.isFalse,
                onChanged: (value) => controller.information["budget"] = value,
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

              // Moving date
              const InputPageHeader(
                subtitle: "When would you like to move?",
              ),
              const SizedBox(height: 20),
              InlineTextField(
                hintText: 'Choose a moving date'.tr,
                suffixIcon: const Icon(Icons.calendar_month),
                readOnly: true,
                controller: controller._movingDateController,
                onChanged: (_) {},
                enabled: controller.isLoading.isFalse,
                onTap: controller.pickMovingDate,
              ),
            ],
          ),
        );

        var addressWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNeedRoomPost)
                const InputPageHeader(
                  title: "DESCRIBE YOUR PREFERRED PLACE",
                  subtitle: "Where would you like to live?",
                )
              else
                const InputPageHeader(
                  title: "DESCRIBE YOUR PLACE",
                  subtitle: "Where your room is located?",
                ),

              // Rent type
              const SizedBox(height: 20),
              const InputPageHeader(subtitle: "City"),
              const SizedBox(height: 10),
              // City
              InlineDropdown<String>(
                hintText: AppController.instance.country.value.isUAE
                    ? 'Example : Dubai'
                    : "Example : Riyadh",
                value: controller.address["city"]?.toString(),
                items: CITIES_FROM_CURRENT_COUNTRY,
                onChanged: controller.isLoading.isTrue
                    ? null
                    : (val) {
                        if (val != controller.address["city"]) {
                          controller.address["location"] = null;
                        }
                        if (val != null) {
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
              // location
              const InputPageHeader(subtitle: "Area"),
              const SizedBox(height: 20),
              InlineDropdown<String>(
                hintText: "Select the location",
                value: controller.address["location"]?.toString(),
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
              Center(
                child: Image.asset(
                  AssetIcons.cityPNG,
                  width: 200,
                ),
              ),
            ],
          ),
        );

        var amenitiesWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNeedRoomPost)
                const InputPageHeader(
                  title: "DESCRIBE YOUR PREFERRED PLACE",
                  subtitle:
                      "What amenities you would like to have at your place?",
                )
              else
                const InputPageHeader(
                  title: "DESCRIBE YOUR PLACE",
                  subtitle: "What amenities available at your property?",
                ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: smallSizeGridCount,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: ALL_AMENITIES
                    .map(
                      (e) => GestureDetector(
                        onTap: () {
                          if (controller.amenities.contains(e["value"])) {
                            controller.amenities.remove(e["value"]);
                          } else {
                            controller.amenities.add("${e["value"]}");
                          }

                          controller.update();
                        },
                        child: Container(
                          decoration: shadowedBoxDecoration,
                          padding: const EdgeInsets.all(5),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Expanded(
                                flex: 1,
                                child: Image.asset(
                                  "${e["asset"]}",
                                  color:
                                      controller.amenities.contains(e["value"])
                                          ? ROOMY_ORANGE
                                          : Colors.grey,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Text(
                                    "${e["value"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
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

        var socialPreferenceWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNeedRoomPost)
                const InputPageHeader(
                  title: "DESCRIBE YOUR PREFERRED ROOMMATE",
                  subtitle:
                      "Now tell us with whom would you like to share your accommodation?",
                )
              else
                const InputPageHeader(
                  title: "DESCRIBE YOUR PREFERRED ROOMMATE",
                  subtitle:
                      "With whom would you like to share your accommodation?",
                ),
              const SizedBox(height: 20),

              const Text("Gender"),
              InlineSelector(
                items: const ["Male", "Female", "Mix"],
                value: controller.socialPreferences["gender"] as String?,
                onChanged: (value) {
                  controller.socialPreferences["gender"] = value;
                  controller.update();
                },
              ),

              const SizedBox(height: 20),

              // Nationalities
              const Text("Nationality"),
              InlineDropdown<String>(
                value: controller.socialPreferences["nationality"] as String?,
                items: ALL_NATIONALITIES,
                onChanged: (val) {
                  if (val != null) {
                    controller.socialPreferences["nationality"] = val;
                  }
                },
              ),
              const SizedBox(height: 20),

              const Center(child: Text("Lifestyle")),

              const SizedBox(height: 30),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  (
                    value: "Early Bird",
                    asset: AssetIcons.birdPNG,
                  ),
                  (
                    value: "Night Owl",
                    asset: AssetIcons.owlPNG,
                  ),
                ].map((e) {
                  return GestureDetector(
                    onTap: () {
                      controller.socialPreferences["lifeStyle"] = e.value;
                      controller.update();
                    },
                    child: Container(
                      decoration: shadowedBoxDecoration,
                      padding: const EdgeInsets.all(10),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.asset(
                              e.asset,
                              color:
                                  controller.socialPreferences["lifeStyle"] ==
                                          e.value
                                      ? null
                                      : Colors.grey,
                            ),
                          ),
                          Text(
                            e.value,
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
        );

        var socialPreferenceWidget2 = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNeedRoomPost)
                const InputPageHeader(
                  title: "DESCRIBE YOUR PREFERRED ROOMMATE",
                  subtitle:
                      "What things would you be comfortable with at your place?",
                )
              else
                const InputPageHeader(
                  title: "DESCRIBE YOUR PREFERRED ROOMMATE",
                  subtitle:
                      "What things would you allow in your apartment/room?",
                ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: bigSizeGridCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.3,
                children: ALL_SOCIAL_PREFERENCES.map((e) {
                  return GestureDetector(
                    onTap: () {
                      if (controller.socialPreferences[e["value"]] == true) {
                        controller.socialPreferences["${e["value"]}"] = false;
                      } else {
                        controller.socialPreferences["${e["value"]}"] = true;
                      }
                      controller.update();
                    },
                    child: Container(
                      decoration: shadowedBoxDecoration,
                      padding: const EdgeInsets.all(5),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Expanded(
                            flex: 3,
                            child: Image.asset(
                              "${e["asset"]}",
                              color: controller.socialPreferences[e["value"]] ==
                                      true
                                  ? ROOMY_ORANGE
                                  : Colors.grey,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "${e["label"]}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
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
        );

        var descriptionWidget = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InputPageHeader(
                title: "INTRODUCE YOURSELF",
                subtitle:
                    "One last step!\nTell us what makes you great to live with?",
              ),
              const Text(
                "Optional",
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 1,
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    hintText: "Say something about your self",
                  ),
                  initialValue:
                      controller.information["description"] as String?,
                  enabled: controller.isLoading.isFalse,
                  onChanged: (value) =>
                      controller.information["description"] = value,
                  validator: (value) {
                    if (value == null) return null;

                    final (_, message) = validateAdsDescription(value);
                    return message;
                  },
                  minLines: 10,
                  maxLines: 20,
                ),
              ),
              const SizedBox(height: 60),
              const CustomTooltip(
                message: _descriptionTooltipMessage,
              ),
            ],
          ),
        );

        var rentRequirements = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InputPageHeader(
                title: "DESCRIBE YOUR PLACE",
                subtitle: "What are your rent out requirements?",
              ),
              const Divider(),
              const Text(
                "Price",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...[
                (value: "Monthly"),
                (value: "Weekly"),
                (value: "Daily"),
              ].map((e) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.value),
                        const Spacer(),
                        Radio(
                          value: e.value,
                          groupValue: controller.information["rentType"],
                          onChanged: (val) {
                            controller.information["rentType"] = val;
                            controller.update();
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                    if (controller.information["rentType"] == e.value)
                      InlineTextField(
                        suffixText: "AED",
                        hintText: 'Example 3000',
                        initialValue:
                            controller.information["budget"] as String?,
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
                    if (controller.information["rentType"] == e.value)
                      const SizedBox(height: 20),
                  ],
                );
              }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Bill included",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Checkbox(
                    value: controller.information["billIncluded"] as bool?,
                    onChanged: (val) {
                      controller.information["billIncluded"] = val;
                      controller.update();
                    },
                  ),
                ],
              )
            ],
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(oldData == null
                ? "${controller.information["action"] ?? "Choose ad type"}"
                : "Update Ad ${controller.information["action"]}"),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 30,
                    right: 30,
                    top: 10,
                    bottom: 60,
                  ),
                  child: PageView(
                    controller: controller._pageController,
                    onPageChanged: (index) => controller._pageIndex(index),
                    physics: const NeverScrollableScrollPhysics(),
                    children: isNeedRoomPost
                        ? [
                            // personal imformation
                            personalInformation,

                            // Images
                            imagesWidget,

                            // Lifstyle
                            lifeStyleWidget,

                            // Employment
                            employmentWidget,

                            // Astroligical sign
                            astrologicalSignWidget,

                            // Interests
                            interestWidget,

                            // Room type
                            roomtypeWidget,

                            // Preferrences
                            preferenceWidget,

                            // Addresse
                            addressWidget,

                            // Amenities
                            amenitiesWidget,

                            // Social Preferenses

                            socialPreferenceWidget,

                            //Social preferences
                            socialPreferenceWidget2,

                            //Description
                            descriptionWidget,
                          ]
                        : [
                            // Room type
                            roomtypeWidget,

                            // Images
                            imagesWidget,

                            // Rent requirements
                            rentRequirements,

                            // Addresse
                            addressWidget,

                            // Amenities
                            amenitiesWidget,

                            // Social Preferenses

                            socialPreferenceWidget,

                            //Social preferences
                            socialPreferenceWidget2,

                            // personal imformation
                            personalInformation,

                            // Employment
                            employmentWidget,

                            // Astroligical sign
                            astrologicalSignWidget,

                            // Interests
                            interestWidget,

                            //Description
                            descriptionWidget,
                          ],
                  ),
                ),
                if (controller.isLoading.isTrue) const LoadingPlaceholder(),
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
                          if (isNeedRoomPost) {
                            switch (controller._pageIndex.value) {
                              case 1:
                                if (controller.images.isEmpty &&
                                    controller.oldImages.isEmpty) {
                                  showToast(
                                      "Please provide at least one image");
                                  return;
                                }
                                controller._moveToNextPage();

                                break;
                              case 6:
                                if (controller.information["type"] == null) {
                                  showToast("Please choose an option");
                                } else {
                                  controller._moveToNextPage();
                                }
                                break;
                              case 7:
                                if (controller.information["budget"] == null) {
                                  showToast("Please add budget");
                                } else {
                                  controller._moveToNextPage();
                                }
                                break;
                              case 8:
                                if (controller.address["city"] == null) {
                                  showToast("Please select city");
                                } else if (controller.address["location"] ==
                                    null) {
                                  showToast("Please select  area");
                                } else {
                                  controller._moveToNextPage();
                                }
                                break;
                              case 12:
                                controller.saveAd();
                                break;
                              default:
                                controller._moveToNextPage();
                            }
                          } else {
                            switch (controller._pageIndex.value) {
                              case 0:
                                if (controller.information["type"] == null) {
                                  showToast("Please choose an option");
                                } else {
                                  controller._moveToNextPage();
                                }
                                break;
                              case 1:
                                if (controller.images.isEmpty &&
                                    controller.oldImages.isEmpty) {
                                  showToast(
                                      "Please provide at least one image");
                                  return;
                                }
                                controller._moveToNextPage();

                                break;
                              case 2:
                                if (controller.information["budget"] == null) {
                                  showToast("Please add budget");
                                } else {
                                  controller._moveToNextPage();
                                }
                                break;
                              case 3:
                                if (controller.address["city"] == null) {
                                  showToast("Please select city");
                                } else if (controller.address["location"] ==
                                    null) {
                                  showToast("Please select  area");
                                } else {
                                  controller._moveToNextPage();
                                }
                                break;
                              case 11:
                                controller.saveAd();
                                break;
                              default:
                                controller._moveToNextPage();
                            }
                          }
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

class InputPageHeader extends StatelessWidget {
  const InputPageHeader({super.key, this.title, this.subtitle});
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
        ],
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

const _needRoomImagetoolTiptext =
    "By adding your pictures, you'll make it easier for others to "
    "recognize you:) Your pictures will be securely stored within the app and "
    "will only be visible to other app users if you choose to share them ";

const _haveRoomImagetoolTiptext =
    "Upload photos in the order that you would like it "
    "to appear on your listing. Ex: upload best images of your "
    "room first";

const _descriptionTooltipMessage =
    "Tell your potential roommates a little about yourself."
    " What do you do in your free time at home, what do you like to"
    " do for fun. Also, remember to let them know what you are"
    " looking for in them & in your desired place:)";

// void _log(data) => print("[ POST_ROOMMATE ] : $data");
void _log(_) {}
