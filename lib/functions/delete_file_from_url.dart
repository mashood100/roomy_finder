import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

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
