import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import "package:path/path.dart" as path;
import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/chat_conversation.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/loadinding_controller.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/models/chat_message.dart';
import 'package:roomy_finder/models/chat_user.dart';

class FlyerChatScreenController extends LoadingController {
  final ChatConversation conversation;
  final List<ChatMessage> messages = [];

  final _newMessageController = TextEditingController();

  final _isUploadingFile = false.obs;
  final _isSendingMessage = false.obs;
  final _canMakeVoice = true.obs;
  types.Message? _currentRepliedMessage;

  FlyerChatScreenController(this.conversation);

  late final AudioPlayer _audioPlayer;
  late final StreamSubscription<FGBGType> fGBGNotifierSubScription;

  Future<void> _fetchMessages({
    bool? isRefresh,
    DateTime? lastDate,
  }) async {
    try {
      if (isRefresh == true) isLoading(true);
      hasFetchError(false);
      update();

      final query = {"otherId": conversation.other.id};

      if (lastDate != null) {
        query["lastDate"] = lastDate.toUtc().toIso8601String();
      }

      final res = await ApiService.getDio.get(
        "/messages",
        queryParameters: query,
      );

      if (res.statusCode == 200) {
        final data = (res.data as List).map((e) {
          try {
            return ChatMessage.fromMap(e);
          } catch (e, trace) {
            Get.log("$trace");
            return null;
          }
        });

        if (isRefresh == true) messages.clear();
        messages.insertAll(0, data.whereType<ChatMessage>());
      } else {
        hasFetchError(true);
      }
    } catch (e) {
      Get.log("$e");
    } finally {
      isLoading(false);
      update();
      _markMessagesAsRead();
    }
  }

  @override
  void onInit() {
    super.onInit();

    _fetchMessages(isRefresh: true);

    _audioPlayer = AudioPlayer();

    fGBGNotifierSubScription = FGBGEvents.stream.listen((event) {
      if (event == FGBGType.foreground) {
        _fetchMessages(
          lastDate: messages.isNotEmpty ? messages.first.createdAt : null,
        ).then((_) {
          AwesomeNotifications().cancelAll();
        });
      }
    });

    FirebaseMessaging.onMessage.asBroadcastStream().listen((remoteMessage) {
      AppController.instance.haveNewMessage(false);

      final data = remoteMessage.data;

      if (data["event"] == "new-message") {
        try {
          final message = ChatMessage.fromJson(data["message"]);

          final convKey = ChatConversation.createConvsertionKey(
            message.recieverId,
            message.senderId,
          );

          if (convKey == conversation.key) {
            _addNewMessage(message);
            update();
          }

          if (convKey == ChatConversation.currrentChatKey) {
            _markMessagesAsRead();
            message.markAsRead();
            _audioPlayer
                .setAsset("assets/audio/in_chat_new_message_sound.mp3")
                .then((_) => _audioPlayer.play());
          }
        } catch (e, trace) {
          Get.log('$e');
          Get.log('$trace');
        }
      } else if (data["event"] == "message-recieved" ||
          data["event"] == "message-read") {
        if (data["senderId"] == conversation.me.id) {
          if (data["event"] == "message-recieved") {
            for (int i = 0; i < messages.length; i++) {
              if (messages[i].senderId == conversation.me.id) {
                messages[i].markAsRecieved();
              }
            }
          } else {
            for (int i = 0; i < messages.length; i++) {
              if (messages[i].senderId == conversation.me.id) {
                messages[i].markAsRead();
              }
            }
          }
          update();
        }
      }
    });
  }

  @override
  void onClose() {
    _newMessageController.dispose();
    ChatConversation.currrentChatKey = null;
    ChatConversation.currrentChatOnTapCallBack = null;
    _audioPlayer.dispose();
    fGBGNotifierSubScription.cancel();
    super.onClose();
  }

  void _addNewMessage(ChatMessage message) {
    if (!messages.contains(message)) messages.insert(0, message);
  }

