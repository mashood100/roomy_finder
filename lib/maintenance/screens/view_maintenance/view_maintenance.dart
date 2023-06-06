import 'dart:io';
import 'dart:math' as math;

import "package:path/path.dart" as path;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/functions/delete_file_from_url.dart';
import 'package:roomy_finder/maintenance/helpers/show_dialog.dart';
import 'package:uuid/uuid.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/inputs.dart';
import 'package:roomy_finder/components/maintenance_button.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/maintenance/helpers/get_sub_category_icon.dart';
import 'package:roomy_finder/maintenance/helpers/maintenance.dart';
import 'package:roomy_finder/maintenance/screens/request/add_note_and_picture.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';

class ViewMaintenance extends StatefulWidget {
  const ViewMaintenance({super.key, required this.maintenance});

  final Maintenance maintenance;

  @override
  State<ViewMaintenance> createState() => _ViewMaintenanceState();
}

class _ViewMaintenanceState extends State<ViewMaintenance> {
  bool _isLoading = false;

  late final List<Map<String, Object?>> _offers;

  final List<XFile> _images = [];
  String? _description;

  final _budgetsFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    _offers = widget.maintenance.tasks.map((e) {
      return {
        "name": e.name,
        "quantity": e.quantity,
        "budget": null,
        "materialIncluded": false,
        "subCategory": e.subCategory,
      };
    }).toList();
    super.initState();
  }

  void _viewImage(String e) {
    Get.to(transition: Transition.zoom, () {
      return ViewImages(
        images: widget.maintenance.images
            .map((e) => CachedNetworkImageProvider(e))
            .toList(),
        initialIndex: widget.maintenance.images.indexOf(e),
        title: "Maintenance pictures",
      );
    });
  }

  Maintenance get maintenance => widget.maintenance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Maintenance")),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "SCHEDULED FOR:",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Center(
                    child: Text(
                      Jiffy(widget.maintenance.date)
                          .format("MMM.d")
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  Center(
                    child: Text(
                      Jiffy(widget.maintenance.date).EEEE.toUpperCase(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Center(
                    child: Text(
                      Jiffy(widget.maintenance.date).jm,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Center(
                    child: Image.asset(
                      getCategoryIconsAsset(widget.maintenance.category),
                      height: 50,
                      width: 50,
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.maintenance.category.toUpperCase(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Transform.rotate(
                          angle: math.pi / 7,
                          child: const Divider(),
                        ),
                      ),
                      Expanded(
                        child: Transform.rotate(
                          angle: -math.pi / 7,
                          child: const Divider(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                      "Country : ${AppController.instance.country.value.name}"),
                  Text("City : ${widget.maintenance.address["city"]}"),
                  Text("Location : ${widget.maintenance.address["location"]}"),
                  Text(
                      "Tower name : ${widget.maintenance.address["buildingName"]}"),
                  Text(
                      "Floor number : ${widget.maintenance.address["floorNumber"]}"),
                  const Divider(height: 20),
                  const Text("NOTE & IMAGES"),
                  if (widget.maintenance.description != null)
                    Text(widget.maintenance.description!),
                  if (widget.maintenance.images.isNotEmpty)
                    GridView.count(
                      crossAxisCount: Get.width > 370 ? 4 : 3,
                      crossAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: widget.maintenance.images.map((e) {
                        return GestureDetector(
                          onTap: () => _viewImage(e),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: e,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    const Text(
                      "No images",
                      style: TextStyle(color: Colors.grey),
                    ),
                  const Divider(),

                  // Budgets form
                  Form(
                      key: _budgetsFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _offers.map((e) {
                          return Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      getSubCategoryIconsAsset(
                                            maintenance.category,
                                            e["subCategory"] as String,
                                          ) ??
                                          "assets/icons/notification.png",
                                      height: 40,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${e["subCategory"]}",
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text("${e["name"]} (${e["quantity"]})"),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text("Enter Your Budget"),
                                        // Budget
                                        SizedBox(
                                          width: Get.width * 0.5,
                                          child: InlineTextField(
                                            labelWidth: 0,
                                            hintText: "Budget",
                                            suffixText: "AED",
                                            enabled: !_isLoading,
                                            onChanged: (value) =>
                                                e["budget"] = value,
                                            labelStyle: const TextStyle(
                                              fontSize: 15,
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
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
                                        ),
                                      ],
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text("Materials"),
                                        const Text(
                                          "Included   Not Included",
                                          style: TextStyle(fontSize: 10),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio(
                                              value: e["materialIncluded"],
                                              groupValue: true,
                                              onChanged: (value) {
                                                setState(() {
                                                  e["materialIncluded"] = true;
                                                });
                                              },
                                            ),
                                            Radio(
                                              value: e["materialIncluded"],
                                              groupValue: false,
                                              onChanged: (value) {
                                                setState(() {
                                                  e["materialIncluded"] = false;
                                                });
                                              },
                                            ),
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                                const Divider(),
                              ],
                            ),
                          );
                        }).toList(),
                      )),
                  const SizedBox(height: 10),
                  const Text("PAYMENT METHOD "),
                  ListTile(title: Text(widget.maintenance.paymentMethod)),
                  if (widget.maintenance.paymentMethod != "CASH")
                    const Text(
                      "Note : you can withdraw your money after 24 hours from Fix date",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  const Divider(height: 20),
                  MaintenanceButton(
                    width: double.infinity,
                    label: "Add Note & Picture",
                    onPressed: () {
                      Get.to(() => AddNoteAndPictureScreen(
                            onSaved: (note, pictures) {
                              _description = note;
                              _images.clear();
                              _images.addAll(pictures);
                            },
                            initialNote: _description,
                            initialPictures: _images,
                          ));
                    },
                  ),
                  const SizedBox(height: 20),
                  MaintenanceButton(
                    width: double.infinity,
                    label: "Send Offer",
                    onPressed: _sendOffer,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator()
        ],
      ),
    );
  }

  void _sendOffer() async {
    if (_budgetsFormKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    List<String> imagesUrls = [];

    try {
      final Map<String, Object?> data = {
        "tasks": _offers.map((e) {
          return {
            "name": e["name"],
            "budget": e["budget"],
            "materialIncluded": e["materialIncluded"],
          };
        }).toList(),
      };
      if (_description != null && _description!.trim().isNotEmpty) {
        data["description"] = _description;
      }

      final imagesTaskFuture = _images.map((e) async {
        final imgRef = FirebaseStorage.instance
            .ref()
            .child('images')
            .child('/${const Uuid().v4()}${path.extension(e.path)}');

        final uploadTask = imgRef.putData(await File(e.path).readAsBytes());

        final imageUrl = await (await uploadTask).ref.getDownloadURL();

        return imageUrl;
      }).toList();

      imagesUrls = await Future.wait(imagesTaskFuture);

      data["images"] = imagesUrls;

      final res = await ApiService.getDio
          .post("/maintenances/${widget.maintenance.id}/offers", data: data);

      if (res.statusCode == 200) {
        setState(() => _isLoading = false);
        await showFinishedDialog("Your Request have been  Sent");
        Get.back();
      } else {
        Get.log("${res.data}");

        deleteManyFilesFromUrl(imagesUrls);
        showToast("Failed to save maintenance");
      }
    } catch (e) {
      Get.log("$e");
      deleteManyFilesFromUrl(imagesUrls);
      showToast("Failed to save maintenance");
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
