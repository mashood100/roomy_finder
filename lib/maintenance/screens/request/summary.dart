// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:roomy_finder/components/maintenance_button.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/maintenance.dart';
import 'package:roomy_finder/maintenance/screens/request/add_note_and_picture.dart';
import 'package:roomy_finder/maintenance/screens/request/choose_maitenance.dart';
import 'package:roomy_finder/maintenance/screens/request/select_date_time.dart';

class RequestSummaryScreen extends StatefulWidget {
  const RequestSummaryScreen({
    super.key,
    required this.request,
  });

  final PostMaintenanceRequest request;

  @override
  State<RequestSummaryScreen> createState() => _RequestSummaryScreenState();
}

class _RequestSummaryScreenState extends State<RequestSummaryScreen> {
  void _allMoreItem() {
    Get.to(() {
      return ChooseMaintenanceScreen(
        category: widget.request.category,
        onFinished: (subCategory, maintenance) {
          var maintenanceEntry = MaintenanceEntry(
            subCategory: subCategory,
            name: maintenance,
            quantity: 1,
          );
          if (!widget.request.maintenances.contains(maintenanceEntry)) {
            widget.request.maintenances.add(maintenanceEntry);
          } else {
            showToast("Item already exist");
          }

          setState(() {});
        },
      );
    });
  }

  void _editItem(MaintenanceEntry item) {
    Get.to(() {
      return ChooseMaintenanceScreen(
        category: widget.request.category,
        onFinished: (subCategory, maintenance) {
          final index = widget.request.maintenances.indexOf(item);

          if (index >= 0) {
            widget.request.maintenances[index] = MaintenanceEntry(
              subCategory: subCategory,
              name: maintenance,
              quantity: 1,
            );
          }

          setState(() {});
        },
      );
    });
  }

  void _deleteItem(MaintenanceEntry item) {
    widget.request.maintenances.remove(item);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SUMMARY")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 200, left: 10, right: 10),
        child: Column(
          children: widget.request.maintenances.map((e) {
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      e.getIcon(widget.request.category),
                      const SizedBox(width: 10),
                      Text(e.subCategory),
                      const Spacer(),
                      SizedBox(
                        height: 40,
                        child: TextButton(
                          onPressed: () => _editItem(e),
                          child: const Text('Edit'),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: TextButton(
                          onPressed: () => _deleteItem(e),
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                  Text(e.name.toUpperCase()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: e.quantity <= 1
                            ? null
                            : () {
                                if (e.quantity > 1) {
                                  e.quantity--;
                                  setState(() {});
                                }
                              },
                        icon: const Icon(
                          Icons.remove_circle_outline,
                        ),
                      ),
                      Text(
                        "Quantity (${e.quantity})",
                        style: const TextStyle(fontWeight: FontWeight.w100),
                      ),
                      IconButton(
                        onPressed: () {
                          e.quantity++;
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.add_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MaintenanceButton(
              width: double.infinity,
              label: "Add Note & Picture",
              onPressed: () {
                Get.to(() => AddNoteAndPictureScreen(
                      onSaved: (note, pictures) {
                        widget.request.description = note;
                        widget.request.images.clear();
                        widget.request.images.addAll(pictures);
                      },
                      initialNote: widget.request.description,
                      initialPictures: widget.request.images,
                    ));
              },
            ),
            const SizedBox(height: 10),
            MaintenanceButton(
              width: double.infinity,
              label: "Add More Items",
              onPressed: _allMoreItem,
            ),
            const SizedBox(height: 10),
            MaintenanceButton(
              width: double.infinity,
              label: "Continue",
              onPressed: () {
                if (widget.request.maintenances.isNotEmpty) {
                  Get.to(() {
                    return SelectDateAndTimeScreen(request: widget.request);
                  });
                } else {
                  showToast("Please select atleast one maintenance");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
