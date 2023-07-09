import 'dart:async';
import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/chat_file_system.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as dd;

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/components/custom_bottom_navbar_icon.dart';
import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/controllers/local_notifications.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/chat_conversation_v2.dart';
import 'package:roomy_finder/models/chat_message_v2.dart';
import 'package:roomy_finder/screens/chat/chat_room/chat_room_screen.dart';
import 'package:roomy_finder/utilities/data.dart';

class _ConversationsController extends LoadingController {
  late final Socket socket;

  late final StreamSubscription<RemoteMessage> fcmStream;
  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;

  bool _isForeground = true;

  RxList<ChatConversationV2> get conversations =>
      ChatConversationV2.conversations;

  int get unReadMessagesCount {
    var count = conversations.isEmpty
        ? 0
        : conversations
            .map((e) => e.unReadMessageCount)
            .reduce((value, e) => value + e);

    return count;
  }

  Future<void> _getInitalSaveMessages() async {
    final data =
        await ChatFileSystem.getSavedConversations(AppController.me.id);

    conversations.addAll(data);

    update();
  }

  @override
  void onInit() {
    super.onInit();
    isLoading.value = true;

    socket = io(SERVER_URL, AppController.me.socketOption);

    socket.connect();

    _getInitalSaveMessages();

    socket.onConnect((id) {
      _fetchConversations();
    });

    socket.onConnectError((data) {
      showToast("Unstable connection. Reconnecting...");
    });

// New message
    socket.on("new-message-v2", _newMessageHandler);

    // Message recieved
    socket.on("message-recieved", _messageRecievedHandler);

// Message read
    socket.on("message-read", _messageReadHandler);

// User blocked
    socket.on("user-blocked", _userBlockedHandler);

// User unblocked
    socket.on("user-unblocked", _userUnblockedHandler);

// Message deleted
    socket.on("message-deleted", _messageDeletedHandler);

// FCM
    fcmStream = FirebaseMessaging.onMessage
        .asBroadcastStream()
        .listen((event) => _fcmHandler(event.data));
// Background foreground
    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        _fetchConversations(true);
        _isForeground = true;
      } else {
        _isForeground = false;
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    socket.dispose();
    socket.disconnect();
    socket.clearListeners();
    socket.destroy();

    dd.cache.clear();

    fcmStream.cancel();
    _fGBGNotifierSubScription.cancel();
  }

  Future<void> _fetchConversations([bool? silent]) async {
    if (AppController.me.isGuest) return;
    if (silent != true) isLoading(true);
    hasFetchError(false);
    update();

    try {
      final res =
          await ApiService.getDio.get("/messaging-v2/get-conversations");

      if (res.statusCode == 200) {
        final data = (res.data as List).map((e) {
          try {
            final conv = ChatConversationV2.fromMap(e);

            return conv;
          } catch (e, trace) {
            Get.log("$e");
            Get.log("$trace");

            return null;
          }
        });

        conversations.clear();

        conversations.addAll(data.whereType<ChatConversationV2>().toList());

        for (var conv in data) {
          if (conv == null) return;

          final index = conversations.indexOf(conv);

          if (index == -1) {
            conversations.add(conv);
          } else {
            conversations[index].updateMessages(conv.messages);
          }
          conv.saveToStorage(conv.me.id);
        }
      } else {
        hasFetchError(true);
      }
    } on DioException catch (e) {
      if (e.message != null) showToast(e.message!);
      rethrow;
    } catch (e) {
      hasFetchError(true);
      Get.log("$e");
    } finally {
      isLoading(false);
      _sortConversations();
      update();
    }
  }

  void _messageDeletedHandler(data) {
    final key = data["key"];

    final conv = conversations.firstWhereOrNull((e) => e.key == key);
    if (conv == null) return;

    final messageId = data["messageId"];

    final index = conv.messages.indexWhere((m) => m.id == messageId);

    if (index == -1) {
      Get.log("Wrong message deleted index : messageId : $messageId");
    } else {
      conv.messages[index].isDeletedForAll = true;
    }

    if (ChatConversationV2.onChatEventCallback != null) {
      ChatConversationV2.onChatEventCallback!("message-deleted", data, key);
    }
    update();
  }

