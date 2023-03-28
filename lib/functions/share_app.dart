import 'package:get/get_utils/get_utils.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/functions/snackbar_toast.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareApp() async {
  try {
    const message =
        "Rent your properties and find roommates easily with Roomy Finder";
    const text = "$SHARE_APP_LINK\n$message";

    Share.share(text);
  } catch (_) {
    showToast("Failed to open link".tr);
  }
}
