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
                      "111 Lawrence street, Brooklyn, New york 11201",
                    ),
                  ),
                  Text("Tel"),
                  Text(
                    "+13053172031",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "+14124033921",
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
                      "🇸🇦",
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
                      "Dubai inverstment park, metro station, falcon house, 2nd floor",
                    ),
                  ),
                  Text("Tel"),
                  Text(
                    "+971505853921",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "+971589292273",
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
                  "info@gsccapitalgroup.com",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  onPressed: () async {
                    var url = Uri.parse("mailto:info@gsccapitalgroup.com");
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
