part of './chat_room_screen.dart';

class _ChatRoomController extends LoadingController {
  late final Socket socket;

  _ChatRoomController(
    this.conversation, {
    this.initialRoommateAd,
    this.initialBooking,
  });

  late final ItemScrollController _scrollController;
  late final TextEditingController _newMessageController;
  late final StreamSubscription<FGBGType> _fGBGNotifierSubScription;
  late final StreamSubscription<ChatEventStreamData> _chatEventsSubscription;

  ChatConversationV2 conversation;
  final List<ChatMessageV2> selectedMessages = [];

  // Voice recording
  // final _recorder = Record();

  List<ChatMessageV2> messages = [];

  bool haveHandledInitialAd = true;

  final skip = 0.obs;

  RoommateAd? initialRoommateAd;
  PropertyBooking? initialBooking;

  final FocusNode focusNode = FocusNode();

  User get me => conversation.me;
  User get other => conversation.other;
  String get newMessageTitle => me.fullName;
  ChatMessageV2? get lastMessage => conversation.lastMessage.value;

  ChatMessageV2? repliedMessage;

  List<ChatMessageFileUploadTaskWidget> uploadTasks = [];

  final isUploading = false.obs;
  final isSelectMode = false.obs;
  // ignore: prefer_final_fields

// Scroll
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

// Voice
  late final FlutterSoundPlayer _newMessageSoundPlayer;
  late final FlutterSoundRecorder _voiceRecoder;
  final _voiceRecoderDragOffset = 0.0.obs;

  late final StreamSubscription<RecordingDisposition>? _recordStream;
  var _recordDuration = const Duration();

  @override
  void onInit() {
    super.onInit();

    ChatConversationV2.currentChatRoomKey = conversation.key;

    _loadMessages(false);
    conversation.unReadMessageCount = 0;
    ISAR.writeTxnSync(() => ISAR.chatConversationV2s.putSync(conversation));

    conversation.updateUserProfiles().then((value) => update());

    _clearChatNotifications();

    _createAudioSession();

    _scrollController = ItemScrollController();
    _newMessageController = TextEditingController();

// New message voice player
    _newMessageSoundPlayer = FlutterSoundPlayer(logLevel: Level.warning);
    _newMessageSoundPlayer.openPlayer().then((_) {
      _newMessageSoundPlayer.setVolume(0.3);
    });

// Voice player
    VoicePlayerHelper.player = FlutterSoundPlayer(logLevel: Level.warning);
    VoicePlayerHelper.player.openPlayer().then((_) {
      VoicePlayerHelper.player
          .setSubscriptionDuration(const Duration(milliseconds: 1));
    });

// Voice recorder
    _voiceRecoder = FlutterSoundRecorder(logLevel: Level.warning);
    _voiceRecoder.openRecorder().then((_) {
      _voiceRecoder.setSubscriptionDuration(const Duration(seconds: 1));
    });

// Socket

    socket = io(SERVER_URL, AppController.me.socketOption);

    socket.connect();

// Chat events
    _chatEventsSubscription = ChatEventHelper.stream.listen((event) {
      if (event.$2 != conversation.key) return;

      if (event.$1 == ChatEvents.newMessage) {
        if (ChatConversationV2.currentChatRoomKey == conversation.key &&
            FileHelper.NEW_MESSAGE_SOUND != null &&
            AppController.isForeground) {
          _newMessageSoundPlayer.startPlayer(
              fromDataBuffer: FileHelper.NEW_MESSAGE_SOUND);
        }

        if (event.$3 != null) {
          final lastM = ISAR.txnSync(() {
                return ISAR.chatMessageV2s.getSync(fastHash(event.$3!.id));
              }) ??
              event.$3!;

          messages.insert(0, lastM);

          _notifyThatIHaveReadMessages();
        }
      } else if (event.$1 == ChatEvents.messageRead) {
        _markMyMessagesAsRead();
      } else if (event.$1 == ChatEvents.messageRecieved) {
        _markMyMessagesAsRecieved();
      } else if (event.$1 == ChatEvents.replyMessageFromRaySuccedded) {
        if (event.$3 != null) {
          messages.insert(0, event.$3!);
        }
      } else if (event.$1 == ChatEvents.userBlocked) {
        conversation.blocks = List.from(conversation.blocks)..add(me.id);
      } else if (event.$1 == ChatEvents.userUnBlocked) {
        conversation.blocks = List.from(conversation.blocks)
          ..removeWhere((e) => e == me.id);
      }
      update();
    });

// Background foreground
    _fGBGNotifierSubScription = FGBGEvents.stream.listen((event) async {
      if (event == FGBGType.foreground) {
        _loadMessages();
        AppController.isForeground = true;

        conversation.unReadMessageCount = 0;
        ISAR.writeTxnSync(() => ISAR.chatConversationV2s.putSync(conversation));

        _notifyThatIHaveReadMessages();

        _clearChatNotifications();
        update();
      } else {
        AppController.isForeground = false;

        if (_voiceRecoder.isRecording) _voiceRecoder.stopRecorder();
      }
    });

// Recorder
    _recordStream = _voiceRecoder.onProgress?.listen((event) {
      _recordDuration = event.duration;

      update(["bottom-widget"]);
    });

    if (initialBooking != null || initialRoommateAd != null) {
      haveHandledInitialAd = false;
    }

    socket.connect();

    socket.onConnectError((data) {
      Get.log("Connection error...");
    });

    socket.onReconnect((data) {
      Get.log("Socket reconnecting...");
    });
  }

