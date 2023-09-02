// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roomy_finder/models/chat/chat_conversation_v2.dart';
import 'package:roomy_finder/models/chat/chat_message_v2.dart';
import 'package:roomy_finder/models/user/user.dart';

@pragma("vm:entry-point")
late Isar ISAR;
var ISAR_IS_OPENNED = false;

@pragma("vm:entry-point")
Future<void> initIsar([String? userId]) async {
  if (ISAR_IS_OPENNED) return;

  var dir = await getApplicationSupportDirectory();

  if (userId != null) {
    dir = Directory(join(dir.path, userId));
    await dir.create();
  }

  ISAR = await Isar.open(
    [ChatConversationV2Schema, ChatMessageV2Schema, UserSchema],
    directory: dir.path,
    inspector: true,
  );

  ISAR_IS_OPENNED = true;
}
