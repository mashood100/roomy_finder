import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/functions/check_for_update.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/screens/user/contact_us.dart';
import 'package:roomy_finder/screens/user/view_pdf.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _AboutController extends GetxController {
  final _isCheckingUpdate = false.obs;

  Future<String> get _appVersion async {
    final packageInfo = await PackageInfo.fromPlatform();
    return "${"version".tr} ${packageInfo.version}";
  }

  // Future<void> _handleLinkPress(String link, {LaunchMode? mode}) async {
  //   try {
  //     final url = Uri.parse(link);
  //     if (await canLaunchUrl(url)) {
  //       launchUrl(url, mode: mode ?? LaunchMode.externalApplication);
  //     } else {
  //       showToast("failedToOpenLink".tr);
  //     }
  //   } catch (_) {
  //     showToast("failedToOpenLink".tr);
  //   }
  // }

  Future<void> _checkUpdate() async {
    _isCheckingUpdate(true);

    final updateIsAvailable = await checkForAppUpdate();

    _isCheckingUpdate(false);

    if (updateIsAvailable) {
      final shouldUpdate = await showConfirmDialog(
        "An update is available. Do you want to download the update?",
      );

      if (shouldUpdate == true) downloadAppUpdate();
    } else {
      showToast("The App is up to date");
    }
  }
}

class AboutScreeen extends StatelessWidget {
  const AboutScreeen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_AboutController());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
        title: Text(
          'About'.tr,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset(
                "assets/images/logo.png",
                height: 80,
                width: 80,
              ),
              const SizedBox(height: 10),
              Center(
                child: FutureBuilder(
                  builder: (ctx, asp) => Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: "Roomy",
                          style: TextStyle(
                            color: Colors.purple,
                          ),
                        ),
                        const TextSpan(
                          text: "Finder ",
                          style: TextStyle(
                            color: Color.fromRGBO(255, 123, 77, 1),
                          ),
                        ),
                        TextSpan(text: "${asp.data}"),
                      ],
                    ),
                  )
                  // Text("Roomy Finder ${asp.data}")
                  ,
                  future: controller._appVersion,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  onTap: () {
                    Get.to(() {
                      return const ViewPdfScreen(
                        title: "Privacy policy",
                        asset: "assets/pdf/privacy-policy.pdf",
                      );
                    });
                  },
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy policy'),
                  trailing: const IconButton(
                    onPressed: null,
                    icon: Icon(Icons.chevron_right),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  onTap: () {
                    Get.to(() {
                      return const ViewPdfScreen(
                        title: "Terms and conditions",
                        asset: "assets/pdf/terms-and-conditions.pdf",
                      );
                    });
                  },
                  leading: const Icon(Icons.verified_user_rounded),
                  title: const Text('Terms and conditions'),
                  trailing: const IconButton(
                    onPressed: null,
                    icon: Icon(Icons.chevron_right),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.question_answer),
                  title: const Text('FAQ'),
                  trailing: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  onTap: () {},
                  leading: const Icon(Icons.support_agent),
                  title: const Text('Contact us'),
                  trailing: IconButton(
                    onPressed: () {
                      Get.to(() => const ContactUsScreen());
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                return Card(
                  child: ListTile(
                    onTap: controller._checkUpdate,
                    leading: const Icon(Icons.system_update),
                    title: const Text('Check for update'),
                    trailing: IconButton(
                      onPressed: controller._checkUpdate,
                      icon: controller._isCheckingUpdate.isTrue
                          ? const CupertinoActivityIndicator()
                          : const Icon(
                              Icons.download,
                              color: Colors.green,
                            ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
