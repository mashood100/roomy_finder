import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/custom_bottom_navbar_icon.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/screens/messages/flyer_chat.dart';

import '../../functions/utility.dart';

class _ChatTabController extends LoadingController {
  final conversations = <ChatConversation>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadConversations();

    FirebaseMessaging.onMessage.asBroadcastStream().listen((event) async {
      final data = event.data;

      if (data["event"] == "new-message") {
        await Future.delayed(const Duration(milliseconds: 200));
        _loadConversations();
      }
    });
  }

  Future<void> _loadConversations() async {
    try {
      isLoading(true);
      final chats =
          await ChatConversation.getAllSavedChats(AppController.me.id);

      conversations.clear();
      conversations.addAll(chats);
      conversations.sort((a, b) => a.createdAt.isBefore(b.createdAt) ? 1 : -1);
      update();
      for (var c in conversations) {
        if (c.friend.fcmToken == null) {
          c.updateChatInfo().then((_) {
            update();
            return c.saveChat();
          });
        }
      }
    } catch (_) {
    } finally {
      isLoading(false);
      update();
    }
  }
}

class MessagesTab extends StatelessWidget implements HomeScreenSupportable {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ChatTabController());
    return Obx(() {
      if (controller.isLoading.isTrue) {
        return const Center(
          child: CupertinoActivityIndicator(),
        );
      }
      if (controller.conversations.isEmpty) {
        return const Center(child: Text("No Chat for now"));
      }

      return GetBuilder<_ChatTabController>(builder: (context) {
        return ListView.builder(
          itemBuilder: (context, index) {
            final conv = controller.conversations[index];

            return ListTile(
              // onTap: () => Get.to(() => ChatScreen(conversation: conv)),
              onTap: () async {
                await Get.to(() => FlyerChatScreen(
                      conversation: conv,
                    ));
                controller._loadConversations();
                AwesomeNotifications()
                    .cancelNotificationsByChannelKey("chat_channel_group_key");
              },
              leading: CircleAvatar(
                radius: 20,
                foregroundImage: conv.friend.profilePicture != null
                    ? CachedNetworkImageProvider(conv.friend.profilePicture!)
                    : null,
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    conv.friend.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (conv.lastMessage != null)
                    Text(
                      relativeTimeText(conv.lastMessage!.createdAt),
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              subtitle: conv.lastMessage == null
                  ? null
                  : Builder(
                      builder: (context) {
                        final msg = conv.lastMessage!;

                        return Text(
                          msg.body ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
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
    final controller = Get.put(_ChatTabController());
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),

      title: const Text('Chat'),
      centerTitle: false,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: controller._loadConversations,
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
  BottomNavigationBarItem navigationBarItem(isCurrent) {
    return BottomNavigationBarItem(
      icon: CustomBottomNavbarIcon(
        icon: Badge(
          showBadge: AppController.instance.haveNewMessage.isTrue,
          child: const Icon(CupertinoIcons.chat_bubble_2),
        ),
        isCurrent: isCurrent,
      ),
      label: 'Chat'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;

  @override
  void onIndexSelected(int index) {
    final controller = Get.put(_ChatTabController());
    controller._loadConversations();
    AppController.instance.haveNewMessage(false);
    AwesomeNotifications().cancelNotificationsByChannelKey("chat_channel_key");
    AwesomeNotifications().cancelNotificationsByGroupKey(
      "chat_channel_group_key",
    );
  }
}
