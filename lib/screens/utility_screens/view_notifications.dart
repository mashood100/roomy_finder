import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:roomy_finder/classes/app_notification.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/notification_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/screens/home/home.dart';
import 'package:roomy_finder/utilities/data.dart';

class NotificationsScreen extends StatefulWidget
    implements HomeScreenSupportable {
  const NotificationsScreen({super.key, this.showNavBar});

  final bool? showNavBar;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();

  @override
  void onTabIndexSelected(int index) {}
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final StreamSubscription<FileSystemEvent> subscription;

  Future<void> _markNotificationAsRead() async {
    final futures = <Future>[];
    for (var n in notifications) {
      if (!n.isRead) futures.add(n.markAsRead(AppController.me.id));
    }

    await Future.wait(futures);

    setState(() {});
  }

  List<AppNotification> notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    watchDir();

    _getNotifications().then((value) => _markNotificationAsRead());

    NotificationController.setUnreadNotificationsCount(AppController.me.id);
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();

    // Home.unReadNotificationsCount(0);
  }

  Future<void> _getNotifications() async {
    setState(() => _isLoading = true);
    notifications =
        await NotificationController.getSaveNotifications(AppController.me.id);

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

    await NotificationController.deleteNotification(
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
            onPressed: _getNotifications,
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            // controller: controller.conversation.messagesListController,
            itemBuilder: (context, index) {
              final n = notifications[index];

              return Card(
                surfaceTintColor: Colors.white,
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
                            child: Builder(builder: (context) {
                              var local = Jiffy.parseFromDateTime(n.createdAt)
                                  .toLocal();
                              var text = local.yMMMdjm;
                              if (local.add(months: 1).isAfter(Jiffy.now())) {
                                text = "${local.MMMd}, ${local.Hm}";
                              }
                              if (local
                                  .add(days: 1)
                                  .isAfter(Jiffy.now(), unit: Unit.day)) {
                                text = local.Hm;
                              }

                              if (local.add(hours: 12).isAfter(Jiffy.now())) {
                                text = local.fromNow();
                              }

                              return Text(
                                text,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 10),
                              );
                            }),
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
      bottomNavigationBar: widget.showNavBar == true
          ? HomeBottomNavigationBar(
              onTap: (index) {
                if (AppController.me.isLandlord && index == 3) {
                  _markNotificationAsRead();
                  Home.unReadNotificationsCount(0);
                }
              },
            )
          : null,
    );
  }
}
