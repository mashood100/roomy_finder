// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:roomy_finder/models/chat_message.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import "package:path/path.dart" as path;
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:just_audio/just_audio.dart';
import 'package:roomy_finder/models/chat_user.dart';

class FlyerChatScreenController extends GetxController
    with WidgetsBindingObserver {
  final ChatConversation conversation;
  final List<ChatMessage> messages = [];

  final _newMessageController = TextEditingController();

  final _isUploadingFile = false.obs;
  final _isSendingMessage = false.obs;
  final _canMakeVoice = true.obs;
  types.Message? _currentRepliedMessage;

  FlyerChatScreenController(this.conversation);

  late final AudioPlayer _audioPlayer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    conversation.loadMessages().then((msgs) {
      messages.clear();
      messages.addAll(msgs);
      update();
    });
    super.didChangeAppLifecycleState(state);
  }

  @override
  void onInit() {
    super.onInit();

    ChatConversation.currrentChatKey = conversation.key;
    ChatConversation.currrentChatOnTapCallBack = () {
      conversation.loadMessages().then((msgs) {
        messages.clear();
        messages.addAll(msgs);
        update();
      });
    };

    WidgetsBinding.instance.addObserver(this);

    conversation.loadMessages().then((msgs) {
      messages.clear();
      messages.addAll(msgs);
      update();
    });

    conversation.updateChatInfo().then((_) => update());

    _audioPlayer = AudioPlayer();

    FirebaseMessaging.onMessage.asBroadcastStream().listen((remoteMessage) {
      AppController.instance.haveNewMessage(false);

      if (remoteMessage.data["event"] == "new-message") {
        try {
          final payload = json.decode(remoteMessage.data["payload"]);

          final message = ChatMessage.fromMap(payload["message"]);

          final convKey = ChatConversation.createConvsertionKey(
            message.recieverId,
            message.senderId,
          );
          message.saveToSameKeyLocaleMessages(convKey);

          if (convKey == conversation.key && !messages.contains(message)) {
            messages.insert(0, message);
            update();
            _audioPlayer
                .setAsset("assets/audio/in_chat_new_message_sound.mp3")
                .then((value) => _audioPlayer.play());
          }
        } catch (e, trace) {
          Get.log('$e');
          Get.log('$trace');
        }
      }
    });
  }

  @override
  void onClose() {
    _newMessageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    ChatConversation.currrentChatKey = null;
    ChatConversation.currrentChatOnTapCallBack = null;
    conversation.saveChat();
    _audioPlayer.dispose();
    super.onClose();
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: Get.context!,
      builder: (BuildContext context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Select picture'),
              onTap: () {
                Navigator.pop(context);
                _handleMediaSelection(AttachedTypes.imageGallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Take picture'),
              onTap: () {
                Navigator.pop(context);
                _handleMediaSelection(AttachedTypes.imageCamera);
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.video_collection_rounded),
            //   title: const Text('Select video'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _handleMediaSelection(AttachedTypes.videoGallery);
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.video_camera_back_rounded),
            //   title: const Text('Record video'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     _handleMediaSelection(AttachedTypes.videoCammera);
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Send file'),
              onTap: () {
                Navigator.pop(context);
                _handleFileSelection();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancel'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        dialogTitle: "Pick a file",
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        _isUploadingFile(false);
        final file = result.files.first;

        if (file.size > 1024 * 1000000 * 10) return showToast("File too large");

        _isUploadingFile(true);

        final fileRef =
            FirebaseStorage.instance.ref().child('chat').child("files").child(
                  '${const Uuid().v4()}'
                  '${path.extension(result.files.first.path!)}',
                );

        final uploadTask =
            fileRef.putData(await File(result.files.first.path!).readAsBytes());

        final fileUrl = await (await uploadTask).ref.getDownloadURL();

        final res = await ApiService.getDio.post(
          '/messages/send',
          data: {
            "notificationTitle": conversation.me.fullName,
            "type": 'file',
            "body": "Sent a file",
            "recieverId": conversation.friend.id,
            "recieverFcmToken": conversation.friend.fcmToken,
            "fileUri": fileUrl,
            "fileName": file.name,
            "fileSize": file.size,
            "replyId": _currentRepliedMessage?.id,
          },
        );

        if (res.statusCode == 200) {
          final message = ChatMessage.fromMap(res.data)
            ..saveToSameKeyLocaleMessages(conversation.key);
          messages.insert(0, message);
          update();
          conversation.lastMessage = message;
          conversation.saveChat();
        } else if (res.statusCode == 404) {
          showToast("Failed to send message, Reciever account not found");
        } else {
          showToast("Failed to send message");
        }

        update();
      }
    } catch (e, trace) {
      Get.log("$trace");
      showToast("Failed to send image");
    } finally {
      _isUploadingFile(false);
    }
  }

  void _handleMediaSelection(AttachedTypes type) async {
    try {
      _isSendingMessage(true);
      final XFile? result;
      final String firesStoreChildRef;

      switch (type) {
        case AttachedTypes.imageGallery:
          result = await ImagePicker().pickImage(
            imageQuality: 70,
            maxWidth: 1440,
            source: ImageSource.gallery,
          );
          firesStoreChildRef = "images";
          break;
        case AttachedTypes.imageCamera:
          result = await ImagePicker().pickImage(
            imageQuality: 70,
            maxWidth: 1440,
            source: ImageSource.camera,
          );
          firesStoreChildRef = "images";
          break;
        case AttachedTypes.videoGallery:
          result = await ImagePicker().pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 10),
          );
          firesStoreChildRef = "videos";
          break;
        case AttachedTypes.videoCammera:
          result = await ImagePicker().pickVideo(
            source: ImageSource.camera,
            maxDuration: const Duration(minutes: 10),
          );
          firesStoreChildRef = "videos";
          break;
        default:
          result = null;
          firesStoreChildRef = "files";
      }
      if (result == null) return;
      _isUploadingFile(true);
      update();

      final bytes = await result.readAsBytes();

      final fileRef = FirebaseStorage.instance
          .ref()
          .child('chat')
          .child(firesStoreChildRef)
          .child('${const Uuid().v4()}${path.extension(result.path)}');

      final uploadTask = fileRef.putData(await File(result.path).readAsBytes());

      final fileUrl = await (await uploadTask).ref.getDownloadURL();
      _isUploadingFile(false);

      _isSendingMessage(true);

      final String messageType;

      switch (type) {
        case AttachedTypes.imageGallery:
        case AttachedTypes.imageCamera:
          messageType = "image";
          break;

        case AttachedTypes.videoGallery:
        case AttachedTypes.videoCammera:
          messageType = "video";
          break;
        default:
          return;
      }

      final res = await ApiService.getDio.post(
        '/messages/send',
        data: {
          "notificationTitle": conversation.me.fullName,
          "type": messageType,
          "body": "Sent a $messageType",
          "recieverId": conversation.friend.id,
          "recieverFcmToken": conversation.friend.fcmToken,
          "fileUri": fileUrl,
          "fileName": result.name,
          "fileSize": bytes.length,
          "replyId": _currentRepliedMessage?.id,
        },
      );

      if (res.statusCode == 200) {
        final message = ChatMessage.fromMap(res.data)
          ..saveToSameKeyLocaleMessages(conversation.key);
        messages.insert(0, message);
        update();
        conversation.lastMessage = message;
        conversation.saveChat();
      } else if (res.statusCode == 404) {
        showToast("Failed to send message, Reciever account not found");
      } else {
        showToast("Failed to send message");
      }

      _isSendingMessage(false);
    } catch (e, trace) {
      Get.log("$trace");
      showToast("Failed to send image");
    } finally {
      _isSendingMessage(false);
      update();
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    try {
      if (message is types.FileMessage) {
        var localPath = message.uri;

        if (message.uri.startsWith('http')) {
          try {
            update();

            final request = await Dio().get(
              message.uri,
              options: CacheOptions(
                store: MemCacheStore(),
                policy: CachePolicy.refresh,
                allowPostMethod: false,
              ).toOptions().copyWith(responseType: ResponseType.bytes),
            );

            final documentsDir =
                (await getApplicationDocumentsDirectory()).path;
            localPath = '$documentsDir/${message.name}';

            if (!File(localPath).existsSync()) {
              final file = File(localPath);
              await file.writeAsBytes(request.data);
            }
          } finally {
            // final index = conversation.messages
            //     .indexWhere((element) => element.id == message.id);
            // final updatedMessage =
            //     (conversation.messages[index] as types.FileMessage).copyWith(
            //   isLoading: null,
            // );

            // conversation.messages[index] = updatedMessage;
            // update();
          }
        }

        await OpenFilex.open(localPath);
      }
    } catch (e) {
      if (message is types.FileMessage) {
        showToast("Cannot open file");
      }
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    // final index =
    //     conversation.messages.indexWhere((element) => element.id == message.id);
    // final updatedMessage =
    //     (conversation.messages[index] as types.TextMessage).copyWith(
    //   previewData: previewData,
    // );

    // conversation.messages[index] = updatedMessage;
    update();
  }

  Future<void> _handleSendPressed(types.PartialText partialMessage) async {
    try {
      _isSendingMessage(true);
      update();

      final res = await ApiService.getDio.post(
        '/messages/send',
        data: {
          "notificationTitle": conversation.me.fullName,
          "type": 'text',
          "body": partialMessage.text,
          "recieverId": conversation.friend.id,
          "recieverFcmToken": conversation.friend.fcmToken,
          "replyId": _currentRepliedMessage?.id,
        },
      );

      if (res.statusCode == 200) {
        final message = ChatMessage.fromMap(res.data)
          ..saveToSameKeyLocaleMessages(conversation.key);
        messages.insert(0, message);
        conversation.lastMessage = message;
        conversation.saveChat();

        _newMessageController.clear();
        _canMakeVoice(true);
        _currentRepliedMessage = null;
        update();
      } else if (res.statusCode == 404) {
        showToast("Failed to send message, Reciever account not found");
      } else {
        showToast("Failed to send message");
      }
    } catch (e) {
      Get.log("$e");
      showToast("Failed to send messsage");
    } finally {
      _isSendingMessage(false);
      update();
    }
  }

  // User
  ChatUser get _user {
    final me = conversation.me;
    return ChatUser(
      id: me.id,
      firstName: me.firstName,
      lastName: me.lastName,
      profilePicture: me.profilePicture,
      createdAt: me.createdAt,
      fcmToken: me.fcmToken,
    );
  }

  Future<void> _handleMessageLongpress(
      BuildContext context, types.Message message) async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete"),
              onTap: () {
                final msg =
                    messages.firstWhereOrNull((e) => e.id == message.id);

                msg?.removeSameKeyLocaleMessages(conversation.key);
                messages.removeWhere((e) => e.id == message.id);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text("Reply"),
              onTap: () {
                _currentRepliedMessage = message;
                Get.back();
              },
            ),
          ],
        );
      },
    );
    update();
  }

  Future<void> _handlePopupMenuPressed(String value) async {
    switch (value) {
      case "clear-chat":
        final shouldClear = await showConfirmDialog(
            "All the messages in this chat will be deleted");
        if (shouldClear == true) {
          messages.clear();
          update();
          ChatMessage.deleteSameKeyLocaleMessages(conversation.key);
          conversation.lastMessage = null;
          conversation.saveChat();
        }

        break;
      case "delete-chat":
        final shouldClear =
            await showConfirmDialog("This conversation will be deleted");
        if (shouldClear == true) {
          await ChatMessage.deleteSameKeyLocaleMessages(conversation.key);
          await conversation.deleteChat();
          Get.back();
        }

        break;
      default:
    }
  }
}

