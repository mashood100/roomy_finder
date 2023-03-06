import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/app_locale.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/screens/ads/post_ad.dart';
import 'package:roomy_finder/screens/ads/property_ad/search_query.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/premium_roommates_ads.dart';
import 'package:roomy_finder/screens/ads/roomate_ad/search_roommate_match.dart';
import 'package:roomy_finder/screens/user/upgrade_plan.dart';

class _HomeTabController extends LoadingController {
  void _toggleThemeMode() {
    AppController.setThemeMode(
        Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
    Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}

class HomeTab extends StatelessWidget implements HomeScreenSupportable {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // final controller = Get.put(_HomeTabController());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: HomeUserInfo(),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10),
                HomeCard(
                  label: "lookingForProperties".tr,
                  assetImage: "assets/images/looking-roommate.png",
                  onTap: () {
                    Get.to(() => const PropertyAdSearchQueryScreen());
                  },
                ),
                HomeCard(
                  label: "Premium Roommate Ad".tr,
                  assetImage: "assets/images/premium_roommate.png",
                  onTap: () async {
                    if (AppController.me.isPremium) {
                      Get.to(() => const PremiumRoommatesAdsScreen());
                    } else {
                      final upgrade = await showConfirmDialog(
                          "Only premium members can see premium ADs."
                          " Do you want to upgrade you plan?");
                      if (upgrade == true) {
                        Get.to(
                          () => UpgragePlanScreen(
                            skipCallback: () {
                              Get.to(
                                () {
                                  return const PremiumRoommatesAdsScreen();
                                },
                              );
                            },
                          ),
                        );
                      }
                    }
                  },
                ),
                HomeCard(
                  label: "Looking for Roommate Match".tr,
                  assetImage: "assets/images/premium_roommate.png",
                  onTap: () {
                    Get.to(() => const SearchRoommateMatchScreen());
                  },
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Text('Post your properties for fast advertisation'.tr),
                ),
                ElevatedButton(
                  onPressed: () {
                    Get.to(() => const PostAdScreen());
                  },
                  child: Text('postAd'.tr),
                )
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < 5; i++)
                    const HomeBlogPost(
                      content: _bolgPostContent,
                      imageUrl: _blogPostImageUrl,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  AppBar get appBar {
    final controller = Get.put(_HomeTabController());
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      automaticallyImplyLeading: false,
      title: SizedBox(
        width: Get.width,
        child: Builder(builder: (context) {
          return Row(
            children: [
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Roomy",
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: "FINDER",
                      style: TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: controller._toggleThemeMode,
                icon: Theme.of(context).brightness == Brightness.light
                    ? const Icon(Icons.dark_mode, color: Colors.white)
                    : const Icon(Icons.light_mode, color: Colors.white),
              ),
              TextButton.icon(
                onPressed: () => changeAppLocale(context),
                label: Text(
                  AppController.locale.languageName,
                  style: const TextStyle(color: Colors.white),
                ),
                icon: Icon(Icons.language, color: Colors.grey.shade300),
              ),
            ],
          );
        }),
      ),
      centerTitle: false,
      elevation: 0,
    );
  }

  @override
  BottomNavigationBarItem get navigationBarItem {
    return BottomNavigationBarItem(
      icon: const Icon(CupertinoIcons.home),
      label: 'home'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;
}

class HomeUserInfo extends StatelessWidget {
  const HomeUserInfo({super.key});

  Future<String> get _formattedPhoneNumber async {
    final phoneNumber = PhoneNumber(
      phoneNumber: AppController.me.phone,
    );
    try {
      final data = await PhoneNumber.getParsableNumber(phoneNumber);
      return "(${phoneNumber.dialCode}) $data";
    } on Exception catch (_) {
      return phoneNumber.phoneNumber ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Card(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppController.me.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.fade,
                      ),
                      maxLines: 1,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mail),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppController.me.email,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_android),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FutureBuilder(
                            builder: (ctx, asp) => Text(
                              "${asp.data}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            future: _formattedPhoneNumber,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.location_solid),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppController.me.country,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.person_alt_circle_fill),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppController.me.type.replaceFirst(
                              AppController.me.type[0],
                              AppController.me.type[0].toUpperCase(),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              AppController.me.profilePicture,
              height: 130,
              errorBuilder: (ctx, e, trace) {
                Get.log('$trace');
                return const Card(
                  child: SizedBox(
                    height: 130,
                    child: Icon(Icons.person, size: 80),
                  ),
                );
              },
              // height: 130,
            ),
          )
        ],
      );
    });
  }
}

class HomeCard extends StatelessWidget {
  final String label;
  final String assetImage;
  final void Function()? onTap;

  const HomeCard({
    super.key,
    required this.label,
    required this.assetImage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(assetImage),
              fit: BoxFit.cover,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  )),
              const Icon(
                Icons.arrow_forward_ios,
                size: 25,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeBlogPost extends StatelessWidget {
  final String content;
  final String imageUrl;
  final void Function()? onTap;

  const HomeBlogPost({
    super.key,
    required this.content,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        child: Container(
          width: 200,
          height: 220,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                // ignore: todo
                // TODO : chang to network image
                child: Image.asset(
                  "assets/images/dubai.png",
                  height: 100,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, trace) {
                    return const Center(child: Icon(Icons.info));
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Divider(height: 1),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    relativeTimeText(DateTime(2022, 9, 7, 17, 30)),
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

const _blogPostImageUrl = "https://pixabay.com/images/id-5219567";
const _bolgPostContent =
    "Lorem ipsum dolor sit amet consectetur adipisicing elit. Omnis, amet iure? itatis "
    "ad impedit quae reiciendis in? Fugit, dicta nulla earum fuga quibusdam "
    "sunt, molestias ex tenetur molestiae numquam esse est! Magni dolores sequi "
    " upiditate perspiciatis dolor. Quia doloremque totam laudantium praesentium fuga";
