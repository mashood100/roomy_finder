import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roomy_finder/components/maintenance_button.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';

class AddNoteAndPictureScreen extends StatefulWidget {
  const AddNoteAndPictureScreen({
    super.key,
    this.onSaved,
    this.initialNote,
    this.initialPictures,
  });
  final void Function(String note, List<XFile> pictures)? onSaved;

  final String? initialNote;
  final List<XFile>? initialPictures;

  @override
  State<AddNoteAndPictureScreen> createState() =>
      _AddNoteAndPictureScreenState();
}

class _AddNoteAndPictureScreenState extends State<AddNoteAndPictureScreen> {
  String note = "";
  late TextEditingController _noteController;
  final _images = <XFile>[];

  @override
  void initState() {
    _noteController = TextEditingController(text: widget.initialNote);
    if (widget.initialPictures != null && widget.initialPictures!.isNotEmpty) {
      _images.addAll(widget.initialPictures!);
    }
    super.initState();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPicture({bool gallery = true}) async {
    if (_images.length >= 10) return;

    try {
      final ImagePicker picker = ImagePicker();

      if (gallery) {
        final data = await picker.pickMultiImage();
        final sumImages = [..._images, ...data];
        _images.clear();
        if (sumImages.length <= 10) {
          _images.addAll(sumImages);
        } else {
          _images.addAll(sumImages.sublist(0, 9));
        }
      } else {
        final image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) _images.add(image);
      }
    } catch (e) {
      Get.log("$e");
      showToast('someThingWhenWrong'.tr);
    } finally {
      setState(() {});
    }
  }

  void _viewImage(XFile e) {
    Get.to(transition: Transition.zoom, () {
      return ViewImages(
        images: _images.map((e) => FileImage(File(e.path))).toList(),
        initialIndex: _images.indexOf(e),
        title: "Maintenance pictures",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Note & Picture")),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("NOTE"),
                  // Text("${_noteController.text.length}/500"),
                ],
              ),
              TextField(
                controller: _noteController,
                maxLength: 500,
                onChanged: (value) => note = value,
                minLines: 6,
                maxLines: 20,
                decoration: const InputDecoration(
                  hintText: 'Text',
                ),
              ),
              const Divider(),
              if (_images.isEmpty)
                Card(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    height: 150,
                    child: const Text("ADD PICTURE"),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: Get.width > 370 ? 4 : 3,
                  crossAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: _images.map((e) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        GestureDetector(
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
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _images.remove(e)),
                          child: const Icon(Icons.remove_circle,
                              color: Colors.red),
                        )
                      ],
                    );
                  }).toList(),
                ),
              Row(
                children: [
                  SizedBox(
                    height: 35,
                    child: ElevatedButton.icon(
                      onPressed:
                          _images.length >= 10 ? null : () => _pickPicture(),
                      icon: const Icon(Icons.image),
                      label: const Text(
                        "Images",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 35,
                    child: ElevatedButton.icon(
                      onPressed: _images.length >= 10
                          ? null
                          : () => _pickPicture(gallery: false),
                      icon: const Icon(Icons.camera),
                      label: const Text(
                        "Camera",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MaintenanceButton(
                width: double.infinity,
                label: "Save",
                onPressed: () {
                  Get.back();
                  widget.onSaved!(_noteController.text, _images);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