  // User
  ChatUser get _user {
    final me = AppController.me;
    return ChatUser(
      id: me.id,
      firstName: me.firstName,
      lastName: me.lastName,
      profilePicture: me.profilePicture,
      createdAt: me.createdAt,
      fcmToken: me.fcmToken,
    );
  }

  Future<void> _markMessagesAsRead() async {
    if (messages.isNotEmpty && !messages.first.isRead) {
      var res = await ChatMessage.requestMarkAsRead(
        conversation.other.id,
        conversation.me.id,
      );
      if (res) {
        for (int i = 0; i < messages.length; i++) {
          if (messages[i].senderId != conversation.me.id) {
            if (messages[i].isRead) break;
            messages[i].markAsRead();
          }
        }
        update();
      }
    }
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
            "notificationTitle": AppController.me.fullName,
            "type": 'file',
            "body": "Sent a file",
            "recieverId": conversation.other.id,
            "recieverFcmToken": conversation.other.fcmToken,
            "fileUri": fileUrl,
            "fileName": file.name,
            "fileSize": file.size,
            "replyId": _currentRepliedMessage?.id,
            "profilePicture": AppController.me.profilePicture,
          },
        );

        if (res.statusCode == 200) {
          final message = ChatMessage.fromMap(res.data);
          _addNewMessage(message);
          conversation.lastMessage = message;
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
          "notificationTitle": AppController.me.fullName,
          "type": messageType,
          "body": "Sent a $messageType",
          "recieverId": conversation.other.id,
          "recieverFcmToken": conversation.other.fcmToken,
          "fileUri": fileUrl,
          "fileName": result.name,
          "fileSize": bytes.length,
          "replyId": _currentRepliedMessage?.id,
          "profilePicture": AppController.me.profilePicture,
        },
      );

      if (res.statusCode == 200) {
        final message = ChatMessage.fromMap(res.data);
        _addNewMessage(message);
        conversation.lastMessage = message;
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
          "notificationTitle": AppController.me.fullName,
          "type": 'text',
          "body": partialMessage.text,
          "recieverId": conversation.other.id,
          "recieverFcmToken": conversation.other.fcmToken,
          "replyId": _currentRepliedMessage?.id,
          "profilePicture": AppController.me.profilePicture,
        },
      );

      if (res.statusCode == 200) {
        final message = ChatMessage.fromMap(res.data);
        _addNewMessage(message);
        conversation.lastMessage = message;

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
        }

        break;
      case "delete-chat":
        final shouldClear =
            await showConfirmDialog("This conversation will be deleted");
        if (shouldClear == true) {
          Get.back();
        }

        break;
      case "reload-messages":
        _fetchMessages(isRefresh: true);

        break;
      default:
    }
  }
}

class FlyerChatScreen extends StatefulWidget {
  const FlyerChatScreen({
    super.key,
    required this.conversation,
    required this.myId,
    required this.otherId,
  });

  final ChatConversation conversation;
  final String myId;
  final String otherId;

  @override
  State<FlyerChatScreen> createState() => _FlyerChatScreenState();
}

class _FlyerChatScreenState extends State<FlyerChatScreen> {
  @override
  void initState() {
    super.initState();

    final controller = Get.put(
      FlyerChatScreenController(widget.conversation),
      tag: "${widget.myId}#${widget.otherId}",
      permanent: true,
    );

    controller.conversation
        .updateChatInfo()
        .then((value) => controller.update());

    ChatConversation.currrentChatKey = widget.conversation.key;
    ChatConversation.currrentChatOnTapCallBack = () {
      controller.update();
    };
    controller._markMessagesAsRead();
    controller.conversation.haveUnreadMessage = false;

    controller.update();

    // WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    final controller = Get.put(
      FlyerChatScreenController(widget.conversation),
      tag: "${widget.myId}#${widget.otherId}",
      permanent: true,
    );

    if (controller.messages.isNotEmpty) {
      ChatConversation.addConversation(widget.conversation);
    }

