import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/screens/utility_screens/view_images.dart';

class ImageGrid extends StatelessWidget {
  const ImageGrid({super.key, required this.images, this.title});

  final List<String> images;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return Container();
    return GridView.count(
      crossAxisCount: Get.width > 370 ? 4 : 3,
      crossAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: images.map((e) {
        return GestureDetector(
          onTap: () {
            Get.to(transition: Transition.zoom, () {
              return ViewImages(
                images:
                    images.map((e) => CachedNetworkImageProvider(e)).toList(),
                initialIndex: images.indexOf(e),
                title: title,
              );
            });
          },
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
              child: LoadingProgressImage(
                image: CachedNetworkImageProvider(e),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
