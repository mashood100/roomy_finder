import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/screens/test/conversations.dart';

class TestHomeScreen extends StatelessWidget {
  const TestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => const ConversationsScreen());
                },
                icon: const Icon(Icons.chat),
                label: const Text("Conversations"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
