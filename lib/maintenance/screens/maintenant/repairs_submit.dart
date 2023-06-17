import 'dart:io';

import 'package:jiffy/jiffy.dart';
import "package:path/path.dart" as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/components/image_grid.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:uuid/uuid.dart';

import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/maintenance.dart';
import 'package:roomy_finder/maintenance/screens/request/add_note_and_picture.dart';

class RepairsSubmitsScreen extends StatefulWidget {
  const RepairsSubmitsScreen({super.key, required this.request});

  final Maintenance request;

  @override
  State<RepairsSubmitsScreen> createState() => _RepairsSubmitsScreenState();
}

class _RepairsSubmitsScreenState extends State<RepairsSubmitsScreen> {
  bool _isLoading = false;

  Maintenance get m => widget.request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Repair Submits"),
        actions: [
          if (m.isMeMaintenant && m.isOffered)
            IconButton(
              tooltip: "New Submit",
              onPressed: () {
                Get.to(() => AddNoteAndPictureScreen(onSaved: _addNewSubmit));
              },
              icon: const Icon(Icons.add),
            )
        ],
      ),
      body: Stack(
        children: [
          if (widget.request.submits.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: Text("No data")),
            )
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(5),
              child: Column(
                children: widget.request.submits.map((e) {
                  final maintenantDate = DateTime.parse(e["maintenantDate"]);
                  final landlordDate =
                      DateTime.tryParse(e["landlordDate"] ?? "");
                  return Container(
                    decoration: BoxDecoration(border: Border.all(width: 1)),
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DefaultTextStyle.merge(
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Maintenant"),
                              Text(Jiffy.parseFromDateTime(maintenantDate)
                                  .yMMMEdjm),
                            ],
                          ),
                        ),
                        const Divider(height: 5),
                        if (e["maintenantNote"] == null)
                          const Text(
                            "No submission note",
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Text(e["maintenantNote"]),
                        ImageGrid(
                          images: List<String>.from(e["maintenantImages"]),
                          title: "Repair submit images",
                        ),
                        // Landlord

                        if (e["landlordDate"] != null) ...[
                          const Divider(height: 5),
                          DefaultTextStyle.merge(
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Landlord"),
                                if (e["landlordDate"] != null)
                                  if (e["approvedByLandlord"])
                                    const Icon(Icons.check, color: Colors.green)
                                  else
                                    const Icon(Icons.cancel, color: Colors.red),
                                if (landlordDate != null)
                                  Text(Jiffy.parseFromDateTime(landlordDate)
                                      .yMMMEdjm),
                              ],
                            ),
                          ),
                          const Divider(height: 5),
                          if (e["landlordNote"] == null)
                            const Text(
                              "No landlord submission note",
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            Text(e["landlordNote"]),
                          ImageGrid(
                            images: List<String>.from(e["landlordImages"]),
                            title: "Repair submit images (landlord)",
                          ),
                        ],

                        if (e["landlordDate"] == null && m.isMine) ...[
                          const Divider(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 35,
                                child: TextButton(
                                  onPressed: () {
                                    Get.to(() {
                                      return AddNoteAndPictureScreen(
                                        onSaved: (description, images) {
                                          _replySubmit(
                                            description,
                                            images,
                                            false,
                                            e["id"],
                                          );
                                        },
                                      );
                                    });
                                  },
                                  child: const Text("Reject"),
                                ),
                              ),
                              SizedBox(
                                height: 35,
                                child: TextButton(
                                  onPressed: () {
                                    Get.to(() {
                                      return AddNoteAndPictureScreen(
                                        onSaved: (description, images) {
                                          _replySubmit(
                                            description,
                                            images,
                                            true,
                                            e["id"],
                                          );
                                        },
                                      );
                                    });
                                  },
                                  child: const Text("Approve"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Future<void> _replySubmit(
    String description,
    List<XFile> images,
    bool approved,
    String submitId,
  ) async {
    final confirm = await showConfirmDialog("Please confirm");

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);

      List<String> imagesUrls = [];

      final Map<String, dynamic> data = {
        "approvedByLandlord": approved,
        "submitId": submitId,
      };

      if (description.trim().isNotEmpty) data["landlordNote"] = description;

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

      data["landlordImages"] = imagesUrls;

      final res = await ApiService.getDio.post(
        "/maintenances/${widget.request.id}/reply-submit",
        data: data,
      );

      if (res.statusCode == 200) {
        showToast("Operation completed");
        setState(() {
          final submit = widget.request.submits
              .firstWhereOrNull((e) => e["id"] == submitId);
          if (submit != null) {
            submit["approvedByLandlord"] = approved;
            submit["landlordNote"] = description;
            submit["landlordImages"] = imagesUrls;
            submit["landlordDate"] = DateTime.now().toIso8601String();
          }

          if (approved) widget.request.status = "Completed";
        });
      } else {
        showToast("Operation failed. Please try again");
      }
    } catch (e) {
      Get.log("$e");
      showToast("Operation failed. Please try again");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewSubmit(String description, List<XFile> images) async {
    try {
      setState(() => _isLoading = true);

      List<String> imagesUrls = [];

      final data = {};

      if (description.trim().isNotEmpty) data["maintenantNote"] = description;

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

      data["maintenantImages"] = imagesUrls;

      final res = await ApiService.getDio.post(
        "/maintenances/${widget.request.id}/submit-work",
        data: data,
      );

      if (res.statusCode == 200) {
        showToast("Operation completed");
        setState(() {
          widget.request.submits.add(res.data);
        });
      } else {
        showToast("Operation failed. Please try again");
      }
    } catch (e) {
      showToast("Operation failed. Please try again");
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
