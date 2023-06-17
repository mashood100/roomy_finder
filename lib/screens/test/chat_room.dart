import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/chat_message_v2.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/classes/chat_conversation_v2.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

class _ChatRoomController extends LoadingController {
  late IO.Socket socket;

  _ChatRoomController(this.conversation);

  late final ScrollController _scrollController;
  late final TextEditingController _newMessageController;

  final ChatConversationV2 conversation;
  final List<ChatMessageV2> messages = [];

  DateTime lastReadDate = DateTime.now();
  DateTime lastRecievedDate = DateTime.now();

  final FocusNode focusNode = FocusNode();

  User get me => conversation.me;
  User get other => conversation.other;
  String get newMessageTitle => me.fullName;
  ChatMessageV2? get lastMessage => conversation.lastMessage;

  @override
  void onInit() {
    super.onInit();

    _scrollController = ScrollController();
    _newMessageController = TextEditingController();

    final socketBuuildOptions =
        IO.OptionBuilder().disableAutoConnect().setAuth({
      "userId": AppController.me.id,
      "password": AppController.me.password,
    }).setTransports(["websocket"]).build();

    socket = IO.io(SERVER_URL, socketBuuildOptions);

    socket.connect();

    _fetchMessages();

    // new Message

    socket.on("new-message", (data) {
      try {
        final msg = ChatMessageV2.fromMap(data);

        if (ChatConversationV2.currrentChatKey == conversation.key) {
          msg.reads.add({"userId": me.id, "date": DateTime.now()});
          msg.recieveds.add({"userId": me.id, "date": DateTime.now()});
          socket.emit("message-read", msg.id);

          messages.insert(0, msg);

          update();
          showToast("new message");

          _scrollDown();
        }
      } catch (e, trace) {
        Get.log("$e");
        Get.log("$trace");
      }
    });

    // Message recieved
    socket.on("message-recieved", (data) {
      final messageId = data["messageId"];
      final userId = data["userId"];

      final index = messages.indexWhere((m) => m.id == messageId);

      if (index == -1) {
        Get.log("Wrong message recieved index : messageId : $messageId");
      } else {
        messages[index]
            .recieveds
            .add({"userId": userId, "date": DateTime.now()});

        lastReadDate = messages[index].createdAt;
        update();
      }
    });

    // Message read
    socket.on("message-read", (data) {
      final messageId = data["messageId"];
      final userId = data["userId"];

      final index = messages.indexWhere((m) => m.id == messageId);

      if (index == -1) {
        Get.log("Wrong message read index : messageId : $messageId");
      } else {
        messages[index].reads.add({"userId": userId, "date": DateTime.now()});
        lastReadDate = messages[index].createdAt;
        update();
      }
    });

    // Message delete
    socket.on("message-deleted", (data) {
      final messageId = data["messageId"];

      final index = messages.indexWhere((m) => m.id == messageId);

      if (index == -1) {
        Get.log("Wrong message deleted index : messageId : $messageId");
      } else {
        messages[index].isDeletedForAll = true;
        update();
      }
    });

    socket.onConnect((_) {
      Get.log("Socket conneted ID : ${socket.id}");
    });

    socket.onConnectError((data) {
      Get.log("Connection error...");
    });

    socket.onReconnect((data) {
      Get.log("Socket reconnecting...");
    });
  }

  @override
  void onClose() {
    super.onClose();
    _scrollController.dispose();
    _newMessageController.dispose();
    socket.dispose();
  }

