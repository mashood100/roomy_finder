import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact us"),
      ),
      body: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  ListTile(
                    leading: Text(
                      "🇺🇸",
                      style: TextStyle(fontSize: 25),
                    ),
                    title: Text(
                      "United States of Ameriaca",
                      style: TextStyle(
                        // fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Location : Global Strategy Catalyst Group LLC\n"
                      "401 Ryland St, Suite 200-A, Reno, NV, 89502",
                    ),
                  ),
                  Text("Tel"),
                  Text(
                    "•  +1 412 403 3921",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  ListTile(
                    leading: Text(
                      "🇦🇪",
                      style: TextStyle(fontSize: 25),
                    ),
                    title: Text(
                      "United Arab Emirates",
                      style: TextStyle(
                        // fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Location : Abu Dhabi, 16, misakin st\nAI Danah 22213",
                    ),
                  ),
                  Text("Tel"),
                  Text(
                    "• +971 50 585 3921",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                leading: const Icon(Icons.mail),
                title: const Text(
                  "Support@roomyfinder.com",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  onPressed: () async {
                    var url = Uri.parse("mailto:Support@roomyfinder.com");
                    if (await canLaunchUrl(url)) {
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
