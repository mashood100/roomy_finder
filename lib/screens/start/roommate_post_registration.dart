import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:roomy_finder/helpers/asset_helper.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/post_roommate_ad.dart';
import 'package:roomy_finder/utilities/data.dart';

class RoommatePostRegistrationScreen extends StatelessWidget {
  const RoommatePostRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var accountTypes = [
      (
        value: "find-roommate",
        label: "Find roommate",
        asset: AssetIcons.homeFriendsPNG,
        description: "Looking for a roommate to share "
            "space together? Find your match with us!",
      ),
      (
        value: "find-room",
        label: "Find room",
        asset: AssetIcons.homeSearchPNG,
        description: "Looking for a rent directly from landlord? Browse through"
            " our multiple sharing options (beds/rooms/partitions).",
      ),
      (
        value: "post-ad",
        label: "Post room ad",
        asset: AssetIcons.homeAddPNG,
        description: "If you have a room and you looking for roommate"
            " to share house expenses, post an ad!",
      ),
    ];
    String? action;
    return StatefulBuilder(builder: (context, setState) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Registration"),
          leading: const BackButton(),
        ),
        body: Stack(
          children: [
            Container(
              height: 15,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Get.theme.appBarTheme.backgroundColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.elliptical(50, 25),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 15,
                bottom: 50,
                left: 20,
                right: 20,
              ),
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
                  ...accountTypes.map((e) {
                    var isSelected = e.value == action;

                    return GestureDetector(
                      onTap: () {
                        action = (e.value);
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
                              color: isSelected ? ROOMY_ORANGE : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    e.label,
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
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          decoration: const BoxDecoration(
            color: ROOMY_PURPLE,
            borderRadius: BorderRadius.vertical(
              top: Radius.elliptical(30, 10),
            ),
          ),
          child: Builder(builder: (context) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: Get.back,
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () async {
                    switch (action) {
                      case "find-roommate":
                        Get.off(() =>
                            const PostRoommateAdScreen(action: "NEED ROOM"));
                        break;
                      case "find-room":
                        Get.back();
                        break;
                      case "post-ad":
                        Get.off(() =>
                            const PostRoommateAdScreen(action: "HAVE ROOM"));
                        break;
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
            );
          }),
        ),
      );
    });
  }
}
