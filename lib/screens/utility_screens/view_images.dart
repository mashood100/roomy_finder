import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ViewImages extends StatefulWidget {
  const ViewImages({
    super.key,
    required this.images,
    this.title,
    this.initialIndex = 0,
  });
  final List<ImageProvider> images;
  final String? title;
  final int initialIndex;

  @override
  State<ViewImages> createState() => _ViewImagesState();
}

class _ViewImagesState extends State<ViewImages> {
  late final PageController _pageController;
  static const duration = Duration(milliseconds: 300);
  bool showDescription = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? "Image Viewer"),
        toolbarHeight: showDescription ? kToolbarHeight : 0,
      ),
      body: GestureDetector(
        onTap: () => setState(() => showDescription = !showDescription),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PhotoViewGallery.builder(
              wantKeepAlive: true,
              itemCount: widget.images.length,
              builder: (context, index) {
                final img = widget.images[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: img,
                  minScale: 0.05,
                  errorBuilder: (ctx, e, trace) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Failed to load image!\n $e",
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                );
              },
              loadingBuilder: (context, chuck) {
                double? progress;

                if (chuck != null) {
                  if (chuck.expectedTotalBytes != null) {
                    progress =
                        chuck.cumulativeBytesLoaded / chuck.expectedTotalBytes!;
                  }
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: CircularProgressIndicator(
                        value: progress,
                        color: Colors.grey.withOpacity(0.5),
                        strokeWidth: 2,
                      ),
                    ),
                    Text(
                      "${((progress ?? 0) * 100).toInt()}%",
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.5),
                      ),
                    ),
                  ],
                );
              },
              pageController: _pageController,
            ),
            if (widget.images.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: duration,
                        curve: Curves.decelerate,
                      );
                    },
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: duration,
                        curve: Curves.decelerate,
                      );
                    },
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
