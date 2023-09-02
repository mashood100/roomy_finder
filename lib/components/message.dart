import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:link_preview_generator/link_preview_generator.dart';
import 'package:readmore/readmore.dart';
import 'package:roomy_finder/classes/voice_note_player_helper.dart';
import 'package:swipe_to/swipe_to.dart';

import 'package:roomy_finder/models/chat/chat_message_v2.dart';
import 'package:roomy_finder/models/user/user.dart';
import 'package:roomy_finder/components/chat_files_preview.dart';
import 'package:roomy_finder/utilities/data.dart';

class ChatMessageV2Widget extends StatefulWidget {
  const ChatMessageV2Widget({
    super.key,
    required this.author,
    required this.msg,
    this.repliedMessage,
    this.previousMsg,
    this.nextMsg,
    this.onSweepToReply,
    required this.isSelectMode,
    this.isSelected,
    this.onSelectionChanged,
    this.onLongPress,
    this.onRepliedMessageTapped,
    this.lastReadDate,
    this.lastRecievedDate,
    required this.isRead,
    required this.isRecieved,
  });

  final User author;
  final ChatMessageV2 msg;
  final ChatMessageV2? repliedMessage;
  final ChatMessageV2? previousMsg;
  final ChatMessageV2? nextMsg;
  final void Function(ChatMessageV2 msg)? onSweepToReply;
  final void Function(ChatMessageV2 msg)? onLongPress;
  final bool isSelectMode;
  final bool? isSelected;
  final void Function(bool?)? onSelectionChanged;
  final void Function(ChatMessageV2 msg)? onRepliedMessageTapped;
  // final bool? isPlayingVoice;
  // final bool? playProgress;
  final DateTime? lastReadDate;
  final DateTime? lastRecievedDate;
  final bool isRead;
  final bool isRecieved;

  static const Color rightColor = ROOMY_ORANGE;
  static const Color leftColor = ROOMY_PURPLE;
  static const Color rightShadedColor = Color(0xFF4E2C21);
  static const Color leftShadedColor = Color(0xFF0F273B);

  @override
  State<ChatMessageV2Widget> createState() => _ChatMessageV2WidgetState();
}

class _ChatMessageV2WidgetState extends State<ChatMessageV2Widget> {
  late final StreamSubscription<PlaybackDisposition>? _voiceNoteStream;

  FlutterSoundPlayer get _player => VoicePlayerHelper.player;
  Duration _totalDuraton = const Duration(seconds: 1);
  Duration _playedProgress = Duration.zero;

  ChatMessageV2 get msg => widget.msg;

