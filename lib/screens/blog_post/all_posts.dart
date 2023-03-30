import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/components/blog_post.dart';
import 'package:roomy_finder/models/blog_post.dart';
import 'package:roomy_finder/screens/blog_post/view_post.dart';

class AllBlogPostsScreen extends StatefulWidget {
  const AllBlogPostsScreen({super.key});

  @override
  State<AllBlogPostsScreen> createState() => _AllBlogPostsScreenState();
}

class _AllBlogPostsScreenState extends State<AllBlogPostsScreen> {
  final List<BlogPost> _blogPosts = [];
  bool _failedToFetch = false;
  @override
  void initState() {
    _fetBlogPost();
    super.initState();
  }

  Future<void> _fetBlogPost() async {
    try {
      _failedToFetch = false;
      final posts = await BlogPost.getBlogPost();
      _blogPosts.clear();
      _blogPosts.addAll(posts);
      setState(() {});
    } catch (e) {
      debugPrint('$e');
      _failedToFetch = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Blog posts"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetBlogPost();
        },
        child: Builder(builder: (context) {
          if (_failedToFetch) {
            return const Center(
              child: Text("Failed to fetch posts. Pull to refresh"),
            );
          }
          return ListView.builder(
            itemBuilder: (context, index) {
              final post = _blogPosts[index];
              return BlogPostWidget(
                post: post,
                showTitle: true,
                onTap: () {
                  Get.to(() => ViewBlogPostScreen(post: post));
                },
              );
            },
            itemCount: _blogPosts.length,
          );
        }),
      ),
    );
  }
}
