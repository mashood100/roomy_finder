import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

import 'package:roomy_finder/classes/file_helprer.dart';
import 'package:roomy_finder/components/color_animated_text.dart';
import 'package:roomy_finder/components/message.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/controllers/local_notifications.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/chat_conversation_v2.dart';
import 'package:roomy_finder/models/chat_message_v2.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/models/user.dart';
import 'package:roomy_finder/screens/chat/chat_room_helper.dart';
import 'package:roomy_finder/classes/voice_note_player_helper.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:socket_io_client/socket_io_client.dart';

part './chat_room_controller.dart';

class _ChatRoomScreen extends StatelessWidget {
  const _ChatRoomScreen({
    required this.conversation,
    this.initialRoommateAd,
    this.initialBooking,
  });

  final ChatConversationV2 conversation;
  final RoommateAd? initialRoommateAd;
  final PropertyBooking? initialBooking;

  @override
  Widget build(BuildContext context) {
    Get.put(
      _ChatRoomController(
        conversation,
        initialRoommateAd: initialRoommateAd,
        initialBooking: initialBooking,
      ),
      tag: conversation.key,
    );

    return GetBuilder<_ChatRoomController>(
      tag: conversation.key,
      builder: (controller) {
        return Scaffold(
          // backgroundColor: Colors.white70,
          appBar: AppBar(
            leading: BackButton(
              onPressed: () {
                if (controller.isSelectMode.isTrue) {
                  controller.isSelectMode(false);
                  controller.update();
                } else {
                  Get.back();
                }
              },
            ),
            leadingWidth: 40,
            title: controller.isSelectMode.isFalse
                ? Row(
                    children: [
                      conversation.other.ppWidget(size: 20, borderColor: false),
                      const SizedBox(width: 10),
                      GetBuilder<_ChatRoomController>(
                        tag: conversation.key,
                        builder: (controller) {
                          return Text(controller.conversation.other.fullName);
                        },
                      )
                    ],
                  )
                : Text("${controller.selectedMessages.length}"),
            actions: controller.isSelectMode.isTrue
                ? [
                    if (controller.selectedMessages.length == 1 &&
                        controller.selectedMessages.first.content != null)
                      IconButton(
                        onPressed: () {
                          controller.isSelectMode(false);
                          controller.update();

                          Clipboard.setData(
                            ClipboardData(
                              text: controller.selectedMessages.first.content!,
                            ),
                          );

                          controller.selectedMessages.clear();
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    IconButton(
                      onPressed: () {
                        for (var item in controller.messages) {
                          if (!controller.selectedMessages.contains(item)) {
                            controller.selectedMessages.add(item);
                          }
                        }

                        controller.update();
                      },
                      icon: const Icon(Icons.select_all),
                    ),
                    IconButton(
                      onPressed: () {
                        controller.selectedMessages.clear();
                        controller.isSelectMode(false);
                        controller.update();
                      },
                      icon: const Icon(Icons.close),
                    ),
                    IconButton(
                      onPressed: controller._deleteMessages,
                      icon: const Icon(Icons.delete),
                    ),
                  ]
                : [
                    PopupMenuButton<String?>(
                      onOpened: () {
                        controller.focusNode.unfocus();
                      },
                      onSelected: controller._handlePopUpMenu,
                      itemBuilder: (ctx) {
                        return [
                          if (controller.conversation.iHaveBlocked)
                            PopupMenuItem<String?>(
                              value: 'unblock-user',
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(),
                                leading: const Icon(
                                  Icons.block,
                                  color: Colors.grey,
                                ),
                                dense: true,
                                title: Text(
                                  "Unblock ${controller.other.fullName}",
                                ),
                              ),
                            )
                          else
                            PopupMenuItem<String?>(
                              value: 'block-user',
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(),
                                leading:
                                    const Icon(Icons.block, color: Colors.red),
                                dense: true,
                                title: Text(
                                  "Block ${controller.other.fullName}",
                                ),
                              ),
                            )
                        ];
                      },
                    )
                  ],
          ),
          body: GestureDetector(
            onTap: controller.focusNode.unfocus,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom + 50,
                  ),
                  child: ScrollablePositionedList.builder(
                    initialScrollIndex: controller.messages.isEmpty
                        ? 0
                        : controller.messages.length - 1,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemScrollController: controller._scrollController,
                    itemCount: controller.messages.length,
                    addAutomaticKeepAlives: true,
                    itemBuilder: (context, index) {
                      if (index < 0) {
                        if (controller.messages.isNotEmpty) {
                          index = 0;
                        } else {
                          return const SizedBox();
                        }
                      }

                      final msg = controller.messages[index];

                      if (msg.isDeleted) return const SizedBox();

                      ChatMessageV2? previous;
                      ChatMessageV2? next;
                      ChatMessageV2? repliedMessage;

                      if (index > 0) {
                        previous = controller.messages[index - 1];
                      }
                      if (index < controller.messages.length - 1) {
                        previous = controller.messages[index + 1];
                      }

                      if (msg.replyId != null) {
                        repliedMessage = controller.messages
                            .firstWhereOrNull((e) => e.id == msg.replyId);
                      }

                      return SizedBox(
                        width: MediaQuery.of(context).size.width - 20,
                        child: ChatMessageV2Widget(
                          author: msg.isMine ? controller.me : controller.other,
                          msg: msg,
                          previousMsg: previous,
                          nextMsg: next,
                          repliedMessage: repliedMessage,
                          isSelectMode: controller.isSelectMode.isTrue,
                          isSelected: controller.selectedMessages.contains(msg),
                          onSelectionChanged: (val) {
                            if (val == true) {
                              controller.selectedMessages.add(msg);
                            } else {
                              controller.selectedMessages.remove(msg);
                            }

                            if (controller.selectedMessages.isEmpty) {
                              controller.isSelectMode(false);
                            }

                            controller.update();
                          },
                          onSweepToReply: (msg) {
                            controller.repliedMessage = msg;
                            controller.update(["bottom-widget"]);
                          },
                          onLongPress: (msg) {
                            controller.focusNode.unfocus();
                            controller.selectedMessages.add(msg);
                            controller.isSelectMode(true);

                            controller.update();
                          },
                          onRepliedMessageTapped: (msg) {
                            final index = controller.messages.indexOf(msg);

                            if (index != -1) {
                              controller._scrollController.scrollTo(
                                index: index,
                                duration: const Duration(milliseconds: 200),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (controller.uploadTasks.isNotEmpty)
                  Container(
                    color: Get.theme.appBarTheme.backgroundColor,
                    child: GetBuilder<_ChatRoomController>(
                      id: 'upload-tasks',
                      tag: conversation.key,
                      builder: (controller) {
                        final max = controller.uploadTasks.length > 1
                            ? 1
                            : controller.uploadTasks.length;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < max; i++)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [controller.uploadTasks[i]],
                              ),
                            if (controller.uploadTasks.length > 1)
                              Row(
                                children: [
                                  Text(
                                    "  + ${controller.uploadTasks.length - 1} operations",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    height: 35,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: const Text(
                                        "Cancel All",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    height: 35,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: const Text(
                                        "See All",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          bottomSheet: GetBuilder<_ChatRoomController>(
            id: "bottom-widget",
            tag: conversation.key,
            builder: (controller) {
              if (controller.conversation.iAmBlocked ||
                  controller.conversation.iHaveBlocked) {
                return Container(
                  color: ROOMY_ORANGE,
                  padding: const EdgeInsets.all(12),
                  width: Get.width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.conversation.iAmBlocked)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: controller.other.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(text: " blocked you."),
                            ],
                          ),
                        ),
                      if (controller.conversation.iHaveBlocked)
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: "You blocked "),
                              TextSpan(
                                text: controller.other.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(text: ". Unblock to chat."),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }
              return _BottomInputWidget(controller: controller);
            },
          ),
        );
      },
    );
  }
}

class _BottomInputWidget extends StatelessWidget {
  const _BottomInputWidget({required this.controller});

  final _ChatRoomController controller;

  @override
  Widget build(BuildContext context) {
    ChatMessageV2? rpMsg = controller.repliedMessage;

    return Container(
      color: ROOMY_PURPLE,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
      width: Get.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rpMsg != null)
            Container(
              margin: const EdgeInsets.all(5.0),
              padding: const EdgeInsets.all(5.0),
              decoration: const BoxDecoration(
                color: ROOMY_PURPLE,
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rpMsg.content ?? rpMsg.typedMessage,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      controller.repliedMessage = null;
                      controller.update(["bottom-widget"]);
                    },
                    child: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
            ),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              if (controller._voiceRecoder.isRecording)
                Obx(() {
                  return Container(
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.red.shade200],
                      ),
                    ),
                    width: controller._voiceRecoderDragOffset.value + 35,
                    height: 40,
                  );
                }),
              Row(
                crossAxisAlignment:
                    controller._newMessageController.text.isEmpty
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.end,
                children: [
                  Builder(builder: (context) {
                    var time = controller._recordDuration;
                    var sec = (time.inSeconds - time.inMinutes * 60)
                        .toString()
                        .padLeft(2, "0");

                    if (controller._voiceRecoder.isRecording) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "${time.inMinutes}:$sec",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: controller.uploadTasks.isNotEmpty
                          ? null
                          : controller._sendMedia,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.all(3),
                        child:
                            const Icon(Icons.attach_file, color: ROOMY_PURPLE),
                      ),
                    );
                  }),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedOpacity(
                          opacity: controller._voiceRecoder.isRecording ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  controller._newMessageController.text.isEmpty
                                      ? 0
                                      : 5,
                            ),
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: "New message",
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 7,
                                  horizontal: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              controller: controller._newMessageController,
                              onChanged: (val) {
                                controller.update(["bottom-widget"]);
                              },
                              maxLines: 6,
                              minLines: 1,

                              // textInputAction: TextInputAction.send,
                              focusNode: controller.focusNode,
                              onEditingComplete: () {},
                            ),
                          ),
                        ),
                        if (controller._voiceRecoder.isRecording)
                          const OpacityAnimatedText(
                            child: Text(
                              "Swipe left to cancel",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (controller._newMessageController.text.isEmpty)
                    GestureDetector(
                      onTapDown: (details) {
                        if (controller._voiceRecoder.isRecording) {
                          controller._stopVoiceRecord(true);
                        } else {
                          controller._startVoiceRecord();
                        }
                        controller.update(["bottom-widget"]);
                      },
                      onTapUp: (details) {
                        if (controller._voiceRecoderDragOffset.value > 100) {
                          controller._stopVoiceRecord(false);
                        } else {
                          controller._stopVoiceRecord(true);
                        }

                        controller._voiceRecoderDragOffset(0);
                      },
                      // onTapCancel: () {
                      //   controller._stopVoiceRecord(false);
                      // },
                      onHorizontalDragEnd: (details) {
                        if (controller._voiceRecoderDragOffset.value > 100) {
                          controller._stopVoiceRecord(false);
                        } else {
                          controller._stopVoiceRecord(true);
                        }

                        controller._voiceRecoderDragOffset(0);
                      },
                      onHorizontalDragUpdate: (details) {
                        if (details.localPosition.dx.isNegative) {
                          controller._voiceRecoderDragOffset(
                              details.localPosition.dx.abs());
                        }
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.all(3),
                        child: Icon(
                          controller._voiceRecoder.isRecording
                              ? Icons.send
                              : Icons.mic,
                          color: ROOMY_PURPLE,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: controller._newMessageController.text.isEmpty
                          ? null
                          : () {
                              controller._sendMessage(
                                {
                                  "type": "text",
                                  "content":
                                      controller._newMessageController.text,
                                  "recieverId": controller.other.id,
                                },
                              );
                            },
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.all(3),
                        child: const Icon(Icons.send, color: ROOMY_PURPLE),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> moveToChatRoom(
  User first,
  User second, {
  RoommateAd? roommateAd,
  PropertyBooking? booking,
}) async {
  try {
    final key = ChatConversationV2.createKey(first.id, second.id);

    var conv =
        ChatConversationV2.conversations.firstWhereOrNull((e) => e.key == key);

    conv ??= ChatConversationV2(
      key: key,
      first: first,
      second: second,
      messages: [],
      blocks: [],
    );

    if (Get.currentRoute == "/_ChatRoomScreen") {
      await Get.off(
        () => _ChatRoomScreen(
          conversation: conv!,
          initialRoommateAd: roommateAd,
          initialBooking: booking,
        ),
        transition: Transition.fadeIn,
        preventDuplicates: false,
      );
    } else {
      await Get.to(() => _ChatRoomScreen(
            conversation: conv!,
            initialRoommateAd: roommateAd,
            initialBooking: booking,
          ));
    }

    ChatConversationV2.onChatEventCallback = null;
  } catch (e, trace) {
    Get.log("$e");
    Get.log("$trace");
  }
}