  @override
  void initState() {
    if (msg.voiceSeconds != null) {
      _totalDuraton = Duration(seconds: msg.voiceSeconds!);
    }

    _voiceNoteStream = VoicePlayerHelper.player.onProgress
        ?.asBroadcastStream()
        .listen((event) {
      if (VoicePlayerHelper.currentId == msg.id) {
        _totalDuraton = event.duration;
        _playedProgress = event.position;

        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _voiceNoteStream?.cancel();
    super.dispose();
  }

  bool get isPlaying {
    return VoicePlayerHelper.currentId == msg.id && _player.isPlaying;
  }

  bool get ispaused {
    return VoicePlayerHelper.currentId == msg.id && _player.isPaused;
  }

  bool get isStopped {
    return _player.isStopped;
  }

  double get progressPercentage {
    if (_totalDuraton.inSeconds == 0) return 0;
    return _playedProgress.inSeconds / _totalDuraton.inSeconds;
  }

  String get sentDateString {
    var date = widget.msg.createdAt.toLocal();
    var today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ).toLocal();

    if (date.isBefore(today)) {
      return Jiffy.parseFromDateTime(date).yMMMEd;
    }
    return Jiffy.parseFromDateTime(date).Hm;
  }

  Future<void> _pauseVoice() async {
    if (isPlaying) await _player.pausePlayer();

    setState(() {});
  }

  Future<void> _resumeVoice() async {
    VoicePlayerHelper.currentId = msg.id;

    _player.stopPlayer();
    await _player.seekToPlayer(_playedProgress);

    var d = await _player.startPlayer(
      fromDataBuffer: msg.voiceFile,
      whenFinished: () {
        _playedProgress = Duration.zero;
        if (mounted) setState(() {});
      },
    );

    if (d != null) _totalDuraton = d;

    setState(() {});
  }

  Future<void> _speedVoice() async {
    if (VoicePlayerHelper.speed.value == 2) {
      VoicePlayerHelper.speed(0.5);
    } else {
      VoicePlayerHelper.speed(VoicePlayerHelper.speed.value + 0.5);
    }
    await _player.setSpeed(VoicePlayerHelper.speed.value);

    setState(() {});
  }

  Future<void> _seekVoice(double factor) async {
    _playedProgress = Duration(
      microseconds: (_totalDuraton.inMicroseconds * factor).toInt(),
    );
    setState(() {});

    if (VoicePlayerHelper.currentId != msg.id) return;

    if (_player.isPlaying || _player.isPaused) {
      await _player.seekToPlayer(_playedProgress);
    }
  }

  bool get isDeleted {
    return widget.msg.isDeletedForAll;
  }

  bool get isPreviousAuthor {
    return widget.previousMsg?.senderId != widget.author.id;
  }

  String? get firstUrl {
    if (widget.msg.content == null) return null;

    final match = urlRegex.firstMatch(widget.msg.content!);
    return match?[0];
  }

  bool get hasFiles => widget.msg.files.isNotEmpty;

  ChatMessageV2? get rpMsg => widget.repliedMessage;

  LinkPreviewStyle? get urlPreviewStyle {
    if (firstUrl == null) return null;

    if (widget.msg.content!.trim().isURL) return LinkPreviewStyle.large;

    final match = urlRegex.firstMatch(widget.msg.content!);

    if (match != null) return LinkPreviewStyle.small;
    return null;
  }

  void handleLinkPreviewTapped(String link) {
    // print(link);
    if (roomyFinderDynamicLinkDomainRegex1.hasMatch(firstUrl!)) {
      // print("Is roomy finder link");
    }
  }

  BoxConstraints get _boxConstraints {
    if (widget.msg.files.isNotEmpty) {
      var maxWidth2 =
          (Get.width * 0.7 > 300 ? 300 : Get.width * 0.7).toDouble();
      return BoxConstraints(
        maxWidth: maxWidth2,
        minWidth: maxWidth2,
      );
    }
    return BoxConstraints(maxWidth: Get.width * 0.8, minWidth: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          widget.msg.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
// Selection
        if (widget.isSelectMode == true && widget.msg.isMine)
          Checkbox.adaptive(
            value: widget.isSelected == true,
            onChanged: widget.onSelectionChanged,
          ),
        GestureDetector(
          onLongPress: widget.isSelectMode
              ? null
              : () {
                  if (widget.onLongPress != null) {
                    widget.onLongPress!(widget.msg);
                  }
                },
          child: SwipeTo(
            animationDuration: const Duration(milliseconds: 300),
            onLeftSwipe: widget.isSelectMode
                ? null
                : widget.msg.isMine
                    ? () {
                        if (widget.onSweepToReply != null) {
                          widget.onSweepToReply!(widget.msg);
                        }
                      }
                    : null,
            onRightSwipe: widget.isSelectMode
                ? null
                : widget.msg.isMine
                    ? null
                    : () {
                        if (widget.onSweepToReply != null) {
                          widget.onSweepToReply!(widget.msg);
                        }
                      },
            child: Align(
              alignment: widget.msg.isMine
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                constraints: _boxConstraints,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(10),
                    topRight: const Radius.circular(10),
                    bottomRight: Radius.circular(widget.msg.isMine ? 0 : 10),
                    bottomLeft: Radius.circular(widget.msg.isMine ? 10 : 0),
                  ),
                  color: widget.msg.isMine
                      ? ChatMessageV2Widget.rightColor
                      : ChatMessageV2Widget.leftColor,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: widget.msg.isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
// Link preview
                    if (firstUrl != null) ...[
                      LinkPreviewGenerator(
                        bodyMaxLines: 3,
                        link: firstUrl!,
                        linkPreviewStyle: urlPreviewStyle!,
                        showGraphic: true,
                        removeElevation: true,
                        borderRadius: 5,
                        errorWidget: const SizedBox(),
                        placeholderWidget: const SizedBox(),
                        onTap: () => handleLinkPreviewTapped(firstUrl!),
                        bodyStyle: const TextStyle(fontFamily: "Roboto"),
                        showDomain: false,
                      ),
                      const SizedBox(height: 5),
                    ],

// Replied message
                    if (rpMsg != null)
                      GestureDetector(
                        onTap: () {
                          widget.onRepliedMessageTapped != null
                              ? widget.onRepliedMessageTapped!(rpMsg!)
                              : null;
                        },
                        child: Container(
                          margin: const EdgeInsets.all(0),
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            color: widget.msg.isMine
                                ? ChatMessageV2Widget.rightShadedColor
                                : ChatMessageV2Widget.leftShadedColor,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                          ),
                          child: Builder(builder: (context) {
                            return Text(
                              rpMsg!.content ?? rpMsg!.typedMessage,
                              style: const TextStyle(color: Colors.grey),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            );
                          }),
                        ),
                      ),
                    if (rpMsg != null) const SizedBox(height: 5),

// Files
                    if (widget.msg.files.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(0),
                        padding: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          color: widget.msg.isMine
                              ? ChatMessageV2Widget.rightShadedColor
                              : ChatMessageV2Widget.leftShadedColor,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5)),
                        ),
                        child: ChatMessgeFilesPreviewGroup(
                          files: widget.msg.files,
                          width: Get.width * 0.6,
                          height: 250,
                        ),
                      ),
// Voice note

                    if (widget.msg.voiceFile != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (isStopped == true)
                            widget.author.ppWidget(size: 20)
                          else
                            GestureDetector(
                              onTap: _speedVoice,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey,
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Obx(() =>
                                    Text("x${VoicePlayerHelper.speed.value}")),
                              ),
                            ),
                          GestureDetector(
                            onTap: isPlaying ? _pauseVoice : _resumeVoice,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: SizedBox(
                                width: 40,
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                  overlayShape: SliderComponentShape.noOverlay),
                              child: Slider.adaptive(
                                thumbColor: Colors.blue,
                                value: progressPercentage,
                                onChanged: _seekVoice,
                              ),
                            ),
                          ),
                        ],
                      ),
