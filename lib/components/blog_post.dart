import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/components/loading_progress_image.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/models/blog_post.dart';
import 'package:roomy_finder/utilities/data.dart';

class BlogPostWidget extends StatelessWidget {
  final BlogPost post;
  final void Function()? onTap;
  final bool? showTitle;

  const BlogPostWidget({
    super.key,
    required this.post,
    this.onTap,
    this.showTitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        child: Container(
          width: 200,
          height: 240,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: LoadingProgressImage(
                  image: CachedNetworkImageProvider("${post.imageUrl}"),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, trace) {
                    return Image.asset(
                      AssetImages.logoHousePNG,
                      height: 100,
                      width: double.infinity,
                      alignment: Alignment.center,
                    );
                  },
                ),
              ),
              if (showTitle == true)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ROOMY_ORANGE,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    post.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Divider(height: 1),
              if (post.createdAt != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      Jiffy.parseFromDateTime(post.createdAt!).yMEd,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
