import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:roomy_finder/classes/home_screen_supportable.dart';
import 'package:roomy_finder/controllers/notification_controller.dart';
import 'package:roomy_finder/functions/message.dart';
import 'package:roomy_finder/helpers/chat_events_helper.dart';
import 'package:roomy_finder/models/chat/chat_message_v2.dart';
import 'package:roomy_finder/screens/home/home.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:roomy_finder/utilities/isar.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as dd;

import 'package:roomy_finder/components/loading_placeholder.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loading_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/chat/chat_conversation_v2.dart';
import 'package:roomy_finder/screens/chat/chat_room/chat_room_screen.dart';

class _ConversationsController extends LoadingController {
  late final Socket socket;

  late final StreamSubscription<RemoteMessage> _fcmStream;
  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;
  late final StreamSubscription<ChatEventStreamData> _chatEventsSubscription;

  final conversations = <ChatConversationV2>[].obs;

  void _setUnreadMessagesCount() {
    var conversations = ISAR
        .txnSync(() =>
            ISAR.chatConversationV2s.filter().unReadMessageCountGreaterThan(0))
        .findAllSync()
        .where((e) => e.first.value != null && e.second.value != null);

    if (conversations.isEmpty) {
      Home.unreadMessagesCount(0);
      update();
      return;
    }

    var count = conversations
        .map((e) => e.unReadMessageCount)
        .reduce((val, el) => val + el);

    Home.unreadMessagesCount(count);

    update();
  }

  void _notifyThatIHaveRecievedMessage(ChatMessageV2 lastM) {
    if (!lastM.reads.contains(AppController.me.id)) {
      socket.emitWithAck(
        "message-recieved",
        {"key": lastM.key, "messageId": lastM.id},
        ack: (_) {},
      );
    }
  }

  @override
  void onInit() {
    super.onInit();

    _syncMessages();

    socket = io(SERVER_URL, AppController.me.socketOption);

    socket.connect();

    _loadConversations();

    socket.onConnectError((data) {});

// New message
    socket.on(
      "new-message-v2",
      (data) => ChatEventHelper.newMessageHandler(data),
    );

    // Message recieved
    socket.on(
      "message-recieved",
      (data) => ChatEventHelper.messageRecievedHandler(data),
    );

// Message read
    socket.on(
      "message-read",
      (data) => ChatEventHelper.messageReadHandler(data),
    );

// User blocked
    socket.on(
      "user-blocked",
      (data) => ChatEventHelper.userBlockedHandler(data),
    );

// User unblocked
    socket.on(
      "user-unblocked",
      (data) => ChatEventHelper.userUnblockedHandler(data),
    );

// Message deleted
    socket.on(
      "message-deleted",
      (data) => ChatEventHelper.messageDeletedHandler(data),
    );

// FCM
    _fcmStream = FirebaseMessaging.onMessage
        .asBroadcastStream()
        .listen((event) => _fcmHandler(event.data));
// Background foreground

    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        _syncMessages();
        _loadConversations(isSilent: true);
        _setUnreadMessagesCount();
        AppController.isForeground = true;
      } else {
        ChatConversationV2.messagesAreSync = false;
        AppController.isForeground = false;
      }
    });