  void _userUnblockedHandler(data) {
    final key = data["key"];
    final conv = conversations.firstWhereOrNull((e) => e.key == key);
    if (conv == null) return;
    conv.blocks.removeWhere((e) => e == data["userId"]);

    if (ChatConversationV2.onChatEventCallback != null) {
      ChatConversationV2.onChatEventCallback!("user-unblocked", data, key);
    }
    update();
  }

  void _userBlockedHandler(data) {
    final key = data["key"];

    final conv = conversations.firstWhereOrNull((e) => e.key == key);

    if (conv == null) return;

    conv.blocks.add(data["userId"]);

    if (ChatConversationV2.onChatEventCallback != null) {
      ChatConversationV2.onChatEventCallback!("user-blocked", data, key);
    }

    update();
  }

  void _messageReadHandler(data) {
    final key = data["key"];

    final conv = conversations.firstWhereOrNull((e) => e.key == key);
    if (conv == null) return;

    conv.markMyMessagesAsRead();

    update();

    if (ChatConversationV2.onChatEventCallback != null) {
      ChatConversationV2.onChatEventCallback!("message-read", data, key);
    }
  }

  void _messageRecievedHandler(data) {
    final key = data["key"];

    final conv = conversations.firstWhereOrNull((e) => e.key == key);
    if (conv == null) return;

    conv.markMyMessagesAsRecieved();

    update();

    if (ChatConversationV2.onChatEventCallback != null) {
      ChatConversationV2.onChatEventCallback!("message-recieved", data, key);
    }
  }

  void _handleMarkAsReadReplySuceeded(data) {
    final key = data["key"];

    final conv = conversations.firstWhereOrNull((e) => e.key == key);
    if (conv == null) return;

    conv.markOthersMessagesAsRead();

    update();

    if (ChatConversationV2.onChatEventCallback != null) {
      ChatConversationV2.onChatEventCallback!("message-recieved", data, key);
    }
  }

  // When message is replied from notification tray,
  // The server will new an event with a new message
  void _handleReplyMessageSuceeded(data) {
    final key = data["key"];

    final conv = conversations.firstWhereOrNull((e) => e.key == key);
    if (conv == null) return;

    final chatMessage = ChatMessageV2.fromJson(data["message"]);

    conv.messages.add(chatMessage);

    conv.markOthersMessagesAsRead();

    update();

    // if (ChatConversationV2.onChatEventCallback != null) {
    //   ChatConversationV2.onChatEventCallback!("message-recieved", data, key);
    // }
  }

  void _newMessageHandler(data) async {
    try {
      final msg = ChatMessageV2.fromMap(data["message"]);

      final key = ChatConversationV2.createKey(
        AppController.me.id,
        msg.senderId,
      );

      final ChatConversationV2 conv;

      final c = conversations.firstWhereOrNull((c) => c.key == key);

      if (c != null) {
        conv = c;
      } else {
        final other = await ApiService.fetchUser(msg.senderId);

        if (other == null) {
          Get.log("Failed to get user data on new message");
          return;
        }

        conv = ChatConversationV2(
          key: key,
          first: AppController.me,
          second: other,
          messages: [],
          createdAt: msg.createdAt,
          blocks: [],
        );

        conversations.insert(0, conv);
      }

      conv.messages.add(msg);

      await conv.saveToStorage(msg.recieverId);
      conv.markMyMessagesAsRecieved();

      socket.emitWithAck(
        "message-recieved",
        {"messageId": msg.id, "key": key},
        ack: (data) {},
      );

      if (ChatConversationV2.onChatEventCallback != null) {
        conv.markOthersMessagesAsRead();
        ChatConversationV2.onChatEventCallback!("new-message-v2", data, key);
      }
      if (!_isForeground || ChatConversationV2.onChatEventCallback == null) {
        try {
          final id = await LocalNotificationController.showNotification(
            conv.other.fullName,
            msg.content ?? msg.typedMessage,
            payload: msg.createLocalNotificationPayload(key),
            category: AppNotificationCategory.messaging,
            groupKey: conv.other.fullName,
          );

          conv.localNotificationsIds.add(id);
        } catch (e, trace) {
          Get.log("$e");
          Get.log("$trace");
        }
      }

      _sortConversations();

      update();
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }

  void _fcmHandler(Map<String, dynamic> data) {
    switch (data["event"]) {
      case "new-message-v2":
        _newMessageHandler({...data, "message": jsonDecode(data["message"])});

      case "message-read":
        _messageReadHandler(data);

      case "mark-as-read-succeded":
        _handleMarkAsReadReplySuceeded(data);

        break;
      case "message-reply-succeded":
        _handleReplyMessageSuceeded(data);

        break;

      default:
    }
  }

  void _sortConversations() {
    conversations.sort((a, b) {
      if (a.lastMessage == null) return 1;
      if (b.lastMessage == null) return 1;

      return b.lastMessage!.createdAt.compareTo(a.lastMessage!.createdAt);
    });
  }
}

class ChatConversationsTab extends StatelessWidget
    implements HomeScreenSupportable {
  const ChatConversationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ConversationsController());

