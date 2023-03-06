// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/controllers/app_controller.dart';

import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/functions/utility.dart';
import 'package:roomy_finder/models/message.dart';

class _ChatController extends GetxController {
  final ChatConversation conversation;
  final newMessageController = TextEditingController();

  final isSending = false.obs;

  _ChatController(this.conversation);

  @override
  void onInit() {
    conversation.updateChatInfo();
    super.onInit();

    FirebaseMessaging.onMessage.asBroadcastStream().listen((event) {
      final data = event.data;

      if (data["event"] == "new-message") {
        try {
          final msg = Message.fromJson(data["jsonMessage"]);
          final key = ChatConversation.createConvsertionKey(
              conversation.me.id, msg.sender.id);
          if (key == conversation.key) {
            conversation.newMessageFromContent(msg.content, false);
            conversation.saveChat();
          }

          AppController.instance.haveNewMessage(false);

          update();
        } catch (e) {
          Get.log('$e');
        }
      }
    });
  }

  @override
  void onClose() {
    newMessageController.dispose();
    super.onClose();
  }

  Future<void> clearChat() async {
    final shouldClear = await showConfirmDialog(
      "Do you really want to clear the conversation?",
    );

    if (shouldClear == true) {
      conversation.messages.clear();
      conversation.saveChat();
      update();
    }
  }

  Future<void> sendMessage() async {
    try {
      isSending(true);
      if (newMessageController.text.trim().isEmpty) return;

      final message = Message.fomNow(
        content: newMessageController.text,
        sender: AppController.me,
      );

      final res = await ApiService.getDio.post(
        '/messages',
        data: {
          "message": message.toMap(),
          "reciverId": conversation.friend.id,
        },
      );

      if (res.statusCode == 200) {
        conversation.newMessageFromContent(newMessageController.text, true);
        newMessageController.clear();
        update();
        conversation.saveChat();
      } else if (res.statusCode == 404) {
        showToast("Failed to send message, Reciever account not found");
      } else {
        showToast("Failed to send message");
      }
    } catch (e) {
      Get.log("$e");
    } finally {
      isSending(false);
    }
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_ChatController(conversation));
    return Obx(() {
      return Scaffold(
        appBar: AppBar(
          title: Text("Chat with ${conversation.friend.firstName}"),
          actions: [
            IconButton(
              onPressed: controller.conversation.messages.isEmpty
                  ? null
                  : controller.clearChat,
              icon: const Icon(Icons.delete_sweep),
            )
          ],
        ),
        body: GetBuilder<_ChatController>(
          builder: (controller) {
            return Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(
                right: 5,
                left: 5, top: 5,
                // bottom: MediaQuery.of(context).viewInsets.bottom,
                bottom: 60,
              ),
              child: controller.conversation.messages.isEmpty
                  ? Center(child: Text('No messages'.tr))
                  : ListView.builder(
                      // controller: controller.conversation.messagesListController,
                      itemBuilder: (context, index) {
                        final msg = conversation.messages[index];

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!msg.sentByMe)
                              msg.sender.ppWidget(size: 20, borderColor: false)
                            else
                              const SizedBox(width: 40),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(
                                    right: 5, left: 5, bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomRight: const Radius.circular(10),
                                    bottomLeft: const Radius.circular(10),
                                    topRight: msg.sentByMe
                                        ? const Radius.circular(0)
                                        : const Radius.circular(10),
                                    topLeft: !msg.sentByMe
                                        ? const Radius.circular(0)
                                        : const Radius.circular(10),
                                  ),
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          msg.sender.fullName,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                          ),
                                        ),
                                        Text(
                                          relativeTimeText(
                                              msg.createdAt.toUtc()),
                                          style: Get.theme.textTheme.bodySmall!
                                              .copyWith(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      msg.content,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            if (msg.sentByMe)
                              msg.sender.ppWidget(size: 20, borderColor: false)
                            else
                              const SizedBox(width: 40),
                          ],
                        );
                      },
                      itemCount: conversation.messages.length,
                    ),
            );
          },
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          padding: const EdgeInsets.only(
            right: 10,
            left: 10,
          ),
          child: TextField(
            controller: controller.newMessageController,
            decoration: InputDecoration(
              border: InputBorder.none,
              suffixIcon: IconButton(
                onPressed: controller.isSending.isTrue
                    ? null
                    : () => controller.sendMessage(),
                icon: controller.isSending.isTrue
                    ? const CupertinoActivityIndicator()
                    : const Icon(Icons.send),
              ),
              hintText: 'New message'.tr,
            ),
            minLines: 1,
            maxLines: 6,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    });
  }
}