// Chat events
    _chatEventsSubscription = ChatEventHelper.stream.listen((event) async {
      await _loadConversations(isSilent: true);

      if (event.$1 == ChatEvents.newMessage) {
        if (event.$3 != null) {
          var lastM = conversations
              .firstWhereOrNull((e) => e.key == event.$2)
              ?.lastMessage
              .value;

          if (lastM != null && !lastM.recieveds.contains(lastM.recieverId)) {
            _notifyThatIHaveRecievedMessage(lastM);

            lastM.recieveds = List.from(lastM.recieveds)..add(lastM.recieverId);
            ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putSync(lastM));
          }
        }
      } else if (event.$1 == ChatEvents.userBlocked) {
        final conv = conversations.firstWhereOrNull((e) => event.$2 == e.key);

        if (conv == null) return;
        conv.blocks = List.from(conv.blocks)..add(conv.me.id);
      } else if (event.$1 == ChatEvents.userUnBlocked) {
        final conv = conversations.firstWhereOrNull((e) => event.$2 == e.key);

        if (conv == null) return;
        conv.blocks = List.from(conv.blocks)
          ..removeWhere((e) => e == conv.me.id);
      }

      update();
      _setUnreadMessagesCount();
    });
  }

  void _syncMessages() async {
    if (!ChatConversationV2.messagesAreSync) {
      await syncChatMessages();
    }

    await _loadConversations(isSilent: true);
    _setUnreadMessagesCount();
  }

  @override
  void onClose() {
    super.onClose();
    socket.dispose();
    socket.disconnect();
    socket.clearListeners();
    socket.destroy();

    dd.cache.clear();

    _fcmStream.cancel();
    _fGBGNotifierSubScription.cancel();
    _chatEventsSubscription.cancel();
  }

  void _fcmHandler(Map<String, dynamic> data) {
    switch (data["event"]) {
      // case "new-message-v2":
      //   _newMessageHandler({...data, "message": jsonDecode(data["message"])});

      case "message-read":
        ChatEventHelper.messageReadHandler(data);

      case "mark-as-read-succeded":
        ChatEventHelper.handleMarkAsReadReplySuceeded(data);

        break;
      case "message-reply-succeded":
        ChatEventHelper.replyMessageFromTraySuceeded(data);

        break;

      default:
    }
  }

  Future<void> _loadConversations({bool? isSilent}) async {
    try {
      if (isSilent != true) {
        isLoading(true);
      }
      update();

      var data = ISAR.txnSync(() => ISAR.chatConversationV2s
          .filter()
          .keyContains(AppController.me.id)
          .sortByCreatedAtDesc()
          .findAllSync());

      conversations
        ..clear()
        ..addAll(data);
    } on IsarError catch (e) {
      Get.log(e.message);
    } finally {
      if (isSilent != true) {
        isLoading(false);
      }

      conversations.sort(
        (a, b) {
          if (a.lastMessage.value == null) {
            return 1;
          }

          return b.lastMessage.value?.createdAt
                  .compareTo(a.lastMessage.value!.createdAt) ??
              -1;
        },
      );
      update();
    }
  }
}

class ChatConversationsTab extends StatelessWidget
    implements HomeScreenSupportable {
  const ChatConversationsTab({super.key});

  @override
  void onTabIndexSelected(int index) {
    final controller = Get.find<_ConversationsController>();

    controller._loadConversations(isSilent: true);
    controller.update();

    for (var id in ChatConversationV2.messagesNotificationIds) {
      NotificationController.plugin.cancel(id);
    }
    NotificationController.plugin.cancelAll();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ConversationsController());

    return GetBuilder<_ConversationsController>(builder: (context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: ROOMY_PURPLE,
          title: const Text('Chats'),
          centerTitle: false,
          elevation: 0,
        ),
        body: Stack(
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

                final data = controller.conversations;

                return ListView.builder(
                  itemBuilder: (context, index) {
                    final conv = data[index];

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 10, right: 10),
                      onTap: () {
                        conv.unReadMessageCount = 0;

                        moveToChatRoom(
                          conv.first.value!,
                          conv.second.value!,
                        ).then((value) {
                          controller._loadConversations();
                          controller._setUnreadMessagesCount();
                          controller.update();
                        });
                      },
                      leading: Hero(
                        tag: "${conv.other.id}profile-picture",
                        child: conv.other.ppWidget(size: 22),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            conv.other.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (conv.lastMessage.value != null)
                            Text(
                              relativeTimeText(
                                  conv.lastMessage.value!.createdAt,
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
                          final msg = conv.lastMessage.value;

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
                              if (msg.isMine &&
                                  (conv.lastMessage.value?.isRead == true ||
                                      msg.isRead))
                                const Icon(
                                  Icons.done_all,
                                  color: Colors.blue,
                                  size: 16,
                                )
                              else if (msg.isMine &&
                                  (conv.lastMessage.value?.isRecieved == true ||
                                      msg.isRecieved))
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
                    );
                  },
                  itemCount: data.length,
                );
              },
            ),
            if (controller.isLoading.isTrue) const LoadingPlaceholder()
          ],
        ),
        bottomNavigationBar: HomeBottomNavigationBar(
          onTap: (index) {
            if (index != 3) return;
            controller._setUnreadMessagesCount();
          },
        ),
      );
    });
  }
}