// Message Content
                    if (widget.msg.content?.trim().isNotEmpty == true &&
                        !widget.msg.isVoice)
                      ReadMoreText(
                        "${widget.msg.content}",
                        trimLines: 10,
                        trimCollapsedText: "See more",
                        trimExpandedText: " See less",
                        style: const TextStyle(color: Colors.white),
                        trimMode: TrimMode.Line,
                        colorClickableText: Colors.blue,
                      ),

                    // const SizedBox(height: 5),
// Status && info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.msg.isVoice) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: isStopped
                                ? Text(
                                    "${widget.msg.voiceMinutues}:"
                                            .padLeft(2, "0") +
                                        "${widget.msg.voiceSeconds}"
                                            .padLeft(2, "0"),
                                    style: const TextStyle(color: Colors.grey),
                                  )
                                : Text(
                                    "${_playedProgress.inSeconds}"
                                        .padLeft(2, "0"),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                          ),
                          const Spacer(),
                        ],
                        // Text("${msg.recieveds.length} : ${msg.reads.length}"),
                        if (widget.msg.isMine)
                          Builder(
                            builder: (context) {
                              if (widget.msg.isSending) {
                                return const Icon(
                                  Icons.pending_outlined,
                                  color: Colors.white70,
                                  size: 15,
                                );
                              } else if (widget.isRead) {
                                return const Icon(
                                  Icons.done_all,
                                  color: ROOMY_PURPLE,
                                  size: 15,
                                );
                              } else if (widget.isRecieved) {
                                return const Icon(
                                  Icons.done_all,
                                  color: Colors.white70,
                                  size: 15,
                                );
                              } else {
                                return const Icon(
                                  Icons.done,
                                  color: Colors.white70,
                                  size: 15,
                                );
                              }
                            },
                          ),
                        if (widget.msg.isMine) const SizedBox(width: 5),
                        Text(
                          sentDateString,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
// Select mode
        if (widget.isSelectMode == true && !widget.msg.isMine)
          Checkbox.adaptive(
            value: widget.isSelected == true,
            onChanged: widget.onSelectionChanged,
          ),
      ],
    );
  }
}
