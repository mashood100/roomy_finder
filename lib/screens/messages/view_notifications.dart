import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/app_notification.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';

import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/utilities/data.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    AppController.instance.unreadNotificationCount(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: FutureBuilder(
        builder: (ctx, asp) {
          if (asp.connectionState == ConnectionState.done) {
            if (asp.hasError) {
              return Center(child: Text('Failed to load notifications'.tr));
            }
            final notifications = asp.data as List<AppNotication>;
            if (notifications.isEmpty) {
              return Center(child: Text('No notifications'.tr));
            }

            return ListView.builder(
              // controller: controller.conversation.messagesListController,
              itemBuilder: (context, index) {
                final n = notifications[index];

                return Card(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: Get.width * 0.6,
                              child: Text(
                                n.event,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: ROOMY_ORANGE),
                              ),
                            ),
                            Text(relativeTimeText(n.createdAt)),
                          ],
                        ),
                        const Divider(),
                        Text(n.message),
                        const Divider(),
                        Row(
                          children: [
                            const Spacer(),
                            SizedBox(
                              height: 35,
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  side: const BorderSide(color: Colors.red),
                                ),
                                onPressed: () async {
                                  final shouldDelete = await showConfirmDialog(
                                      "Do you really want to delete");
                                  if (shouldDelete != true) return;

                                  await AppNotication.deleteNotifications(n);
                                  setState(() {});
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
              itemCount: notifications.length,
            );
          }

          return const CircularProgressIndicator();
        },
        future: AppNotication.getSavedNotifications(),
      ),
    );
  }
}