  void _scrollDown() {
    _scrollController
        .animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.decelerate,
        )
        .then((value) => update());
  }

  void _sortMessages() {
    if (messages.isEmpty) return;
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _fetchMessages() async {
    if (AppController.me.isGuest) return;
    isLoading(true);
    hasFetchError(false);
    update();
    socket.emitWithAck('get-messages', {
      "otherId": other.id,
      "lastDate": lastMessage?.createdAt.toIso8601String(),
    }, ack: (res) {
      try {
        final code = res["code"];

        if (code == 200) {
          final data = (res["data"] as List).map((e) {
            try {
              var m = ChatMessageV2.fromMap(e);
              if (m.isRead) lastReadDate = m.createdAt;
              if (m.isRecieved) lastReadDate = m.createdAt;
              return m;
            } catch (e) {
              Get.log("$e");
              return null;
            }
          });

          messages.addAll(data.whereType<ChatMessageV2>());
          _sortMessages();
          _scrollDown();
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

  // Send message
  void _sendTextMessage() {
    Map<String, dynamic> msg = {
      "type": "text",
      "content": _newMessageController.text,
      "recieverId": other.id,
    };

    socket.emitWithAck(
      "send-message",
      {"message": msg, "title": newMessageTitle},
      ack: (res) {
        if (res["code"] == 200) {
          final msg = ChatMessageV2.fromMap(res["message"]);

          messages.insert(0, msg);

          _newMessageController.clear();
          _scrollDown();

          update();
        } else {
          showToast("Failed to sent message");
        }
      },
    );
  }
}

class _ChatRoomScreen extends StatefulWidget {
  const _ChatRoomScreen({required this.conversation});

  final ChatConversationV2 conversation;

  @override
  State<_ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<_ChatRoomScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      _ChatRoomController(widget.conversation),
      tag: widget.conversation.key,
      // permanent: true,
    );
    return WillPopScope(
      onWillPop: () async {
        if (controller.messages.isNotEmpty) {
          ChatConversationV2.findConversation(widget.conversation.key)
              ?.lastMessage = controller.messages.last;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                foregroundImage:
                    widget.conversation.other.profilePicture != null
                        ? CachedNetworkImageProvider(
                            widget.conversation.other.profilePicture!,
                          )
                        : null,
                child: Text(widget.conversation.other.fullName[0]),
              ),
              const SizedBox(width: 10),
              GetBuilder<_ChatRoomController>(
                tag: widget.conversation.key,
                builder: (controller) {
                  return Text(controller.conversation.other.fullName);
                },
              )
            ],
          ),
        ),
        body: GetBuilder<_ChatRoomController>(
          tag: widget.conversation.key,
          builder: (controller) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom + 50,
              ),
              child: ListView.separated(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                controller: controller._scrollController,
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = controller.messages[index];
                  ChatMessageV2? previous;
                  ChatMessageV2? next;

                  if (index > 0) {
                    previous = controller.messages[index - 1];
                  }
                  if (index < controller.messages.length - 1) {
                    previous = controller.messages[index + 1];
                  }

                  return ChatMessageWidget(
                    author: msg.isMine ? controller.me : controller.other,
                    msg: msg,
                    lastReadDate: controller.lastReadDate,
                    lastRecievedDate: controller.lastRecievedDate,
                    previousMsg: previous,
                    nextMsg: next,
                  );
                },
                separatorBuilder: (context, index) {
                  final msg = controller.messages[index];

                  if (index == controller.messages.length - 1) {
                    return const SizedBox();
                  }

                  if (index > 0) {
                    ChatMessageV2 previous = controller.messages[index - 1];

                    var d1 = DateTime(
                      previous.createdAt.year,
                      previous.createdAt.month,
                      previous.createdAt.day,
                    );
                    var d2 = DateTime(
                      msg.createdAt.year,
                      msg.createdAt.month,
                      msg.createdAt.day,
                    );

                    if (d2.isAtSameMomentAs(d1)) return const SizedBox();
                  }

                  var diff2 = DateTime.now().difference(msg.createdAt);
                  String text;

                  var date = Jiffy.parseFromDateTime(msg.createdAt);

                  if (diff2.inDays < 365) {
                    text = date.MMMEd;
                  } else {
                    text = date.yMMMEd;
                  }
                  return Align(
                    alignment: Alignment.center,
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        color: Colors.black54,
                      ),
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        bottomSheet: GetBuilder<_ChatRoomController>(
          id: "send-button",
          tag: widget.conversation.key,
          builder: (controller) {
            return Container(
              color: Colors.green,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom,
              ),
              width: Get.width,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: "New message",
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                        ),
                        controller: controller._newMessageController,
                        onChanged: (val) {
                          controller.update(["send-button"]);
                        },
                        maxLines: 6,
                        minLines: 1,
                        onSubmitted: (value) {
                          if (value.isNotEmpty) controller._sendTextMessage();
                        },
                        textInputAction: TextInputAction.send,
                        focusNode: controller.focusNode,
                        onEditingComplete: () {},
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: controller._newMessageController.text.isEmpty
                        ? null
                        : controller._sendTextMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  const ChatMessageWidget({
    super.key,
    required this.author,
    required this.msg,
    required this.lastReadDate,
    required this.lastRecievedDate,
    this.previousMsg,
    this.nextMsg,
  });

  final User author;
  final ChatMessageV2 msg;
  final ChatMessageV2? previousMsg;
  final ChatMessageV2? nextMsg;
  final DateTime lastReadDate;
  final DateTime lastRecievedDate;

  String get formattedDate {
    var diff = DateTime.now().difference(msg.createdAt);
    var x = Jiffy.parseFromDateTime(msg.createdAt);
    if (diff.inDays < 1) {
      return x.Hm;
    }
    return relativeTimeText(msg.createdAt);
  }

  bool get isRead {
    if (lastReadDate.isAfter(msg.createdAt)) return true;
    return msg.isRead;
  }

  bool get isRecieved {
    if (lastRecievedDate.isAfter(msg.createdAt)) return true;
    return msg.isRecieved;
  }

  bool get isDeleted {
    return msg.isDeletedForAll;
  }

  bool get isPreviousAuthor {
    return previousMsg?.senderId != author.id;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: Get.width * 0.7, minWidth: 100),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomRight: Radius.circular(msg.isMine ? 0 : 10),
            bottomLeft: Radius.circular(msg.isMine ? 10 : 0),
          ),
          color: msg.isMine ? const Color(0xFF6C3A28) : const Color(0xFF13334D),
        ),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        margin: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg.content ?? "Sent a ${msg.type}",
              style: const TextStyle(color: Colors.white),
            ),
            // const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.isMine)
                  Builder(
                    builder: (context) {
                      if (isRead) {
                        return const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              color: Colors.blue,
                              size: 15,
                            ),
                            Icon(
                              Icons.check_rounded,
                              color: Colors.blue,
                              size: 15,
                            ),
                          ],
                        );
                      } else if (isRecieved) {
                        return const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              color: Colors.grey,
                              size: 15,
                            ),
                            Icon(
                              Icons.check_rounded,
                              color: Colors.grey,
                              size: 15,
                            ),
                          ],
                        );
                      } else {
                        return const Icon(
                          Icons.check_rounded,
                          color: Colors.grey,
                          size: 15,
                        );
                      }
                    },
                  ),
                const SizedBox(width: 5),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> moveToChatRoom(BuildContext context, User other) async {
  final key = "${AppController.me.id}-${other.id}";

  final ChatConversationV2 conv = ChatConversationV2.findConversation(key) ??
      ChatConversationV2(other: other);

  ChatConversationV2.currrentChatKey = key;

  await Get.to(() => _ChatRoomScreen(conversation: conv));

  conv.haveUnreadMessage = false;

  ChatConversationV2.currrentChatKey = null;
  ChatConversationV2.currrentChatOnTapCallBack = null;
}
