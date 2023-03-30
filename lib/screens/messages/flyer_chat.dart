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
import 'package:roomy_finder/models/user.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import "package:path/path.dart" as path;
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

class FlyerChatScreenController extends GetxController
    with WidgetsBindingObserver {
  final ChatConversation conversation;

  final _newMessageController = TextEditingController();

  final _isUploadingFile = false.obs;
  final _isSendingMessage = false.obs;
  final _canMakeVoice = true.obs;
  types.Message? _currentRepliedMessage;

  FlyerChatScreenController(this.conversation);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    conversation.loadMessages().then((value) => update());
    super.didChangeAppLifecycleState(state);
  }

  @override
  void onInit() {
    super.onInit();

    ChatConversation.currrentChatKey = conversation.key;

    WidgetsBinding.instance.addObserver(this);

    conversation.loadMessages().then((_) => update());
    conversation.updateChatInfo().then((_) => update());
    FirebaseMessaging.onMessage.asBroadcastStream().listen((event) {
      final data = event.data;
      AppController.instance.haveNewMessage(false);

      if (data["event"] == "new-message") {
        try {
          final msg = types.Message.fromJson(jsonDecode(data["message"]));

          final sender = User.fromJson(data["sender"]);
          final reciever = User.fromJson(data["reciever"]);

          final convKey =
              ChatConversation.createConvsertionKey(reciever.id, sender.id);

          if (convKey == conversation.key) {
            conversation.messages.insert(0, msg);
            update();
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

        final message = types.FileMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          name: file.name,
          size: file.size,
          uri: fileUrl,
          repliedMessage: _currentRepliedMessage,
        );

        final res = await ApiService.getDio.post(
          '/messages',
          data: {
            "message": jsonEncode(message.toJson()),
            "reciever": conversation.friend.toJson(),
            "sender": conversation.me.toJson(),
          },
        );

        if (res.statusCode == 200) {
          conversation.newMessage(message);
          update();
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

      final types.Message message;

      final createdAt = DateTime.now().millisecondsSinceEpoch;

      switch (type) {
        case AttachedTypes.imageGallery:
        case AttachedTypes.imageCamera:
          message = types.ImageMessage(
            author: _user,
            createdAt: createdAt,
            id: const Uuid().v4(),
            name: result.name,
            size: bytes.length,
            uri: fileUrl,
            repliedMessage: _currentRepliedMessage,
          );
          break;

        case AttachedTypes.videoGallery:
        case AttachedTypes.videoCammera:
          message = types.VideoMessage(
            author: _user,
            createdAt: createdAt,
            id: const Uuid().v4(),
            name: result.name,
            size: bytes.length,
            uri: fileUrl,
            repliedMessage: _currentRepliedMessage,
          );
          break;
        default:
          return;
      }

      final res = await ApiService.getDio.post(
        '/messages',
        data: {
          "message": jsonEncode(message.toJson()),
          "reciever": conversation.friend.toJson(),
          "sender": conversation.me.toJson(),
        },
      );

      if (res.statusCode == 200) {
        conversation.newMessage(message);
        update();
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
            final index = conversation.messages
                .indexWhere((element) => element.id == message.id);
            final updatedMessage =
                (conversation.messages[index] as types.FileMessage).copyWith(
              isLoading: true,
            );

            update();
            conversation.messages[index] = updatedMessage;

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
            final index = conversation.messages
                .indexWhere((element) => element.id == message.id);
            final updatedMessage =
                (conversation.messages[index] as types.FileMessage).copyWith(
              isLoading: null,
            );

            conversation.messages[index] = updatedMessage;
            update();
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
    final index =
        conversation.messages.indexWhere((element) => element.id == message.id);
    final updatedMessage =
        (conversation.messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    conversation.messages[index] = updatedMessage;
    update();
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    try {
      _isSendingMessage(true);
      update();

      final textMessage = types.TextMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: message.text,
      );

      final res = await ApiService.getDio.post(
        '/messages',
        data: {
          "message": jsonEncode(textMessage.toJson()),
          "reciever": conversation.friend.toJson(),
          "sender": conversation.me.toJson(),
        },
      );

      if (res.statusCode == 200) {
        conversation.messages.add(textMessage);
        conversation.newMessage(textMessage);
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
      showToast("Failed to send messsage");
    } finally {
      _isSendingMessage(false);
      update();
    }
  }

  // User
  types.User get _user {
    final me = conversation.me;
    return types.User(
      id: me.id,
      firstName: me.firstName,
      lastName: me.lastName,
      imageUrl: me.profilePicture,
      createdAt: me.createdAt.millisecondsSinceEpoch,
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
                conversation.messages.remove(message);
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
          conversation.messages.clear();
          conversation.saveChat();
          update();
        }

        break;
      case "delete-chat":
        final shouldClear =
            await showConfirmDialog("This conversation will be deleted");
        if (shouldClear == true) {
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
              foregroundImage: CachedNetworkImageProvider(
                conversation.friend.profilePicture,
              ),
            ),
            const SizedBox(width: 10),
            Text(conversation.friend.fullName)
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
            messages: conversation.messages,
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
            user: controller._user,
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
                  foregroundImage: CachedNetworkImageProvider(
                    conversation.me.profilePicture,
                  ),
                );
              }
              return CircleAvatar(
                radius: 20,
                foregroundImage: CachedNetworkImageProvider(
                  conversation.friend.profilePicture,
                ),
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