    ChatConversation.sortConversations();
    controller._audioPlayer.dispose();
    // WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     final controller = Get.put(
  //       FlyerChatScreenController(widget.conversation),
  //       tag: "${widget.myId}#${widget.otherId}",
  //       permanent: true,
  //     );

  //     controller._fetchMessages();
  //   }
  //   super.didChangeAppLifecycleState(state);
  // }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      FlyerChatScreenController(widget.conversation),
      tag: "${widget.myId}#${widget.otherId}",
      permanent: true,
    );
    return WillPopScope(
      onWillPop: () async {
        ChatConversation.currrentChatKey = null;
        ChatConversation.currrentChatOnTapCallBack = null;
        if (controller.messages.isNotEmpty) {
          ChatConversation.findConversation(widget.conversation.key)
              ?.lastMessage = controller.messages.first;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 40,
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
              GetBuilder<FlyerChatScreenController>(
                tag: "${widget.myId}#${widget.otherId}",
                builder: (controller) {
                  return Text(controller.conversation.other.fullName);
                },
              )
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: controller._handlePopupMenuPressed,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: "reload-messages",
                  child: ListTile(
                    title: Text("Reload Messages"),
                    leading: Icon(CupertinoIcons.refresh, color: Colors.red),
                  ),
                ),
                // PopupMenuItem(
                //   value: "delete-chat",
                //   child: ListTile(
                //     title: Text("Delete chat"),
                //     leading: Icon(CupertinoIcons.delete, color: Colors.red),
                //   ),
                // ),
              ],
            ),
          ],
        ),
        body: GetBuilder<FlyerChatScreenController>(
          tag: "${widget.myId}#${widget.otherId}",
          builder: (controller) {
            if (controller.isLoading.isTrue) {
              return const Center(
                  child: Column(
                children: [
                  Spacer(),
                  Text("Loading messages..."),
                  SizedBox(height: 20),
                  CupertinoActivityIndicator(),
                  Spacer(),
                ],
              ));
            }
            if (controller.hasFetchError.isTrue) {
              return Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    const Text("Failed to load messages"),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () =>
                          controller._fetchMessages(isRefresh: true),
                      child: const Text("Reload"),
                    ),
                    const Spacer(),
                  ],
                ),
              );
            }
            return Chat(
              messages: controller.messages.map((e) {
                final author = e.senderId == widget.conversation.me.id
                    ? widget.conversation.me
                    : widget.conversation.other;
                var flyerMessage = e.getFlyerMessage(author).copyWith(
                    repliedMessage: e
                        .getRepliedMessage(controller.messages)
                        ?.getFlyerMessage(author));

                return flyerMessage;
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: controller.isLoading.isTrue
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    controller._handleAttachmentPressed();
                                  },
                            icon: const Icon(Icons.attach_file),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: TextField(
                                controller: controller._newMessageController,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding: const EdgeInsets.all(8),
                                  hintText: "New messsage",
                                  hintStyle: TextStyle(
                                    color:
                                        Get.isDarkMode ? Colors.white54 : null,
                                  ),
                                ),
                                minLines: 1,
                                maxLines: 10,
                                onChanged: (value) {
                                  controller
                                      .update(["send-button-get-builder"]);
                                },
                              ),
                            ),
                          ),
                          GetBuilder<FlyerChatScreenController>(
                            tag: "${widget.myId}#${widget.otherId}",
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
                              if (controller
                                  ._newMessageController.text.isEmpty) {
                                return const SizedBox(width: 10);
                              }
                              return IconButton(
                                onPressed: controller.isLoading.isTrue
                                    ? null
                                    : () {
                                        controller._handleSendPressed(
                                          types.PartialText(
                                            text: controller
                                                ._newMessageController.text,
                                            repliedMessage: controller
                                                ._currentRepliedMessage,
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.send),
                              );
                            },
                          )
                        ],
                      ),
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
          },
        ),
      ),
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
