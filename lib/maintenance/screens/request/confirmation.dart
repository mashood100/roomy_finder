import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_storage/firebase_storage.dart';
import "package:path/path.dart" as path;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/functions/delete_file_from_url.dart';
import 'package:uuid/uuid.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/maintenance_button.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/maintenance/helpers/get_sub_category_icon.dart';
import 'package:roomy_finder/maintenance/helpers/maintenance.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key, required this.request});

  final PostMaintenanceRequest request;

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _isLoading = false;

  void _viewImage(XFile e) {
    Get.to(transition: Transition.zoom, () {
      return ViewImages(
        images:
            widget.request.images.map((e) => FileImage(File(e.path))).toList(),
        initialIndex: widget.request.images.indexOf(e),
        title: "Maintenance pictures",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CONFIRMATION")),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                    Jiffy(widget.request.date).format("MMM.d").toUpperCase(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                Center(
                  child: Text(
                    Jiffy(widget.request.date).EEEE.toUpperCase(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Center(
                  child: Text(
                    Jiffy(widget.request.date).jm,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Center(
                  child: Image.asset(
                    getCategoryIconsAsset(widget.request.category),
                    height: 50,
                    width: 50,
                  ),
                ),
                Center(
                  child: Text(
                    widget.request.category.toUpperCase(),
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
                Text("Country : ${AppController.instance.country.value.name}"),
                Text("City : ${widget.request.address["city"]}"),
                Text("Location : ${widget.request.address["location"]}"),
                Text("Tower name : ${widget.request.address["buildingName"]}"),
                Text("Floor number : ${widget.request.address["floorNumber"]}"),
                const Divider(height: 20),
                const Text("NOTE & IMAGES"),
                if (widget.request.description != null)
                  Text(widget.request.description!),
                if (widget.request.images.isNotEmpty)
                  GridView.count(
                    crossAxisCount: Get.width > 370 ? 4 : 3,
                    crossAxisSpacing: 10,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: widget.request.images.map((e) {
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
                            child: Image.file(
                              File(e.path),
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
                const Text("PAYMENT METHOD "),
                ...["VISA OR CREDIT CARD", "PAYPAL", 'CASH'].map((e) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => widget.request.paymentMethod = e),
                        child: Row(
                          children: [
                            Radio(
                              value: e,
                              groupValue: widget.request.paymentMethod,
                              onChanged: (val) => setState(
                                  () => widget.request.paymentMethod = val),
                            ),
                            Text(e),
                          ],
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 40),
                MaintenanceButton(
                  width: double.infinity,
                  label: "Continue",
                  onPressed: _saveMaintenance,
                )
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator()
        ],
      ),
    );
  }

  void _saveMaintenance() async {
    if (widget.request.paymentMethod == null) {
      showToast("Please choose payment method");
      return;
    }

    setState(() => _isLoading = true);

    List<String> imagesUrls = [];

    try {
      widget.request.address["countryCode"] =
          AppController.instance.country.value.code;

      final data = {
        "category": widget.request.category,
        "tasks": widget.request.maintenances.map((e) {
          return {
            "name": e.name,
            "quantity": e.quantity,
            "subCategory": e.subCategory
          };
        }).toList(),
        "date": widget.request.date.toIso8601String(),
        "paymentMethod": widget.request.paymentMethod,
      };

      if (widget.request.description?.isNotEmpty == true) {
        data["description"] = widget.request.description;
      }

      widget.request.address["country"] =
          AppController.instance.country.value.name;
      data["address"] = widget.request.address;

      final imagesTaskFuture = widget.request.images.map((e) async {
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

      final res = await ApiService.getDio.post("/maintenances", data: data);

      if (res.statusCode == 201) {
        setState(() => _isLoading = false);
        // ignore: use_build_context_synchronously
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: Container(
                height: Get.height * 0.7,
                width: Get.width * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 40,
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "Your Request have been  Sent",
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {
                        Get.until(
                            (route) => Get.currentRoute == '/maintenance');
                      },
                      child: const Text("Done"),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        deleteManyFilesFromUrl(imagesUrls);
        showToast("Failed to save maintenance");
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      deleteManyFilesFromUrl(imagesUrls);
      showToast("Failed to save maintenance");
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
