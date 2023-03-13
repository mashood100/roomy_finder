import 'package:flutter/material.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateAppScreen extends StatelessWidget {
  const UpdateAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text("App upate is required"),
          ElevatedButton(
            onPressed: () async {
              if (AppController.updateVersion != null) {
                var url = Uri.parse(AppController.updateVersion!.url);
                if (await canLaunchUrl(url)) {
                  launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: const Text("Update now"),
          ),
        ],
      ),
    );
  }
}
