import 'dart:convert';

import 'package:roomy_finder/classes/api_service.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class BlogPost {
  final String title;
  final String content;
  final String? imageUrl;
  final String? author;
  final String? authorImageUrl;
  final String? quote;
  final String? conclusion;
  final DateTime? createdAt;
  BlogPost({
    required this.title,
    required this.content,
    this.imageUrl,
    this.author,
    this.authorImageUrl,
    this.quote,
    this.conclusion,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'author': author,
      'authorImageUrl': authorImageUrl,
      'quote': quote,
      'conclusion': conclusion,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory BlogPost.fromMap(Map<String, dynamic> map) {
    return BlogPost(
      title: map['title'] as String,
      content: map['content'] as String,
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
      author: map['author'] != null ? map['author'] as String : null,
      authorImageUrl: map['authorImageUrl'] != null
          ? map['authorImageUrl'] as String
          : null,
      quote: map['quote'] != null ? map['quote'] as String : null,
      conclusion:
          map['conclusion'] != null ? map['conclusion'] as String : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BlogPost.fromJson(String source) =>
      BlogPost.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant BlogPost other) {
    if (identical(this, other)) return true;

    return other.title == title &&
        other.content == content &&
        other.imageUrl == imageUrl &&
        other.author == author &&
        other.quote == quote &&
        other.conclusion == conclusion &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        content.hashCode ^
        imageUrl.hashCode ^
        author.hashCode ^
        quote.hashCode ^
        conclusion.hashCode ^
        createdAt.hashCode;
  }

  // Static list of blog posts
  static Future<List<BlogPost>> getBlogPost() async {
    final res = await ApiService.getDio.get("/blog-post");
    final post = (res.data as List).map((e) => BlogPost.fromMap(e)).toList();

    return post;
  }
}