class FlyerChatScreen extends StatelessWidget {
  const FlyerChatScreen({super.key, required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FlyerChatScreenController(conversation));
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              foregroundImage: conversation.friend.profilePicture != null
                  ? CachedNetworkImageProvider(
                      conversation.friend.profilePicture!,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            GetBuilder<FlyerChatScreenController>(builder: (controller) {
              return Text(controller.conversation.friend.fullName);
            })
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: controller._handlePopupMenuPressed,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "delete-chat",
                child: ListTile(
                  title: Text("Delete chat"),
                  leading: Icon(Icons.delete, color: Colors.red),
                ),
              ),
              PopupMenuItem(
                value: "clear-chat",
                child: ListTile(
                  title: Text("Clear chat"),
                  leading: Icon(Icons.delete_sweep),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Builder(builder: (context) {
        return GetBuilder<FlyerChatScreenController>(builder: (controller) {
          return Chat(
            messages: controller.messages.map((e) {
              final author = e.senderId == conversation.me.id
                  ? conversation.me
                  : conversation.friend;
              return e.getFlyerMessage(author);
            }).toList(),
            onMessageTap: controller._handleMessageTap,
            onPreviewDataFetched: controller._handlePreviewDataFetched,
            onSendPressed: controller._handleSendPressed,

            customBottomWidget: Container(
              color: Get.theme.inputDecorationTheme.fillColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller._isUploadingFile.isTrue)
                    const LinearProgressIndicator(),
                  if (controller._currentRepliedMessage != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.6),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final msg = controller._currentRepliedMessage;

                                if (msg is types.TextMessage) {
                                  return Text(
                                    msg.text,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                } else if (msg is types.ImageMessage) {
                                  return CachedNetworkImage(
                                    imageUrl: msg.uri,
                                    height: 100,
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              controller._currentRepliedMessage = null;
                              controller.update();
                            },
                            icon: const Icon(Icons.cancel),
                          )
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          controller._handleAttachmentPressed();
                        },
                        icon: const Icon(Icons.attach_file),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextField(
                            controller: controller._newMessageController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(8),
                              hintText: "New messsage",
                              hintStyle: TextStyle(
                                color: Get.isDarkMode ? Colors.white54 : null,
                              ),
                            ),
                            minLines: 1,
                            maxLines: 10,
                            onChanged: (value) {
                              controller.update(["send-button-get-builder"]);
                            },
                          ),
                        ),
                      ),
                      GetBuilder<FlyerChatScreenController>(
                        id: "send-button-get-builder",
                        builder: (controller) {
                          if (controller._isSendingMessage.isTrue) {
                            return const Padding(
                              padding: EdgeInsets.all(15),
                              child: CupertinoActivityIndicator(
                                color: Colors.blue,
                              ),
                            );
                          }
                          if (controller._newMessageController.text.isEmpty) {
                            return const SizedBox();
                          }
                          return IconButton(
                            onPressed: () {
                              controller._handleSendPressed(
                                types.PartialText(
                                  text: controller._newMessageController.text,
                                  repliedMessage:
                                      controller._currentRepliedMessage,
                                ),
                              );
                            },
                            icon: const Icon(Icons.send),
                          );
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
            theme: DefaultChatTheme(
              backgroundColor: Get.theme.scaffoldBackgroundColor,
              messageInsetsVertical: 0,
              messageInsetsHorizontal: 5,
              messageBorderRadius: 20,
            ),
            user: types.User(
              id: controller._user.id,
              firstName: controller._user.firstName,
              lastName: controller._user.lastName,
              createdAt: controller._user.createdAt.millisecondsSinceEpoch,
            ),
            // customBottomWidget: TextField(
            //   controller: controller.newMessageController,
            //   decoration: InputDecoration(
            //     prefix: IconButton(onPressed: (), icon: icon)

            //   ),
            // ),
            onMessageLongPress: controller._handleMessageLongpress,
            avatarBuilder: (userId) {
              if (userId == conversation.me.id) {
                return CircleAvatar(
                  radius: 20,
                  foregroundImage: conversation.me.profilePicture != null
                      ? CachedNetworkImageProvider(
                          conversation.me.profilePicture!,
                        )
                      : null,
                );
              }
              return CircleAvatar(
                radius: 20,
                foregroundImage: conversation.friend.profilePicture != null
                    ? CachedNetworkImageProvider(
                        conversation.friend.profilePicture!,
                      )
                    : null,
              );
            },
            bubbleBuilder: (
              child, {
              required message,
              required nextMessageInGroup,
            }) {
              return Bubble(
                color: controller._user.id == message.author.id
                    ? Get.theme.appBarTheme.backgroundColor
                    : Colors.blue,
                margin: nextMessageInGroup
                    ? const BubbleEdges.symmetric(horizontal: 6)
                    : null,
                nip: nextMessageInGroup
                    ? BubbleNip.no
                    : controller._user.id != message.author.id
                        ? BubbleNip.leftTop
                        : BubbleNip.rightTop,
                radius: const Radius.circular(10),
                child: child,
              );
            },
          );
        });
      }),
    );
  }
}

enum AttachedTypes {
  imageGallery,
  imageCamera,
  audio,
  videoGallery,
  videoCammera,
  any
}
