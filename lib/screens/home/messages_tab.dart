import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/screens/messages/chat.dart';
import 'package:roomy_finder/screens/messages/view_notifications.dart';
// import 'package:roomy_finder/controllers/loadinding_controller.dart';

class _MessagesTabController extends LoadingController {
  final conversations = <ChatConversation>[].obs;

  @override
  void onInit() {
    super.onInit();
    _getNotifications();
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
    final controller = Get.put(_MessagesTabController());
    return Obx(() {
      if (controller.isLoading.isTrue) {
        return const Center(
          child: CupertinoActivityIndicator(),
        );
      }
      if (controller.conversations.isEmpty) {
        return const Center(child: Text("No Chat for now"));
      }

      return ListView.builder(
        itemBuilder: (context, index) {
          final conv = controller.conversations[index];

          return ListTile(
            onTap: () => Get.to(() => ChatScreen(conversation: conv)),
            leading: conv.friend.ppWidget(size: 20, borderColor: false),
            title: Text(conv.friend.fullName),
            subtitle:
                conv.messages.isEmpty ? null : Text(conv.messages.last.content),
            trailing: IconButton(
              onPressed: () async {
                final shoulDelete =
                    await showConfirmDialog("Do you really want to delete?");

                if (shoulDelete == true) {
                  await ChatConversation.removeSavedChat(conv.key);
                  controller._getNotifications();
                }
              },
              icon: const Icon(Icons.delete),
            ),
          );
        },
        itemCount: controller.conversations.length,
      );
    });
  }

  @override
  AppBar get appBar {
    final controller = Get.put(_MessagesTabController());
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      automaticallyImplyLeading: false,
      title: const Text('Messages'),
      centerTitle: false,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: controller._getNotifications,
          icon: const Icon(Icons.refresh),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size(double.infinity, 30),
        child: ListTile(
          dense: true,
          title: const Text(
            "Notification",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          leading: const CircleAvatar(
            child: Icon(
              Icons.notifications,
              color: Colors.white,
            ),
          ),
          trailing: Badge(
            position: BadgePosition.topEnd(top: 2, end: 2),
            showBadge: AppController.instance.haveNewNotification.isTrue,
            badgeColor: Colors.blue,
            child: IconButton(
              onPressed: () {
                Get.to(() => const NotificationsScreen());
                AppController.instance.haveNewNotification(false);
              },
              icon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  @override
  BottomNavigationBarItem get navigationBarItem {
    return BottomNavigationBarItem(
      icon: Obx(() {
        return Badge(
          showBadge: AppController.instance.haveNewMessage.isTrue ||
              AppController.instance.haveNewNotification.isTrue,
          child: const Icon(CupertinoIcons.chat_bubble_2_fill),
        );
      }),
      label: 'messages'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;
}
