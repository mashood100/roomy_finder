import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:roomy_finder/classes/app_notification.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/local_notifications.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/utilities/data.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final StreamSubscription<FileSystemEvent> subscription;

  List<AppNotification> notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    watchDir();

    _getNotifications();
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();

    AppNotification.unReadNotificationsCount(0);
  }

  Future<void> _getNotifications() async {
    setState(() => _isLoading = true);
    notifications = await LocalNotificationController.getSaveNotifications(
      AppController.me.id,
    );

    setState(() => _isLoading = false);
  }

  Future<void> watchDir() async {
    try {
      final appDir = await getApplicationSupportDirectory();

      var filePath =
          path.join(appDir.path, "${AppController.me.id}-notifications.json");

      final file = File(filePath);

      if (!file.existsSync()) file.createSync();

      subscription = file.watch().listen((event) {
        _getNotifications();
      });
    } catch (e, trace) {
      log(e);
      log(trace);
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    final shouldDelete = await showConfirmDialog("Please confirm");
    if (shouldDelete != true) return;

    await LocalNotificationController.deleteNotification(
      AppController.me.id,
      notification,
    );

    notifications.remove(notification);
    setState(() {});
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
      body: Builder(
        builder: (context) {
          if (_isLoading) return const LoadingPlaceholder();

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
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
                          Expanded(
                            child: Text(
                              n.event,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: ROOMY_ORANGE),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              relativeTimeText(n.createdAt),
                              textAlign: TextAlign.right,
                            ),
                          ),
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
                              onPressed: () => _deleteNotification(n),
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 20,
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
        },
      ),
    );
  }
}