  void _notifyThatIHaveReadMessages() {
    var lastM = messages.firstWhereOrNull((e) => e.senderId != me.id);

    if (lastM != null && !lastM.reads.contains(me.id)) {
      socket.emitWithAck(
        "message-read",
        {"key": conversation.key, "messageId": lastM.id, "userId": me.id},
        ack: (_) {},
      );

      lastM.reads = List.from(lastM.reads)..add(me.id);
      lastM.recieveds = List.from(lastM.recieveds)..add(me.id);

      ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putSync(lastM));

      ISAR.writeTxnSync(() {
        return ISAR.chatConversationV2s.putSync(conversation);
      });
    }
  }

  void _markMyMessagesAsRead() {
    var lastM = messages.firstWhereOrNull((e) => e.senderId == me.id);

    if (lastM != null) {
      if (!lastM.reads.contains(other.id)) {
        lastM.reads = List.from(lastM.reads)..add(other.id);
      }
      if (!lastM.recieveds.contains(other.id)) {
        lastM.recieveds = List.from(lastM.recieveds)..add(other.id);
      }
      ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putSync(lastM));
    }

    update();
  }

  void _markMyMessagesAsRecieved() {
    var lastM = messages.firstWhereOrNull((e) => e.senderId == me.id);

    if (lastM != null && !lastM.recieveds.contains(other.id)) {
      lastM.recieveds = List.from(lastM.recieveds)..add(other.id);

      ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putSync(lastM));
    }

    update();
  }

// On Close
  @override
  void onClose() {
    super.onClose();
    // _scrollController.dispose();

    _fGBGNotifierSubScription.cancel();

    _newMessageSoundPlayer.closePlayer();

    VoicePlayerHelper.player.closePlayer();

    if (!_voiceRecoder.isStopped) _voiceRecoder.closeRecorder();

    _recordStream?.cancel();

    _endAudioSession();

    _chatEventsSubscription.cancel();

    conversation.unReadMessageCount = 0;
    ISAR.writeTxnSync(() => ISAR.chatConversationV2s.putSync(conversation));
    _setUnreadMessagesCount();

    _newMessageController.dispose();

    ChatConversationV2.currentChatRoomKey = null;
  }

// Load messages

  Future<void> _loadMessages([bool silent = true]) async {
    try {
      if (!silent) {
        isLoading(true);
        update();
      }

      messages = await ISAR.txn(() => ISAR.chatMessageV2s
          .filter()
          .keyEqualTo(conversation.key)
          .sortByCreatedAtDesc()
          .findAll());
    } catch (e) {
      Get.log("$e");
    } finally {
      isLoading(false);
      update();
      _clearChatNotifications();
      _notifyThatIHaveReadMessages();
    }
  }

