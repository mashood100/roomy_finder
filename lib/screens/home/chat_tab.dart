import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:badges/badges.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/screens/messages/flyer_chat.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../../functions/utility.dart';
// import 'package:roomy_finder/controllers/loadinding_controller.dart';

class ChatTabController extends LoadingController {
  final conversations = <ChatConversation>[].obs;

  @override
  void onInit() {
    super.onInit();
    _getNotifications();

    FirebaseMessaging.onMessage.asBroadcastStream().listen((event) {
      final data = event.data;

      if (data["event"] == "new-message") {
        _getNotifications();
      }
    });
  }

  Future<void> _getNotifications() async {
    try {
      isLoading(true);
      final notifications = await ChatConversation.getAllSavedChats();
      conversations.clear();
      conversations.addAll(notifications);
    } catch (_) {
    } finally {}
    isLoading(false);
  }
}

class MessagesTab extends StatelessWidget implements HomeScreenSupportable {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatTabController());
    return Obx(() {
      if (controller.isLoading.isTrue) {
        return const Center(
          child: CupertinoActivityIndicator(),
        );
      }
      if (controller.conversations.isEmpty) {
        return const Center(child: Text("No Chat for now"));
      }

      return GetBuilder<ChatTabController>(builder: (context) {
        return ListView.builder(
          itemBuilder: (context, index) {
            final conv = controller.conversations[index];

            return ListTile(
              // onTap: () => Get.to(() => ChatScreen(conversation: conv)),
              onTap: () async {
                await Get.to(() => FlyerChatScreen(
                      conversation: conv,
                    ));
                controller._getNotifications();
                AwesomeNotifications()
                    .cancelNotificationsByChannelKey("chat_channel_group_key");
              },
              leading: conv.friend.ppWidget(size: 20, borderColor: false),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    conv.friend.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (conv.messages.isNotEmpty &&
                      conv.messages.first.createdAt != null)
                    Text(
                      relativeTimeText(
                        DateTime.fromMillisecondsSinceEpoch(
                          conv.messages.first.createdAt!,
                        ),
                      ),
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              subtitle: conv.messages.isEmpty
                  ? null
                  : Builder(
                      builder: (context) {
                        final msg = conv.messages.first;

                        if (msg is types.TextMessage) {
                          return Text(
                            msg.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                        return const Text("message");
                      },
                    ),
            );
          },
          itemCount: controller.conversations.length,
        );
      });
    });
  }

  @override
  AppBar get appBar {
    final controller = Get.put(ChatTabController());
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      automaticallyImplyLeading: false,
      title: const Text('Chat'),
      centerTitle: false,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: controller._getNotifications,
          icon: const Icon(Icons.refresh),
        ),
      ],
      // bottom: PreferredSize(
      //   preferredSize: const Size(double.infinity, 30),
      //   child: ListTile(
      //     dense: true,
      //     title: const Text(
      //       "Notification",
      //       style: TextStyle(fontSize: 16, color: Colors.white),
      //     ),
      //     leading: const CircleAvatar(
      //       child: Icon(
      //         Icons.notifications,
      //         color: Colors.white,
      //       ),
      //     ),
      //     trailing: Badge(
      //       position: BadgePosition.topEnd(top: 2, end: 2),
      //       showBadge: AppController.instance.haveNewNotification.isTrue,
      //       badgeColor: Colors.blue,
      //       child: IconButton(
      //         onPressed: () {
      //           Get.to(() => const NotificationsScreen());
      //           AppController.instance.haveNewNotification(false);
      //         },
      //         icon: const Icon(Icons.chevron_right, color: Colors.white),
      //       ),
      //     ),
      //   ),
      // ),
    );
  }

  @override
  BottomNavigationBarItem get navigationBarItem {
    return BottomNavigationBarItem(
      icon: Obx(() {
        return Badge(
          showBadge: AppController.instance.haveNewMessage.isTrue,
          child: const Icon(CupertinoIcons.chat_bubble_2_fill),
        );
      }),
      label: 'Chat'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;
}
