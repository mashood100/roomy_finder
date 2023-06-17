import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/chat_message_v2.dart';
import 'package:roomy_finder/classes/chat_conversation_v2.dart';
import 'package:roomy_finder/screens/test/chat_room.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

class _ConversationsController extends LoadingController {
  late IO.Socket socket;

  List<ChatConversationV2> get conversations {
    return ChatConversationV2.conversations;
  }

  @override
  void onInit() {
    super.onInit();

    final socketBuuildOptions =
        IO.OptionBuilder().disableAutoConnect().setAuth({
      "userId": AppController.me.id,
      "password": AppController.me.password,
    }).setTransports(["websocket"]).build();

    socket = IO.io(SERVER_URL, socketBuuildOptions);

    socket.connect();

    socket.onConnect((_) {
      _fetchConversations();
    });

    socket.onConnectError((data) {
      isLoading(false);
      hasFetchError(true);
      update();
      Get.log("Connection failed...");
    });

    socket.onReconnect((data) {
      isLoading(false);
      hasFetchError(false);
      update();
    });

    socket.on("new-message", (data) async {
      try {
        final msg = ChatMessageV2.fromMap(data);

        final key = "${AppController.me.id}-${msg.senderId}";

        final ChatConversationV2 conv;

        final c = ChatConversationV2.findConversation(key);

        if (c != null) {
          conv = c;
        } else {
          final c2 = await ApiService.fetchUser(msg.senderId);

          if (c2 == null) {
            Get.log("Failed to get user data on new message");
            return;
          }

          conv = ChatConversationV2(other: c2);

          ChatConversationV2.addConversation(conv);
          ChatConversationV2.sortConversations();
        }

        if (ChatConversationV2.currrentChatKey != key) {
          msg.recieveds
              .add({"userId": AppController.me.id, "date": DateTime.now()});
          socket.emit("message-recieved", msg.id);

          conv.lastMessage = msg;
          conv.haveUnreadMessage = true;
        }

        update();
      } catch (e, trace) {
        Get.log("$e");
        Get.log("$trace");
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    socket.dispose();
  }

  Future<void> _fetchConversations({bool isRefresh = false}) async {
    if (AppController.me.isGuest) return;
    isLoading(true);
    hasFetchError(false);
    update();
    socket.emitWithAck('get-conversations', null, ack: (res) {
      try {
        final code = res["code"] as int;

        if (code == 200) {
          final data = (res["data"] as List).map((e) {
            try {
              final conv = ChatConversationV2.fromMap(e);
              if (conv.lastMessage?.isRead == false) {
                conv.haveUnreadMessage = true;
              }

              return conv;
            } catch (e, trace) {
              Get.log("$e");
              Get.log("$trace");

              return null;
            }
          });

          ChatConversationV2.conversations.clear();
          ChatConversationV2.addAllConversations(
              data.whereType<ChatConversationV2>().toList());
          ChatConversationV2.sortConversations();
        } else {
          hasFetchError(true);
        }
      } catch (e) {
        Get.log("$e");
      } finally {
        isLoading(false);
        update();
      }
    });
  }

  void sendMessage(Map message) {
    socket.emitWithAck(
      "send-message",
      {"message": message},
    );
  }
}

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ConversationsController());

    return RefreshIndicator(
      onRefresh: () async {
        controller._fetchConversations(isRefresh: true);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Conversations")),
        body: GetBuilder<_ConversationsController>(builder: (context) {
          if (controller.hasFetchError.isTrue) {
            return Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text("Failed to load chats"),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: controller.isLoading.isTrue
                        ? null
                        : () => controller._fetchConversations(isRefresh: true),
                    label: const Text("Reload"),
                    icon: Builder(builder: (context) {
                      if (controller.isLoading.isTrue) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CupertinoActivityIndicator(),
                        );
                      }
                      return const Icon(Icons.refresh);
                    }),
                  ),
                  const Spacer(),
                ],
              ),
            );
          }
          if (controller.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("No Chat for now"),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: controller.isLoading.isTrue
                        ? null
                        : () => controller._fetchConversations(isRefresh: true),
                    label: const Text("Reload"),
                    icon: Builder(builder: (context) {
                      if (controller.isLoading.isTrue) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CupertinoActivityIndicator(),
                        );
                      }
                      return const Icon(Icons.refresh);
                    }),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemBuilder: (context, index) {
              final conv = controller.conversations[index];

              return ListTile(
                contentPadding: const EdgeInsets.only(left: 10, right: 10),
                onTap: () async {
                  conv.haveUnreadMessage = false;

                  await moveToChatRoom(context, conv.other);

                  ChatConversationV2.sortConversations();
                  controller.update();
                },
                leading: CircleAvatar(
                  radius: 20,
                  foregroundImage: conv.other.profilePicture != null
                      ? CachedNetworkImageProvider(conv.other.profilePicture!)
                      : null,
                  child: Text(conv.other.fullName[0].toUpperCase()),
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
                            msg.content ?? "",
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
                        else if (conv.haveUnreadMessage)
                          const Icon(
                            Icons.circle,
                            color: Colors.blue,
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
        }),
      ),
    );
  }
}