// Clear notifications
  void _clearChatNotifications() {
    for (var m in messages) {
      NotificationController.plugin.cancel(m.localNotificationsId);
    }
  }

  Future<Codec?> _getSupporttedCodec() async {
    if (await _voiceRecoder.isEncoderSupported(Codec.aacMP4)) {
      return Codec.aacMP4;
    }

    for (final c in Codec.values) {
      if (await _voiceRecoder.isEncoderSupported(c)) {
        return c;
      }
    }

    return null;
  }

// Audio session

  Future<void> _endAudioSession() async {
    try {
      final session = await AudioSession.instance;

      await session.setActive(true);
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }

  Future<void> _createAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth |
                  AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );

      await session.setActive(true);
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }

  Future<void> _startVoiceRecord() async {
    try {
      var canRecord = await Permission.microphone.isGranted ||
          await Permission.microphone.isLimited;

      if (!canRecord) {
        FileHelper.requestPermission(Permission.microphone);
        return;
      }

      if (_voiceRecoder.isRecording) await _voiceRecoder.stopRecorder();

      Codec? codec = await _getSupporttedCodec();

      if (codec == null) {
        showToast("Voice ending is supported on this device");
        return;
      }

      final toFile = "${DateTime.now().toIso8601String()}"
          "-${Random().nextInt(1000) + 100}.m4a";

      await _voiceRecoder.startRecorder(
        toFile: toFile,
        codec: codec,
      );

      update(["bottom-widget"]);
    } catch (e, trace) {
      showToast("Error recording voice");
      Get.log("$e");
      Get.log("$trace");
    }
  }

  Future<void> _stopVoiceRecord(bool shouldSend) async {
    try {
      if (!_voiceRecoder.isRecording) {
        return;
      }

      final filePath = await _voiceRecoder.stopRecorder();

      if (filePath == null) return;

      final file = File(filePath);

      update(["bottom-widget"]);

      if (!shouldSend) {
        file.deleteSync();

        return;
      }

      if (_recordDuration.inSeconds < 1) {
        // showToast("Voice must be nore than one second");
        _recordDuration = Duration.zero;

        return;
      }

      final bytes = file.readAsBytesSync();

      final msg = ChatMessageV2(
        id: DateTime.now().toIso8601String(),
        key: conversation.key,
        senderId: me.id,
        recieverId: other.id,
        type: 'voice',
        recieveds: [],
        reads: [],
        deletes: [],
        isDeletedForAll: false,
        createdAt: DateTime.now(),
        isSending: true,
        files: [],
        replyId: repliedMessage?.id,
        voice: ChatVoiceNote()
          ..name = path.basename(filePath)
          ..bytes = bytes
          ..seconds = _recordDuration.inSeconds,
        bookingId: haveHandledInitialAd ? initialBooking?.id : null,
        roommateId: haveHandledInitialAd ? initialRoommateAd?.id : null,
        localNotificationsId: Random().nextInt(pow(1, 30).toInt()),
      );

      messages.insert(0, msg);

      final map = {
        "type": msg.type,
        "recieverId": msg.recieverId,
        "bookingId": msg.bookingId,
        "roommateId": msg.roommateId,
        "replyId": msg.replyId,
        "voice": {
          "name": path.basename(filePath),
          "bytes": bytes,
          "seconds": _recordDuration.inSeconds,
        },
      };

      _recordDuration = Duration.zero;
      repliedMessage = null;

      update(["bottom-widget"]);

      try {
        file.deleteSync(recursive: true);
      } catch (_) {}

      socket.emitWithAck(
        "send-message",
        {"message": map, "title": newMessageTitle},
        ack: (res) {
          if (res["code"] == 200) {
            msg.id = res["message"]["id"];
            msg.isSending = false;

            ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putSync(msg));
            conversation.lastMessage.value = msg;
            ISAR.writeTxnSync(
                () => ISAR.chatConversationV2s.putSync(conversation));

            update();
          } else {
            res["code"];
            showToast("Failed to sent message");
          }
        },
      );
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
    }
  }

  // void _scrollDown() {
  //   _scrollController.jumpTo(index: messages.length - 1);
  // }

