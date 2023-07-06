import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:roomy_finder/classes/file_helprer.dart';
import 'package:roomy_finder/functions/firebase_file_helper.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as path;

class ChatMessageFileUploadTaskWidget extends StatefulWidget {
  const ChatMessageFileUploadTaskWidget({
    super.key,
    required this.files,
    this.message,
    this.replyId,
    required this.onUploadCompleted,
    required this.onCancel,
    this.fileMetadata,
  });

  final List<File> files;
  final String? message;
  final String? replyId;

  final void Function(
    List<Map<String, Object>> tasks,
    String? message,
    String? replyId,
  ) onUploadCompleted;
  final void Function() onCancel;
  final Map<String, String>? fileMetadata;

  @override
  State<ChatMessageFileUploadTaskWidget> createState() =>
      _ChatMessageFileUploadTaskWidgetState();
}

class _ChatMessageFileUploadTaskWidgetState
    extends State<ChatMessageFileUploadTaskWidget> {
  bool isUploading = false;
  bool haveUploadError = false;

  int currentFileIndex = 0;

  List<File> get files => widget.files;
  final List<Map<String, Object>> result = [];

  @override
  void initState() {
    _uploadFile();
    super.initState();
  }

  Future<void> _uploadFile() async {
    try {
      for (var i = currentFileIndex; i < files.length; i++) {
        var file = files[i];

        setState(() => currentFileIndex = i);

        var task = await uploadFileToStorage(file);

        var url = await task.ref.getDownloadURL();

        String? thumbnail;

        if (file.path.isImageFileName) {
          try {
            var uint8list = await FileHelper.compressImageFile(file);
            if (uint8list != null) {
              var uBasename = path.basenameWithoutExtension(file.path);

              uBasename += '-200x200';
              uBasename = path.setExtension(uBasename, ".jpeg");

              var thumbnailTask =
                  await uploadUnit8ListToStorage(uint8list, uBasename);

              thumbnail = await thumbnailTask.ref.getDownloadURL();
            } else {}
          } catch (e, trace) {
            Get.log("$e");
            Get.log("$trace");
          }
        }

        var map = {
          "name": basename(file.path),
          "url": url,
          "size": task.bytesTransferred,
        };

        if (thumbnail != null) map["thumbnail"] = thumbnail;

        result.add(map);
      }

      widget.onUploadCompleted(result, widget.message, widget.replyId);
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      haveUploadError = true;
    } finally {
      setState(() {});
    }
  }

  void cancelledUploads() {
    deleteManyFilesFromUrl(result.map((e) => "${e["url"]}").toList());
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          createFilePreviewWidget(files.first, 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  basename(files[currentFileIndex].path),
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Sending ${currentFileIndex + 1}/${files.length}",
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (haveUploadError) const Icon(Icons.error, color: Colors.red),
          IconButton(
            onPressed: isUploading ? null : cancelledUploads,
            icon: Builder(builder: (context) {
              if (isUploading) {
                return const SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              if (haveUploadError) return const Icon(Icons.refresh);
              return const Icon(Icons.close, color: Colors.red);
            }),
          ),
        ],
      ),
    );
  }
}

Widget createFilePreviewWidget(
  File file, [
  double width = 60,
  double height = 60,
  bool showExtension = true,
]) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(5),
    child: Builder(builder: (context) {
      if (file.path.isImageFileName) {
        return Image.file(
          file,
          height: height,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, trace) {
            return Container(
              color: Colors.grey,
              height: height,
              width: width,
              child: const Icon(Icons.image),
            );
          },
        );
      } else if (file.path.isVideoFileName) {
        return FutureBuilder(
          builder: (ctx, asp) {
            if (asp.hasData) {
              return Image.memory(
                asp.data!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                height: height,
                width: width,
              );
            }
            return Container();
          },
          future: VideoThumbnail.thumbnailData(
            video: file.path,
          ),
        );
      } else {
        final type = extension(file.path).replaceFirst('.', '').toUpperCase();
        return Container(
          alignment: Alignment.center,
          color: Colors.grey,
          height: height,
          width: width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showExtension)
                Text(
                  type,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width / 8.5,
                  ),
                ),
              Icon(
                Icons.description_outlined,
                size: width / 3,
              ),
            ],
          ),
        );
      }
    }),
  );
}

Future<List<File>?> filterMediaFiles(List<File> files) async {
  final filter = await showModalBottomSheet(
    context: Get.context!,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    builder: (context) {
      int selectedIndex = 0;
      return Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.8),
        padding: const EdgeInsets.all(8.0),
        child: StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Get.back(),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Text("${selectedIndex + 1}/${files.length}"),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => Get.back(result: files),
                    child: const Text(
                      "Send",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const Divider(),
              if (selectedIndex < files.length)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Builder(builder: (context) {
                      var f = files[selectedIndex];
                      if (f.path.isImageFileName) {
                        return Image.file(
                          f,
                          height: Get.height * 0.5,
                          alignment: Alignment.center,
                        );
                      } else if (f.path.isVideoFileName) {
                        return FutureBuilder(
                          builder: (ctx, asp) {
                            if (asp.hasData) {
                              return Image.memory(
                                asp.data!,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                height: Get.height * 0.5,
                              );
                            }
                            return Container();
                          },
                          future: VideoThumbnail.thumbnailData(
                            video: f.path,
                          ),
                        );
                      }

                      return createFilePreviewWidget(f, 200, 200);
                    }),
                  ),
                ),
              if (selectedIndex < files.length)
                Text(
                  basename(files[selectedIndex].path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const Divider(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: files.map((e) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: selectedIndex == files.indexOf(e)
                          ? const EdgeInsets.all(3)
                          : null,
                      decoration: BoxDecoration(
                        border: selectedIndex == files.indexOf(e)
                            ? Border.all(width: 1, color: Colors.blue)
                            : null,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex = files.indexOf(e);
                              });
                            },
                            child: createFilePreviewWidget(
                                e,
                                selectedIndex == files.indexOf(e) ? 77 : 80,
                                selectedIndex == files.indexOf(e) ? 77 : 80),
                          ),
                          GestureDetector(
                            onTap: () {
                              files.remove(e);
                              if (files.isEmpty) Get.back();

                              if (selectedIndex > 0) {
                                selectedIndex--;
                              }

                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Icon(Icons.cancel, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          );
        }),
      );
    },
  );

  if (filter is List<File>?) return filter;
  return null;
}
