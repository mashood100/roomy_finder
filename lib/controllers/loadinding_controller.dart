import 'package:get/state_manager.dart';

class LoadingController extends GetxController {
  final isLoading = false.obs;
  final hasError = false.obs;
  final hasFetchError = false.obs;
  final Rx<String?> errorMessage = null.obs;

  bool get isErrorMessageNull => errorMessage.value == null;
}