/*
  Future<void> _fetchMessages() async {
    if (AppController.me.isGuest) return;
    isLoading(true);
    hasFetchError(false);
    update();
    socket.emitWithAck(
        'get-messages', {"key": conversation.key, "skip": skip.value},
        ack: (res) {
      try {
        final code = res["code"];

        if (code == 200) {
          final data = (res["data"] as List).map((e) {
            try {
              var m = ChatMessageV2.fromMap(e);

              return m;
            } catch (e, trace) {
              Get.log("$e");
              Get.log("$trace");
              return null;
            }
          });

          messages.addAll(data.whereType<ChatMessageV2>());
          _sortMessages();
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
*/

  // Send message
  void _sendMessage(
    Map<String, dynamic> content, {
    void Function()? onSent,
  }) {
    if (!haveHandledInitialAd) {
      if (initialBooking != null) {
        content["bookingId"] = initialBooking!.id;
      }

      if (initialRoommateAd != null) {
        content["roommateId"] = initialRoommateAd!.id;
      }
    }

    if (repliedMessage != null) content["replyId"] = repliedMessage!.id;
    repliedMessage = null;
    update(["bottom-widget"]);
    _newMessageController.clear();

    socket.emitWithAck(
      "send-message",
      {"message": content, "title": newMessageTitle},
      ack: (res) {
        if (res["code"] == 200) {
          final msg = ChatMessageV2.fromMap(res["message"]);

          messages.insert(0, msg);

          ISAR.writeTxnSync(() => ISAR.chatMessageV2s.putSync(msg));
          conversation.lastMessage.value = msg;
          ISAR.writeTxnSync(
              () => ISAR.chatConversationV2s.putSync(conversation));

          update();

          if (onSent != null) onSent();
        } else {
          res["code"];
          showToast("Failed to sent message");
        }
      },
    );
  }

  Future<List<File>> _pickFiles(_AttachedTypes type) async {
    final List<File> files = [];

    switch (type) {
      case _AttachedTypes.imageGallery:
        var data = await ImagePicker().pickMultiImage(
          imageQuality: 70,
        );

        files.addAll(data.map((e) => File(e.path)));

        break;
      case _AttachedTypes.imageCamera:
        var file = await ImagePicker().pickImage(
          imageQuality: 70,
          source: ImageSource.camera,
        );

        if (file != null) {
          files.add(File(file.path));
        }

        break;
      case _AttachedTypes.videoGallery:
        var file = await ImagePicker().pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 10),
        );

        if (file != null) {
          files.add(File(file.path));
        }

        break;
      case _AttachedTypes.videoCammera:
        var file = await ImagePicker().pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 10),
        );

        if (file != null) {
          files.add(File(file.path));
        }
        break;
      case _AttachedTypes.document:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: true,
          dialogTitle: "Pick  Documents",
          allowedExtensions:
              DOCUMENT_EXTENSIONS.map((e) => e.replaceFirst(".", "")).toList(),
        );

        if (result != null) {
          files.addAll(result.files.map((e) => File(e.path!)));
        }

        break;
      case _AttachedTypes.audio:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: true,
          dialogTitle: "Pick Audios",
        );

        if (result != null) {
          files.addAll(result.files.map((e) => File(e.path!)));
        }

        break;
      case _AttachedTypes.file:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: true,
          dialogTitle: "Pick Files",
          allowedExtensions:
              OTHER_EXTENSIONS.map((e) => e.replaceFirst(".", "")).toList(),
        );

        if (result != null) {
          files.addAll(result.files.map((e) => File(e.path!)));
        }

        break;
      default:
    }

    return files;
  }

  void _onFileUploadCancel(int index) {
    uploadTasks.removeAt(index);
    update();
  }

  Future<void> _sendMedia() async {
    focusNode.unfocus();
    try {
      final type = await showModalBottomSheet(
        context: Get.context!,
        builder: (context) {
          return Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              children: [
                {
                  "asset": "assets/images/document_file_picker.png",
                  "type": _AttachedTypes.document,
                  "label": "Document",
                },
                {
                  "asset": "assets/images/camera_file_picker.png",
                  "type": _AttachedTypes.imageCamera,
                  "label": "Camera",
                },
                {
                  "asset": "assets/images/image_file_picker.png",
                  "type": _AttachedTypes.imageGallery,
                  "label": "Gallery",
                },
                {
                  "asset": "assets/images/video_file_picker.png",
                  "type": _AttachedTypes.videoGallery,
                  "label": "Video",
                },
                {
                  "asset": "assets/images/audio_file_picker.png",
                  "type": _AttachedTypes.audio,
                  "label": "Audio",
                },
              ].map((e) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(result: e["type"]),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Image.asset(
                          "${e["asset"]}",
                          height: 60,
                          width: 60,
                        ),
                      ),
                    ),
                    Text(
                      "${e["label"]}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      );

      if (type is _AttachedTypes) {
        final files = await _pickFiles(type);

        if (files.length > 10) {
          showToast("max files is 10");

          files.removeRange(10, files.length - 1);
        }

        if (files.isEmpty) return;

        var filteredFiles = await filterMediaFiles(files);

        if (filteredFiles == null) return;

        uploadTasks.add(ChatMessageFileUploadTaskWidget(
          files: filteredFiles,
          message: _newMessageController.text.trim().isNotEmpty
              ? _newMessageController.text
              : null,
          replyId: repliedMessage?.id,
          onUploadCompleted: (tasks, msg, replyId) {
            _sendMessage({
              "type": "file",
              "replyId": replyId,
              "content": msg,
              "recieverId": other.id,
              "files": tasks,
            }, onSent: () async {
              uploadTasks.removeAt(uploadTasks.length - 1);

              update();

              for (int i = 0; i < filteredFiles.length; i++) {
                try {
                  var path = await FileHelper.getPossibleLocalPath(
                      Uri.parse("${tasks[i]["url"]}"));

                  await FileHelper.copyFileToPath(filteredFiles[i], path);
                  update();
                } catch (e, trace) {
                  Get.log("$e");
                  Get.log("$trace");
                }
              }
            });
          },
          onCancel: () => _onFileUploadCancel(uploadTasks.length - 1),
        ));

        _newMessageController.clear();
        repliedMessage = null;
        update();
      }

      update();
    } catch (e, trace) {
      showToast("Failed to sent message");

      Get.log("$e");
      Get.log("$trace");
    }
  }

  Future<void> _deleteMessages() async {
    final res = await showConfirmDialog("Please confirm to delete");

    if (res != true) return;
    socket.emitWithAck(
      "delete-messages",
      {
        "ids": selectedMessages.map((e) => e.id).toList(),
        "key": conversation.key,
      },
      ack: (_) {},
    );

    ISAR.writeTxnSync(() {
      return ISAR.chatMessageV2s
          .deleteAllSync(selectedMessages.map((e) => fastHash(e.id)).toList());
    });

    messages.removeWhere((e) => selectedMessages.contains(e));
    if (messages.isNotEmpty) {
      conversation.lastMessage.value = messages.first;
      ISAR.writeTxnSync(() => ISAR.chatConversationV2s.putSync(conversation));
    }

    selectedMessages.clear();

    isSelectMode(false);

    update();
  }

  Future<void> _handlePopUpMenu(String? val) async {
    switch (val) {
      case "block-user":
        var shoulBlock = await showConfirmDialog(
          "Please confirm",
          title: "Block ${other.fullName}",
          confirmText: "Block",
          refuseText: "Cancel",
        );

        if (shoulBlock == true) {
          socket.emitWithAck(
            "block-user",
            {"userId": other.id, "key": conversation.key},
            ack: (data) {
              conversation.blocks = List.from(conversation.blocks)
                ..add(other.id);
              update();
            },
          );
        }

        break;
      case "unblock-user":
        var shoulBlock = await showConfirmDialog(
          "Please confirm",
          title: "Unblock ${other.fullName}",
          confirmText: "Unblock",
          refuseText: "Cancel",
        );

        if (shoulBlock == true) {
          socket.emitWithAck(
            "unblock-user",
            {"userId": other.id, "key": conversation.key},
            ack: (data) {
              conversation.blocks = List.from(conversation.blocks)
                ..remove(other.id);
              update();
            },
          );
        }

        break;
      default:
    }
  }

  void _setUnreadMessagesCount() {
    var conversations = ISAR
        .txnSync(() =>
            ISAR.chatConversationV2s.filter().unReadMessageCountGreaterThan(0))
        .findAllSync();

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
}

enum _AttachedTypes {
  imageGallery,
  imageCamera,
  videoGallery,
  videoCammera,
  audio,
  document,
  file,
}
