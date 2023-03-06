import 'package:get/get.dart';

part './messages_en.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys {
    return {
      "en": enMessages,
    };
  }
}
