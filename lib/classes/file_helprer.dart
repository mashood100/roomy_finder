// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:get/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:roomy_finder/functions/dialogs_bottom_sheets.dart';
import 'package:path/path.dart' as path;
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:roomy_finder/utilities/data.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

const _folder = "Roomy Finder";

class FileHelper {
  static Uint8List? NEW_MESSAGE_SOUND;

  static Future<void> loadAssets() async {
    try {
      var byte =
          await rootBundle.load("assets/audio/in_chat_new_message_sound.mp3");
      NEW_MESSAGE_SOUND = byte.buffer.asUint8List();
    } catch (e) {
      Get.log("$e");
    }
  }

  static Future<bool> requestPermission(Permission permission) async {
    if (await permission.isGranted) return true;

    const permenentlyDeniedMssage = "Permission is permently denied."
        " Will you open settings to grant permission?";

    if (await permission.isDenied) {
      final status = await permission.request();

      if (status == PermissionStatus.granted) return true;
      if (status == PermissionStatus.denied) return false;
      if (status == PermissionStatus.permanentlyDenied) {
        final res = await showConfirmDialog(permenentlyDeniedMssage);

        if (res == true) {
          final haveOpenedSettings = await openAppSettings();

          if (haveOpenedSettings) {
            final status = await permission.request();
            if (status == PermissionStatus.granted) return true;
            showToast(
              "You need to open the app setting"
              " an grant $permission mannually",
              duration: 5,
            );
            if (status == PermissionStatus.denied) return false;
            if (status == PermissionStatus.permanentlyDenied) return false;
          } else {
            showToast(
              "You need to open the app setting"
              " an grant $permission mannually",
              duration: 5,
            );
            return false;
          }
        }
      }
    }
    if (await permission.isPermanentlyDenied) {
      final res = await showConfirmDialog(permenentlyDeniedMssage);

      if (res == true) {
        final haveOpenedSettings = await openAppSettings();

        if (haveOpenedSettings) {
          final status = await permission.request();
          if (status == PermissionStatus.granted) return true;
          if (status == PermissionStatus.denied) return false;
          if (status == PermissionStatus.permanentlyDenied) return false;
        } else {
          return false;
        }
      }
    }
    // final extDir = await getAp

    return false;
  }

  static Future<String> getPossibleLocalPath(Uri uri) async {
    final appDir = await getApplicationDocumentsDirectory();
    final directory = Directory("${appDir.path}/$_folder/");

    if (!directory.existsSync()) directory.createSync(recursive: true);

    var fileName = path.basename(Uri.decodeComponent(uri.path));
    var ext = path.extension(fileName);

    final String subFolder;

    var isDoc = DOCUMENT_EXTENSIONS.contains(path.extension(ext.toLowerCase()));

    if (ext.isImageFileName) {
      subFolder = "Images";
    } else if (ext.isVideoFileName) {
      subFolder = "Videos";
    } else if (isDoc) {
      subFolder = "Documents";
    } else if (ext.isAudioFileName) {
      subFolder = "Audios";
    } else {
      subFolder = "Others";
    }

    return path.join(
      directory.path,
      "Media",
      subFolder,
      fileName,
    );
  }

  static Future<bool> copyFileToPath(File file, String filePath) async {
    file.copySync(filePath);

    return true;
  }

  static Future<void> deleteFiles(List<String> urls) async {
    for (var e in urls) {
      try {
        final path = await getPossibleLocalPath(Uri.parse(e));

        File(path).deleteSync();
      } catch (e, trace) {
        Get.log("$e\n$trace");
      }
    }
  }

  static Future<String?> downloadFileFromUri(
    Uri uri, [
    void Function(int count, int total)? onRecieved,
  ]) async {
    final savePath = await getPossibleLocalPath(uri);

    final file = File(savePath);
    if (!file.existsSync()) file.createSync(recursive: true);

    final res = await Dio().getUri(
      uri,
      onReceiveProgress: onRecieved,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
      ),
    );

    file.writeAsBytesSync(res.data);

    return savePath;
  }

  static Future<bool> resourceIsSavedLocally(Uri uri) async {
    final path = await getPossibleLocalPath(uri);

    var file = File(path);

    return file.existsSync();
  }

  static Future<Uint8List?> compressImageFile(File file) async {
    var result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 200,
      minHeight: 200,
      quality: 10,
      rotate: 0,
      format: CompressFormat.jpeg,
    );
    return result;
  }
}
