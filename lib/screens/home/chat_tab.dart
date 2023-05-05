import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';

import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/custom_bottom_navbar_icon.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/chat_message.dart';
import 'package:roomy_finder/models/chat_user.dart';
import 'package:roomy_finder/screens/messages/flyer_chat.dart';
import 'package:roomy_finder/utilities/data.dart';

import '../../functions/utility.dart';

class ChatTabController extends LoadingController {
  final conversations = <ChatConversation>[].obs;
  late final StreamSubscription<FGBGType> fGBGNotifierSubScription;

  @override
  void onInit() {
    super.onInit();
    _fetchConversations(isRefresh: true);

    fGBGNotifierSubScription = FGBGEvents.stream.listen((event) {
      if (event == FGBGType.foreground) {
        _fetchConversations();
      }
    });

    FirebaseMessaging.onMessage.asBroadcastStream().listen((event) async {
      final data = event.data;

      if (data["event"] == "new-message") {
        try {
          final payload = jsonDecode(data["payload"]);

          final message = ChatMessage.fromMap(payload["message"]);

          final other =
              ChatUser(id: message.senderId, createdAt: DateTime.now());

          final convKey = ChatConversation.createConvsertionKey(
            message.recieverId,
            message.senderId,
          );
          final ChatConversation conv;
          final oldConv =
              conversations.firstWhereOrNull((c) => c.key == convKey);

          if (oldConv != null) {
            conv = oldConv;
          } else {
            conv = ChatConversation(other: other, lastMessage: message);
            await conv.updateChatInfo();
          }

          final chatUiController = Get.put(
            FlyerChatScreenController(conv),
            tag: "${AppController.me.id}#${other.id}",
            permanent: true,
          );

          chatUiController.messages.insert(0, message);

          conv.lastMessage = message;

          addConversation(conv);

          update();

          ChatMessage.requestMarkAsRecieved(
            message.senderId,
            message.recieverId,
          ).then((value) {
            if (value) message.markAsRecieved();
            update();
          });
        } catch (e) {
          Get.log("$e");
        }
      } else if (data["event"] == "message-recieved" ||
          data["event"] == "message-read") {
        final payload = jsonDecode(data["payload"]);

        final convKey = ChatConversation.createConvsertionKey(
          payload["recieverId"],
          payload["senderId"],
        );

        final oldConv = conversations.firstWhereOrNull((c) => c.key == convKey);

        if (oldConv != null) {
          if (data["event"] == "message-recieved") {
            oldConv.lastMessage?.markAsRecieved();
          } else {
            oldConv.lastMessage?.markAsRead();
          }
          update();
        }
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    fGBGNotifierSubScription.cancel();
  }

  Future<void> _fetchConversations({bool isRefresh = false}) async {
    if (AppController.me.isGuest) return;
    try {
      isLoading(true);
      hasFetchError(false);
      update();
      final res = await ApiService.getDio.get(
        "/messages/conversations",
      );

      if (res.statusCode == 200) {
        final data = (res.data as List).map((e) {
          try {
            final conv = ChatConversation.fromMap(e);
            return conv;
          } catch (e) {
            return null;
          }
        });

        conversations.clear();
        conversations.addAll(data.whereType<ChatConversation>());
        sortConversations();
        for (var c in conversations) {
          ChatMessage.requestMarkAsRecieved(c.other.id, c.me.id);
        }
      } else {
        hasFetchError(true);
      }
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    } finally {
      isLoading(false);
      update();
    }
  }

  void sortConversations() {
    conversations.sort((a, b) {
      if (a.lastMessage == null) return 1;
      if (b.lastMessage == null) return 1;

      return b.lastMessage!.createdAt.compareTo(a.lastMessage!.createdAt);
    });
  }

  void addConversation(ChatConversation conversation) {
    if (!conversations.contains(conversation)) {
      conversations.add(conversation);
    }
    sortConversations();
  }

  Future<void> deleteConversation(ChatConversation conversation) async {
    var res = await ChatMessage.deleteConversation(conversation);
    if (res) {
      conversations.remove(conversation);
      update();
      showToast("Conversation deleted");
    }
  }
}

class MessagesTab extends StatelessWidget implements HomeScreenSupportable {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatTabController());
    return GetBuilder<ChatTabController>(builder: (context) {
      if (controller.hasError.isTrue) {
        return Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Text("Failed to load chats"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    controller._fetchConversations(isRefresh: true),
                child: const Text("Reload"),
              ),
              const Spacer(),
            ],
          ),
        );
      }
      if (controller.conversations.isEmpty) {
        return const Center(child: Text("No Chat for now"));
      }

      return ListView.builder(
        itemBuilder: (context, index) {
          final conv = controller.conversations[index];

          return ListTile(
            contentPadding: const EdgeInsets.only(left: 10, right: 10),
            onTap: () async {
              await Get.to(() {
                return FlyerChatScreen(
                  conversation: conv,
                  myId: AppController.me.id,
                  otherId: conv.other.id,
                );
              });
              controller.sortConversations();
              controller.update();
              AwesomeNotifications()
                  .cancelNotificationsByChannelKey("chat_channel_group_key");
            },
            leading: CircleAvatar(
              radius: 20,
              foregroundImage: conv.other.profilePicture != null
                  ? CachedNetworkImageProvider(conv.other.profilePicture!)
                  : null,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  conv.other.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (conv.lastMessage != null)
                  Text(
                    relativeTimeText(conv.lastMessage!.createdAt,
                        fromNow: false),
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            subtitle: Builder(
              builder: (context) {
                final msg = conv.lastMessage;

                if (msg == null) return const SizedBox();

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        msg.body ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (msg.isMine && !msg.isRecieved)
                      const Icon(
                        Icons.done,
                        color: Colors.grey,
                        size: 16,
                      )
                    else if (msg.isMine)
                      Icon(
                        Icons.done_all_outlined,
                        color: msg.isRead ? Colors.blue : Colors.grey,
                        size: 16,
                      )
                  ],
                );
              },
            ),
            // trailing: SizedBox(
            //   width: 40,
            //   child: IconButton(
            //     onPressed: () {},
            //     icon: const Icon(CupertinoIcons.ellipsis_vertical),
            //   ),
            // ),
          );
        },
        itemCount: controller.conversations.length,
      );
    });
  }

  @override
  AppBar get appBar {
    return AppBar(
      backgroundColor: const Color.fromRGBO(96, 15, 116, 1),
      title: const Text('Chats'),
      centerTitle: false,
      elevation: 0,
      actions: [
        GetBuilder<ChatTabController>(builder: (controller) {
          if (controller.isLoading.isTrue) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: CupertinoActivityIndicator(
                color: Colors.white,
              ),
            );
          }
          return IconButton(
            onPressed: controller._fetchConversations,
            icon: const Icon(Icons.refresh),
          );
        })
      ],
    );
  }

  @override
  BottomNavigationBarItem navigationBarItem(isCurrent) {
    return BottomNavigationBarItem(
      icon: CustomBottomNavbarIcon(
        icon: Badge(
          showBadge: AppController.instance.haveNewMessage.isTrue,
          child: Image.asset(
            "assets/icons/chat.png",
            height: 30,
            width: 30,
            color: ROOMY_PURPLE,
          ),
        ),
        isCurrent: isCurrent,
      ),
      label: 'Chats'.tr,
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;

  @override
  void onIndexSelected(int index) {
    final controller = Get.put(ChatTabController());
    controller.update();
    AppController.instance.haveNewMessage(false);
    AwesomeNotifications().cancelNotificationsByChannelKey("chat_channel_key");
    AwesomeNotifications().cancelNotificationsByGroupKey(
      "chat_channel_group_key",
    );
  }
}
