import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/share_app.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/helpers/roomy_notification.dart';
import 'package:roomy_finder/screens/ads/property_ad/post_property_ad.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/post_ad_first_screen.dart';
import 'package:roomy_finder/screens/blog_post/all_posts.dart';
import 'package:roomy_finder/screens/home/home.dart';
import 'package:roomy_finder/screens/user/update_profile.dart';
import 'package:roomy_finder/screens/utility_screens/contact_us.dart';
import 'package:roomy_finder/screens/utility_screens/faq.dart';
import 'package:roomy_finder/screens/utility_screens/view_pdf.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showConfirmDialog(
      "Are you sure yo want to logout?",
      title: 'Roomy Finder',
    );
    if (shouldLogout == true) {
      await AppController.instance.logout();
      Home.currentIndex(1);
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (!AppController.me.isGuest)
              AppController.me.ppWidget(borderColor: false),
            if (!AppController.me.isGuest)
              Text(
                AppController.me.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            if (!AppController.me.isGuest)
              Builder(builder: (context) {
                final type = AppController.me.type;
                if (type.isEmpty) return const SizedBox();
                return Text(
                  type.replaceFirst(type[0], type[0].toUpperCase()),
                  style: const TextStyle(),
                );
              }),
            if (!AppController.me.isGuest)
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.edit, color: Colors.white),
                ),
                title: const Text("Edit Profile"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.back();
                  Get.to(() => const UpdateUserProfileScreen());
                },
              ),
            if (AppController.me.isGuest)
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: ROOMY_ORANGE,
                  child: Icon(Icons.login, color: Colors.white),
                ),
                title: const Text("Login"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.offAllNamed("/login");
                },
              ),
            if (AppController.me.isGuest)
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: ROOMY_PURPLE,
                  child: Icon(Icons.person_add, color: Colors.white),
                ),
                title: const Text("Register"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.offAllNamed("/login");
                },
              ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  "General Settings",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: ROOMY_PURPLE,
                child: Icon(Icons.home, color: Colors.white),
              ),
              title: const Text("Home"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Home.currentIndex(1);
                Get.back();
              },
            ),
            if (!AppController.me.isGuest)
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: ROOMY_ORANGE,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: const Text("My Account"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Home.currentIndex(0);
                  Get.back();
                },
              ),
            ListTile(
              // ),
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue,
                child: Icon(Icons.add_box, color: Colors.white),
              ),
              title: const Text("Post Ad"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                if (AppController.me.isGuest) {
                  Get.offAllNamed('/login');
                } else if (AppController.me.isLandlord) {
                  if (AppController.dashboardIsBlocked &&
                      AppController.me.isLandlord) {
                    RoomyNotificationHelper.showDashBoardIsBlocked();
                    return;
                  }
                  Get.to(() => const PostPropertyAdScreen());
                } else if (AppController.me.isRoommate) {
                  Get.to(() {
                    return const PostRoommateAdFirstScreen();
                  });
                }
              },
            ),
            ListTile(
              // leading: Image.asset(
              //   "assets/icons/drawer/contact_us.png",
              //   width: 40,
              //   height: 40,
              //   fit: BoxFit.cover,
              // ),
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.pink,
                child: Icon(Icons.support_agent, color: Colors.white),
              ),
              title: const Text("Contact Us"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                Get.to(() => const ContactUsScreen());
              },
            ),
            ListTile(
              // leading: Image.asset(
              //   "assets/icons/drawer/edit_article.png",
              //   width: 40,
              //   height: 40,
              //   fit: BoxFit.cover,
              // ),
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: ROOMY_ORANGE,
                child: Icon(Icons.article, color: Colors.white),
              ),
              title: const Text("Blog"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                Get.to(() => const AllBlogPostsScreen());
              },
            ),
            ListTile(
              // leading: Image.asset(
              //   "assets/icons/drawer/info.png",
              //   width: 40,
              //   height: 40,
              //   fit: BoxFit.cover,
              // ),
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green,
                child: Icon(Icons.info_outline, color: Colors.white),
              ),
              title: const Text("Terms & Conditions"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                Get.to(() {
                  return const ViewPdfScreen(
                    title: "Terms and conditions",
                    asset: "assets/pdf/terms-and-conditions.pdf",
                  );
                });
              },
            ),
            ListTile(
              // leading: Image.asset(
              //   "assets/icons/drawer/lock.png",
              //   width: 40,
              //   height: 40,
              //   fit: BoxFit.cover,
              // ),
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.red,
                child: Icon(Icons.privacy_tip, color: Colors.white),
              ),
              title: const Text("Privacy Policy"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                Get.to(() {
                  return const ViewPdfScreen(
                    title: "Privacy policy",
                    asset: "assets/pdf/privacy-policy.pdf",
                  );
                });
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue,
                child: Icon(Icons.question_mark_outlined, color: Colors.white),
              ),
              title: const Text("FAQ"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                Get.to(() => const FAQScreen());
              },
            ),
            ListTile(
              // leading: Image.asset(
              //   "assets/icons/drawer/share.png",
              //   width: 40,
              //   height: 40,
              //   fit: BoxFit.cover,
              // ),
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purpleAccent,
                child: Icon(Icons.share, color: Colors.white),
              ),
              title: const Text("Share This App"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                shareApp();
              },
            ),
            if (!AppController.me.isGuest)
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.logout, color: Colors.white),
                ),
                title: const Text("Logout"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Get.back();

                  _logout(Get.context!);
                },
              ),
            const Divider(height: 10),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                {
                  "url":
                      "https://www.tiktok.com/@roomyfinder?_t=8bNtaBqPwQr&_r=1",
                  "assetImage": "assets/images/social/tiktok.png",
                  "label": "Tiktok",
                },
                {
                  "url": "https://www.facebook.com/roomyfinder?mibextid=LQQJ4d",
                  "assetImage": "assets/images/social/facebook.png",
                  "label": "Facebook",
                },
                {
                  "url":
                      "https://instagram.com/roomyfinder?igshid=YjNmNGQ3MDY=",
                  "assetImage": "assets/images/social/instagram.png",
                  "label": "Instagram",
                },
                {
                  "assetImage": "assets/images/social/twitter.png",
                  "label": "Twitter",
                },
                {
                  "assetImage": "assets/images/social/snapchat.png",
                  "label": "Snapchat",
                },
              ].map((e) {
                return GestureDetector(
                  onTap: () async {
                    Get.back();
                    if (e["url"] == null) {
                      showToast("Comming soon...");
                      return;
                    }
                    var url = Uri.parse(e["url"]!);
                    if (await canLaunchUrl(url)) {
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Image.asset(e["assetImage"]!, width: 40, height: 40),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
