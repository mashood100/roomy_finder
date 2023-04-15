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
        title: Text(widget.title ?? "View images"),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          PhotoViewGallery.builder(
            itemCount: widget.images.length,
            builder: (context, index) {
              final img = widget.images[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: img,
              );
            },
            loadingBuilder: (context, event) {
              return const Padding(
                padding: EdgeInsets.all(50.0),
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(),
                ),
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
    );
  }
}
