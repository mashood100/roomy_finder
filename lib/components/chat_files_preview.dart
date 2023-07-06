import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:roomy_finder/classes/file_helprer.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/models/chat_message_v2.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';
// import 'package:roomy_finder/screens/new_chat/helper.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as path;

class ChatMessgeFilesPreviewGroup extends StatelessWidget {
  const ChatMessgeFilesPreviewGroup({
    super.key,
    required this.files,
    required this.height,
    required this.width,
  });

  final List<ChatFile> files;
  final double height;
  final double width;

  Future<void> onFileTap(int index) async {
    var file = files[index];
    var path = await FileHelper.getPossibleLocalPath(Uri.parse(file.url));

    if (file.isImage) {
      Get.to(() {
        return ViewImages(
          images: [FileImage(File(path))],
        );
      });
    } else {
      OpenFilex.open(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox();

    final count = files.length > 4 ? 4 : files.length;

    return GridView.count(
      crossAxisCount: files.length == 1 ? 1 : 2,
      childAspectRatio: files.length == 2 ? 0.5 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: files.getRange(0, count).map((e) {
        var index = files.indexOf(e);
        return Hero(
          tag: e.id,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: ChatMessgeFilePreview(
                  file: e,
                  onTap: () => onFileTap(index),
                ),
              ),
              if (index == count - 1 && files.length > 4)
                TextButton(
                  onPressed: () {
                    // Get.to(() => ViewManyChatFiles(files: files));
                  },
                  child: Text(
                    "+ ${files.length - count}",
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class ChatMessgeFilePreview extends StatefulWidget {
  const ChatMessgeFilePreview({
    super.key,
    required this.file,
    this.onTap,
  });

  final ChatFile file;

  final void Function()? onTap;

  @override
  State<ChatMessgeFilePreview> createState() => _ChatMessgeFilePreviewState();
}

class _ChatMessgeFilePreviewState extends State<ChatMessgeFilePreview> {
  late int totalSize;
  int recievedSize = 0;
  bool isDownloading = false;
  bool downloadFinished = false;
  String? localPath;

  ChatFile get file => widget.file;
  String get extension =>
      path.extension(file.name).replaceFirst('.', '').toUpperCase();

  @override
  void initState() {
    super.initState();

    totalSize = widget.file.size;
    Future.delayed(const Duration(microseconds: 0), () async {
      var path = await FileHelper.getPossibleLocalPath(Uri.parse(file.url));

      if (File(path).existsSync()) {
        localPath = path;

        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future<void> downloadFile() async {
    try {
      setState(() => isDownloading = true);

      localPath = await FileHelper.downloadFileFromUri(
        Uri.parse(file.url),
        (p, t) => setState(() {
          recievedSize = p;
          totalSize = t;
        }),
      );
      isDownloading = false;
      downloadFinished = true;
    } catch (e, trace) {
      isDownloading = false;
      Get.log("$e");
      Get.log("$trace");
    } finally {
      setState(() {});
    }
  }

  Future<void> handleFileTapped() async {
    await OpenFilex.open(localPath);
  }

  @override
  Widget build(BuildContext context) {
    if (localPath != null) {
      return GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            handleFileTapped();
          }
        },
        child: Builder(builder: (context) {
          if (localPath!.isImageFileName) {
            return LoadingProgressImage(
              image: FileImage(File(localPath!)),
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              borderRadius: 5,
            );
          }

          if (localPath!.isVideoFileName) {
            return Stack(
              alignment: Alignment.center,
              children: [
                FutureBuilder(
                  builder: (ctx, asp) {
                    if (asp.hasData) {
                      return LoadingProgressImage(
                        image: MemoryImage(asp.data!),
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                      );
                    }
                    return FileExtPlaceholder(
                      file: file,
                    );
                  },
                  future: VideoThumbnail.thumbnailData(
                    video: widget.file.url,
                    quality: 50,
                  ),
                ),
                const Icon(Icons.play_arrow, size: 40, color: Colors.white),
              ],
            );
          }

          return FileExtPlaceholder(
            file: file,
          );
        }),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Builder(builder: (context) {
          if (widget.file.isImage) {
            if (widget.file.haveThumbnail) {
              return LoadingProgressImage(
                image: CachedNetworkImageProvider(widget.file.thumbnail!),
                fit: BoxFit.cover,
              );
            }
          }
          if (widget.file.isVideo) {
            return Stack(
              alignment: Alignment.center,
              children: [
                FutureBuilder(
                  builder: (ctx, asp) {
                    if (asp.hasData) {
                      return LoadingProgressImage(
                        image: MemoryImage(asp.data!),
                        fit: BoxFit.cover,
                      );
                    }
                    return FileExtPlaceholder(
                      file: file,
                    );
                  },
                  future: VideoThumbnail.thumbnailData(
                    video: widget.file.url,
                    quality: 50,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Icon(
                        Icons.video_collection_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(file.sizeText, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            );
          }
          return FileExtPlaceholder(
            file: file,
          );
        }),
        if (!isDownloading && !downloadFinished)
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black38,
            ),
            onPressed: isDownloading ? null : downloadFile,
            icon: const Icon(
              Icons.download,
              size: 30,
              color: Colors.blue,
            ),
          ),
        if (isDownloading)
          SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              value: recievedSize == 0 ? null : recievedSize / totalSize,
            ),
          ),
      ],
    );
  }
}

class FileExtPlaceholder extends StatelessWidget {
  const FileExtPlaceholder({
    super.key,
    required this.file,
  });

  String get extension {
    return path.extension(file.name).replaceFirst('.', '').toUpperCase();
  }

  final ChatFile file;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      var isSmall = constraint.biggest.height < 200 ? true : false;
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              extension.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmall ? 18 : 22,
              ),
            ),
            Icon(
              Icons.description_outlined,
              size: isSmall ? 20 : 30,
            ),
            const SizedBox(height: 5),
            Text(file.sizeText, style: TextStyle(fontSize: isSmall ? 12 : 16)),
            Text(
              file.name,
              style: TextStyle(fontSize: isSmall ? 10 : 12),
              textAlign: TextAlign.center,
              maxLines: isSmall ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    });
  }
}

// Chat files preview

class ViewManyChatFiles extends StatelessWidget {
  const ViewManyChatFiles({super.key, required this.files});

  final List<ChatFile> files;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: SingleChildScrollView(
          child: Column(
        children: files.map((e) {
          return Hero(
              tag: e.id,
              child: ChatMessgeFilePreview(
                file: e,
                onTap: e.isImage
                    ? () async {
                        var path = await FileHelper.getPossibleLocalPath(
                            Uri.parse(e.url));
                        Get.to(() {
                          return ViewImages(images: [FileImage(File(path))]);
                        });
                      }
                    : null,
              ));
        }).toList(),
      )),
    );
  }
}
