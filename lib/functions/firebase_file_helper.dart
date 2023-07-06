import 'dart:io';
import 'dart:typed_data';

import "package:path/path.dart" as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import 'package:roomy_finder/functions/create_datetime_filename.dart';
import 'package:roomy_finder/utilities/data.dart';

Future<TaskSnapshot> uploadFileToStorage(
  File file, [
  Map<String, String>? customMetadata,
]) async {
  final data = await file.readAsBytes();

  return uploadUnit8ListToStorage(data, file.path);
}

Future<TaskSnapshot> uploadUnit8ListToStorage(
  Uint8List bytes,
  String filePath, {
  Map<String, String>? customMetadata,
}) async {
  final String subFolder;

  final isDocument =
      DOCUMENT_EXTENSIONS.contains(path.extension(filePath.toLowerCase()));

  if (filePath.isImageFileName) {
    subFolder = "Images";
  } else if (filePath.isVideoFileName) {
    subFolder = "Videos";
  } else if (filePath.isVideoFileName) {
    subFolder = "Audio";
  } else if (isDocument) {
    subFolder = "Documents";
  } else {
    subFolder = "Others";
  }

  final fileRef = FirebaseStorage.instance
      .ref()
      .child(subFolder)
      .child('${createDateTimeFileName()}${path.extension(filePath)}');

  final uploadTask = fileRef.putData(
    bytes,
    SettableMetadata(customMetadata: {
      "originalName": path.basename(filePath),
      ...?customMetadata,
    }),
  );

  final snapshot = await uploadTask;

  return snapshot;
}

Future<void> deleteFileFromUrl(String url) async {
  await FirebaseStorage.instance
      .refFromURL(url)
      .delete()
      .catchError((err) => Get.log('Fire delete error : $err'));
}

Future<void> deleteManyFilesFromUrl(List<String> urls) async {
  for (final url in urls) {
    await deleteFileFromUrl(url);
  }
}
