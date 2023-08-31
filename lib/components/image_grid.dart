import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';

class ImageGrid<T> extends StatelessWidget {
  const ImageGrid({
    super.key,
    required this.items,
    required this.getImage,
    this.title,
    this.noDataMessage,
    this.onItemRemoved,
    this.crossAxisCount,
    this.onItemTap,
    this.isVideo,
  });

  final List<T> items;
  final ImageProvider Function(T item) getImage;
  final String? title;
  final String? noDataMessage;
  final void Function(T item)? onItemRemoved;
  final int? crossAxisCount;
  final void Function(T item)? onItemTap;
  final bool? isVideo;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          noDataMessage ?? "No images",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    int crossAxisCount =
        this.crossAxisCount ?? MediaQuery.sizeOf(context).width ~/ 150;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 0,
      mainAxisSpacing: 0,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: items.map((e) {
        return GestureDetector(
          onTap: onItemTap != null
              ? () => onItemTap!(e)
              : () {
                  Get.to(transition: Transition.zoom, () {
                    return ViewImages(
                      images: items.map((e) => getImage(e)).toList(),
                      initialIndex: items.indexOf(e),
                      title: title,
                    );
                  });
                },
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                margin: const EdgeInsets.all(3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LoadingProgressImage(
                    image: getImage(e),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              if (onItemRemoved != null)
                IconButton(
                  onPressed: () => onItemRemoved!(e),
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                ),
              if (isVideo == true)
                const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
