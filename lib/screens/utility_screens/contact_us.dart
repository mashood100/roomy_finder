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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Card(
                surfaceTintColor: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
                        leading: Text(
                          "🇺🇸",
                          style: TextStyle(fontSize: 25),
                        ),
                        title: Text(
                          "United States of America",
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
                surfaceTintColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
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
                      const Text("Tel"),
                      for (final item in [
                        "• +971 58 613 3921",
                        "• +971 52 653 3921",
                        "• +971 58 693 3921",
                      ])
                        Text(
                          item,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ),
              Card(
                surfaceTintColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    leading: const Icon(Icons.mail),
                    title: const Text(
                      "Support@roomyfinder.com",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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
        ),
      ),
    );
  }
}
