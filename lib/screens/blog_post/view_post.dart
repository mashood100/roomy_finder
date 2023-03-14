import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/models/blog_post.dart';

class ViewBlogPostScreen extends StatelessWidget {
  const ViewBlogPostScreen({super.key, required this.post});

  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.topLeft,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl ?? "",
                    width: MediaQuery.of(context).size.height,
                    fit: BoxFit.fitWidth,
                    // errorWidget: (ctx, e, trace) {
                    //   return const Center(child: Icon(Icons.info));
                    // },
                  ),
                ),
                const BackButton(),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    post.title,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (post.authorImageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 10, top: 10),
                          child: CircleAvatar(
                            radius: 25,
                            foregroundImage: CachedNetworkImageProvider(
                              post.authorImageUrl!,
                            ),
                          ),
                        ),
                      Text.rich(
                        TextSpan(children: [
                          if (post.author != null) TextSpan(text: post.author!),
                          if (post.author != null) const TextSpan(text: "  "),
                          if (post.createdAt != null)
                            TextSpan(text: Jiffy(post.createdAt!).yMEd),
                        ]),
                        textAlign: TextAlign.left,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  color: const Color.fromRGBO(255, 123, 77, 1),
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(post.content),
                  if (post.conclusion != null)
                    Text(
                      post.conclusion!,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
