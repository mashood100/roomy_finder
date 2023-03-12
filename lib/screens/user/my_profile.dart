import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/screens/user/update_profile.dart';

class ViewUser extends StatelessWidget {
  const ViewUser({super.key, required this.user});
  final User user;

  void _viewImage(String source) {
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(5.0),
          child: CachedNetworkImage(imageUrl: source),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.isMe ? "My Profile" : user.fullName),
        actions: [
          if (user.isMe)
            IconButton(
              onPressed: () {
                Get.to(const UpdateUserProfile());
              },
              icon: const Icon(Icons.edit),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _viewImage(user.profilePicture),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: CachedNetworkImage(
                    imageUrl: user.profilePicture,
                    height: MediaQuery.of(context).size.width * 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
