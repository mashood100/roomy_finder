import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/alert.dart';
import 'package:roomy_finder/components/image_grid.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/components/phone_input.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/data/static.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/data/enums.dart';
import 'package:roomy_finder/functions/city_location.dart';
import 'package:roomy_finder/functions/create_datetime_filename.dart';
import 'package:roomy_finder/functions/firebase_file_helper.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/screens/utility_screens/play_video.dart';
import 'package:roomy_finder/utilities/data.dart';
import "package:path/path.dart" as path;
import 'package:video_thumbnail/video_thumbnail.dart';

part './post_property_ad_controller.dart';

class PostPropertyAdScreen extends StatelessWidget {
  const PostPropertyAdScreen({super.key, this.oldData});
  final PropertyAd? oldData;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_PostPropertyAdController(oldData: oldData));

    const labelStyle = TextStyle(fontWeight: FontWeight.bold);
    int bigSizeGridCount = MediaQuery.sizeOf(context).width ~/ 150;
    int smallSizeGridCount = MediaQuery.sizeOf(context).width ~/ 100;

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
                    left: 20,
                    right: 20,
                    top: 20,
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
                              const InputPageHeader(
                                title: "DESCRIBE YOUR PROPERTY",
                                subtitle: "Where your property is located?",
                              ),
                              const SizedBox(height: 20),

                              // City
                              const Text("City", style: labelStyle),
                              InlineDropdown<String>(
                                hintText:
                                    AppController.instance.country.value.isUAE
                                        ? 'Example : Dubai'
                                        : "Example : Riyadh",
                                value: controller.address["city"]?.toString(),
                                items: CITIES_FROM_CURRENT_COUNTRY,
                                onChanged: controller.isLoading.isTrue
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          controller.address["location"] = null;
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
                              const Text("Area", style: labelStyle),
                              InlineDropdown<String>(
                                hintText: "Example Al Barsha",
                                value:
                                    controller.address["location"]?.toString(),
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
                              const Text("Tower name", style: labelStyle),
                              InlineTextField(
                                hintText: "Example ABC Tower",
                                enabled: controller.isLoading.isFalse,
                                initialValue: controller.address["buildingName"]
                                    ?.toString(),
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
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 20),

                              // Apartment number
                              const Text("Apartment number", style: labelStyle),
                              InlineTextField(
                                hintText: "Example 456",
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
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 20),

                              // Floor number
                              const Text("Floor number", style: labelStyle),
                              InlineTextField(
                                hintText: "Example 4",
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
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // Property type
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputPageHeader(
                              title: "DESCRIBE YOUR PROPERTY",
                              subtitle: "What is your property type?",
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
                              const InputPageHeader(
                                title: "DESCRIBE YOUR PROPERTY",
                                subtitle:
                                    "How many units are available in your property?",
                              ),

                              const Divider(height: 20),
                              const InputPageHeader(
                                subtitle: "Number of units",
                              ),
                              const SizedBox(height: 20),
                              // Quantity
                              for (var count in [1, 6])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: InlineSelector(
                                    items: List.generate(
                                      5,
                                      (index) => "${index + count}",
                                    ),
                                    value: controller.information["quantity"]
                                        as String?,
                                    onChanged: (value) {
                                      controller.information[
                                          "quantityGreaterThan10"] = false;
                                      controller.information["quantity"] =
                                          value;
                                    },
                                  ),
                                ),

                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "More than 10 units",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Checkbox(
                                    value: controller.information[
                                        "quantityGreaterThan10"] as bool?,
                                    onChanged: (val) {
                                      if (val == false) {
                                        controller.information["quantity"] =
                                            "10";
                                      }
                                      controller.information[
                                          "quantityGreaterThan10"] = val;
                                      controller.update();
                                    },
                                  ),
                                ],
                              ),

                              if (controller
                                      .information["quantityGreaterThan10"] ==
                                  true) ...[
                                InlineTextField(
                                  hintText: 'Enter number of units',
                                  initialValue: controller
                                      .information["quantity"] as String,
                                  enabled: controller.isLoading.isFalse,
                                  onChanged: (value) => controller
                                      .information["quantity"] = value,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'thisFieldIsRequired'.tr;
                                    }
                                    final numValue = int.tryParse(value);

                                    if (numValue == null || numValue < 1) {
                                      return 'Must be greater than 10';
                                    }
                                    if (numValue > 500) {
                                      return 'Quantity must be less than 500'
                                          .tr;
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*'))
                                  ],
                                )
                              ],

                              const SizedBox(height: 20),
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "Number of rooms, beds or partitions available at 1 property",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Pricing
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputPageHeader(
                              title: "DESCRIBE YOUR PLACE",
                              subtitle: "What are your rent out requeriments?",
                            ),

                            const SizedBox(height: 10),

                            const CustomTooltip(
                              message:
                                  "You can set rental prices for different periods,"
                                  " ensuring your properties are occupied at all time.",
                            ),
                            const Divider(),

                            const Text(
                              "Price",
                              style: TextStyle(fontWeight: FontWeight.bold),
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item["label"].toString()),
                                  Checkbox(
                                    value: controller.information[
                                            "${item["value"]}-selected"] ==
                                        true,
                                    onChanged: (val) {
                                      controller.information[
                                          "${item["value"]}-selected"] = val;
                                      if (val != true) {
                                        controller.information[
                                            "${item["value"]}"] = null;
                                      }
                                      controller.update();
                                    },
                                  ),
                                ],
                              ),
                              if (controller.information[
                                      "${item["value"]}-selected"] ==
                                  true)
                                InlineTextField(
                                  hintText: "Enter the ${item["label"]} price",
                                  labelStyle: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                  // labelText: item['label']!,
                                  suffixText:
                                      "AED ${item["label"]!.padLeft(7, " ")}",
                                  initialValue: controller
                                      .information[item['value']] as String?,
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
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        priceRegex)
                                  ],
                                ),
                              const SizedBox(height: 20),
                            ],

                            const CustomTooltip(
                              message:
                                  "Please note that a 10% will be automatically included"
                                  " in the rental price, which will be deducted"
                                  " from the tenant's payment.",
                            ),

                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Deposit",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Checkbox(
                                  value: controller.information["deposit"]
                                      as bool?,
                                  onChanged: (val) {
                                    controller.information["deposit"] = val;
                                    if (val != true) {
                                      controller.information
                                          .remove("depositPrice");
                                    }
                                    controller.update();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (controller.information["deposit"] == true)
                              InlineTextField(
                                hintText: "Enter deposit amount",
                                initialValue:
                                    controller.information["depositPrice"] ==
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
                                  FilteringTextInputFormatter.allow(priceRegex)
                                ],
                              ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Bill included",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Checkbox(
                                  value: controller.information["billIncluded"]
                                      as bool?,
                                  onChanged: (val) {
                                    controller.information["billIncluded"] =
                                        val;
                                    controller.update();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Amenities
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputPageHeader(
                              title: "DESCRIBE YOUR PROPERTY",
                              subtitle:
                                  "What amenities are available at your property?",
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
                                        if (controller.amenities
                                            .contains(e["value"])) {
                                          controller.amenities
                                              .remove(e["value"]);
                                        } else {
                                          controller.amenities
                                              .add("${e["value"]}");
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
                                                color: controller.amenities
                                                        .contains(e["value"])
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
                      ),

                      //Images
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputPageHeader(
                              title: "DESCRIBE YOUR PROPERTY",
                              subtitle: "Add pictures of your property",
                            ),

                            // Images
                            if (controller.images.isEmpty &&
                                controller.oldImages.isEmpty)
                              Center(
                                child: Image.asset(
                                  AssetImages.defaultRoomPNG,
                                  height: 150,
                                ),
                              )
                            else ...[
                              ImageGrid(
                                items: controller.oldImages,
                                getImage: (item) =>
                                    CachedNetworkImageProvider(item),
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
                              future: Future.wait(controller.oldVideos.map(
                                  (e) =>
                                      VideoThumbnail.thumbnailData(video: e))),
                              builder: (context, asp) {
                                if (asp.connectionState ==
                                    ConnectionState.done) {
                                  final data = asp.data!;

                                  return ImageGrid(
                                    items: data,
                                    isVideo: true,
                                    getImage: (item) => MemoryImage(item!),
                                    onItemRemoved: (item) {
                                      controller.oldVideos
                                          .removeAt(data.indexOf(item));
                                      controller.update();
                                    },
                                    noDataMessage: "",
                                    onItemTap: (item) {
                                      controller._playVideo(
                                        controller
                                            .oldVideos[data.indexOf(item)],
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
                                  return VideoThumbnail.thumbnailData(
                                      video: e.path);
                                }),
                              ),
                              builder: (context, asp) {
                                if (asp.connectionState ==
                                    ConnectionState.done) {
                                  final data = asp.data!;

                                  return ImageGrid(
                                    items: data,
                                    isVideo: true,
                                    getImage: (item) => MemoryImage(item!),
                                    onItemRemoved: (item) {
                                      controller.videos
                                          .removeAt(data.indexOf(item));
                                      controller.update();
                                    },
                                    noDataMessage: "",
                                    onItemTap: (item) {
                                      controller._playVideo(
                                        controller
                                            .videos[data.indexOf(item)].path,
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
                            const Center(
                              child: Text(
                                "Show off your place!",
                                style: TextStyle(
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
                                  onPressed: () =>
                                      controller._pickPicture(gallery: false),
                                ),
                                (
                                  label: "Video",
                                  asset: AssetIcons.videoPNG,
                                  onPressed: () => controller._pickVideo(),
                                ),
                              ].map((e) {
                                return OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ROOMY_PURPLE,
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
                            const CustomTooltip(message: _imagetoolTiptext),
                          ],
                        ),
                      ),

                      // Tenant preferences
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputPageHeader(
                              title: "DESCRIBE YOUR PREFFERED TENANT",
                              subtitle: "Who are your preferred tenants?",
                            ),

                            // Gender
                            const Text("Gender"),
                            InlineSelector(
                              items: const ["Male", "Female", "Mix"],
                              value: controller.socialPreferences["gender"],
                              onChanged: (value) {
                                controller.socialPreferences["gender"] = value;
                                controller.update();
                              },
                            ),

                            const SizedBox(height: 20),

                            // Nationality
                            const Text("Nationality"),

                            InlineDropdown<String>(
                              hintText: "Indian",
                              value: controller.socialPreferences["nationality"]
                                  as String?,
                              items: ALL_NATIONALITIES,
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
                            const InputPageHeader(
                              subtitle:
                                  "How many people live at your property now?",
                            ),

                            for (var count in [1, 6])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InlineSelector(
                                  items: List.generate(
                                    5,
                                    (index) => "${index + count}",
                                  ),
                                  value: controller
                                          .socialPreferences["numberOfPeople"]
                                      as String?,
                                  onChanged: (value) {
                                    controller.socialPreferences[
                                        "peopleGreaterThan10"] = false;
                                    controller.socialPreferences[
                                        "numberOfPeople"] = value;
                                  },
                                ),
                              ),

                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "More than 10 people",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Checkbox(
                                  value: controller.socialPreferences[
                                      "peopleGreaterThan10"] as bool?,
                                  onChanged: (val) {
                                    if (val == false) {
                                      controller.socialPreferences[
                                          "numberOfPeople"] = "10";
                                    } else {
                                      controller.socialPreferences[
                                          "numberOfPeople"] = "10+";
                                    }
                                    controller.socialPreferences[
                                        "peopleGreaterThan10"] = val;
                                    controller.update();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Tenant preference 2
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputPageHeader(
                              title: "DESCRIBE YOUR PREFFERED TENANT",
                              subtitle:
                                  "What things would you allow for tenants at your property?",
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
                                    if (controller
                                            .socialPreferences[e["value"]] ==
                                        true) {
                                      controller.socialPreferences[
                                          "${e["value"]}"] = false;
                                    } else {
                                      controller.socialPreferences[
                                          "${e["value"]}"] = true;
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
                                            color: controller.socialPreferences[
                                                        e["value"]] ==
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
                      ),

                      // Description
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const InputPageHeader(
                              title: "DESCRIBE YOUR PROPERTY",
                              subtitle: "Write a description of your property!",
                            ),
                            const Text(
                              "Optional",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: TextFormField(
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
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
                                  hintText: "2 BR apartment with a balcony…",
                                ),
                                initialValue: controller
                                    .information["description"] as String?,
                                enabled: controller.isLoading.isFalse,
                                onChanged: (value) => controller
                                    .information["description"] = value,
                                validator: (value) {
                                  if (value == null) return null;

                                  final (_, message) =
                                      validateAdsDescription(value);
                                  return message;
                                },
                                minLines: 10,
                                maxLines: 20,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const CustomTooltip(
                              message: _descriptionTooltipMessage,
                            ),
                          ],
                        ),
                      ),

                      // Who are you
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            const InputPageHeader(
                              title: "One last step!",
                              subtitle:
                                  "Please tell us if you are a landlord or agent?",
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
                                      color: Colors.black,
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
                                      color: Colors.black,
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
                            else ...[
                              const SizedBox(height: 200),
                              const CustomTooltip(
                                message:
                                    "This will help Roomy FINDER to provide you "
                                    "with more accurate assistance regarding"
                                    " real estate matters.",
                              ),
                            ],
                          ],
                        ),
                      ),
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
                          var info = controller.information;
                          switch (controller._pageIndex.value) {
                            case 0:
                              if (controller._addressFormKey.currentState
                                      ?.validate() ==
                                  true) {
                                controller._moveToNextPage();
                              }
                              break;

                            case 2:
                              if (controller._informationFormKey.currentState
                                      ?.validate() ==
                                  true) {
                                controller._moveToNextPage();
                              }
                              break;
                            case 3:
                              var isValid = info["monthlyPrice"] != null ||
                                  info["weeklyPrice"] != null ||
                                  info["dailyPrice"] != null;

                              if (isValid) {
                                controller._moveToNextPage();
                              } else {
                                showToast("At least one price is required");
                              }
                              break;
                            case 5:
                              if (controller.images.isEmpty &&
                                  controller.oldImages.isEmpty) {
                                showToast("Please provide at least one image");
                                return;
                              }
                              controller._moveToNextPage();

                              break;
                            case 8:
                              if (controller._validateDescription()) {
                                controller._moveToNextPage();
                              }
                              break;

                            case 9:
                              if (controller.information['posterType'] ==
                                  "Agent/Broker") {
                                var isvalid = controller
                                    ._agentBrokerFormKey.currentState
                                    ?.validate();

                                if (isvalid != true) return;
                              }

                              if (oldData != null) {
                                controller._upatePropertyAd();
                              } else {
                                controller._savePropertyAd();
                              }

                              break;
                            default:
                              controller._moveToNextPage();
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

const _imagetoolTiptext =
    "Upload photos in the order that you would like it to "
    "appear on your listing. Ex: upload best images of your room first";

const _descriptionTooltipMessage =
    "Tell your potential tenants about your property "
    "including its additional features, furnishing and any relevant "
    "information to attract more tenants!";