    return GetBuilder<_ConversationsController>(builder: (context) {
      return Stack(
        children: [
          Builder(
            builder: (context) {
              if (controller.hasFetchError.isTrue) {
                return const Center(
                  child: Text(
                    "Failed to load chats. Please refresh",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              if (controller.conversations.isEmpty) {
                return const Center(
                  child: Text(
                    "No Chat for now",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final data = controller.conversations
                  .where((c) => c.messages.isNotEmpty)
                  .toList();

              return ListView.builder(
                itemBuilder: (context, index) {
                  final conv = data[index];

                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 10, right: 10),
                    onTap: () async {
                      // print(conv.messages
                      //     .map((e) => (e.recieveds, e.isRecieved)));
                      // return;
                      await moveToChatRoom(conv.first, conv.second);

                      controller._sortConversations();
                      conv.markOthersMessagesAsRead();
                      controller.update();
                    },
                    leading: conv.other.ppWidget(size: 22),
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
                                msg.content ?? "Sent a ${msg.type}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (msg.isMine && msg.isRead)
                              const Icon(
                                Icons.done_all,
                                color: Colors.blue,
                                size: 16,
                              )
                            else if (msg.isMine && msg.isRecieved)
                              const Icon(
                                Icons.done_all,
                                color: Colors.grey,
                                size: 16,
                              )
                            else if (msg.isMine)
                              const Icon(
                                Icons.done,
                                color: Colors.grey,
                                size: 16,
                              ),
                            if (conv.unReadMessageCount > 0)
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                ),
                                child: Text("${conv.unReadMessageCount}"),
                              ),
                          ],
                        );
                      },
                    ),
                    // trailing: SizedBox(
                    //   width: 40,
                    //   child: IconButton(
                    //     onPressed: () {
                    //       print(conv.messages.map((e) => e.reads).toList());
                    //     },
                    //     icon: const Icon(CupertinoIcons.ellipsis_vertical),
                    //   ),
                    // ),
                  );
                },
                itemCount: data.length,
              );
            },
          ),
          if (controller.isLoading.isTrue) const LoadingPlaceholder()
        ],
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
        GetBuilder<_ConversationsController>(builder: (controller) {
          return IconButton(
            onPressed: controller.isLoading.isTrue
                ? null
                : controller._fetchConversations,
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
        icon: GetBuilder<_ConversationsController>(builder: (controller) {
          var badge = controller.unReadMessagesCount;
          return Badge(
            badgeContent: Text(badge.toString()),
            showBadge: badge > 0,
            child: Image.asset(
              "assets/icons/chat.png",
              height: 30,
              width: 30,
              color: ROOMY_PURPLE,
            ),
          );
        }),
        isCurrent: isCurrent,
      ),
      label: 'Chats',
    );
  }

  @override
  FloatingActionButton? get floatingActionButton => null;

  @override
  void onIndexSelected(int index) {
    final controller = Get.put(_ConversationsController());

    controller._sortConversations();
    controller.update();
  }
}
