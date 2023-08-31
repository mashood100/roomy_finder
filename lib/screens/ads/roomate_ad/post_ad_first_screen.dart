import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/post_roommate_ad.dart';
import 'package:roomy_finder/utilities/data.dart';

class PostRoommateAdFirstScreen extends StatelessWidget {
  const PostRoommateAdFirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String? action;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post ad"),
      ),
      body: StatefulBuilder(builder: (context, setState) {
        var list = [
          (
            value: "HAVE ROOM",
            label: "Have Room",
            asset: AssetIcons.homeAddPNG,
            description: "If you have a room and you looking for "
                "roommate to share house expenses, post an ad!",
          ),
          (
            value: "NEED ROOM",
            label: "Need Room",
            asset: AssetIcons.homeSearchPNG,
            description: "Looking for a roommate & shared space? "
                "Find your ideal living situation with us!",
          ),
        ];

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "What are you looking for?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ...list.map((e) {
                var isSelected = action == e.value;

                return GestureDetector(
                  onTap: () {
                    action = e.value;
                    setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(width: 2, color: ROOMY_PURPLE)
                          : Border.all(width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 10,
                    ),
                    margin: const EdgeInsets.only(
                      bottom: 20,
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          e.asset,
                          height: 50,
                          width: 50,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                e.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                e.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList()
            ],
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          color: ROOMY_PURPLE,
          borderRadius: BorderRadius.vertical(
            top: Radius.elliptical(30, 10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
            IconButton(
              onPressed: () {
                if (action == null) {
                  showToast("Please choose an option");
                } else {
                  Get.to(() => PostRoommateAdScreen(action: action!));
                }
              },
              icon: const Icon(
                CupertinoIcons.chevron_right_circle,
                color: Colors.white,
                size: 30,
              ),
            ),
            // const Icon(Icons.arrow_right),
          ],
        ),
      ),
    );
  }
}
