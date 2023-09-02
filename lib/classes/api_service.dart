import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/models/chat/chat_conversation_v2.dart';
import 'package:roomy_finder/models/chat/chat_message_v2.dart';
import 'package:roomy_finder/models/maintenance.dart';
import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/property_booking.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:roomy_finder/models/user/user.dart';
import 'package:roomy_finder/screens/home/home.dart';

const _validStatus = [200, 201, 204, 400, 403, 409, 404, 406, 500, 502, 503];

class ApiService {
  final Dio dio = Dio();

  static Dio get getDio => ApiService().dio;

  ApiService() {
    dio.options.baseUrl = API_URL;
    dio.options.validateStatus = _validateStatus;

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (e, handler) async {
          if (e.response == null) return handler.next(e);
          final RequestOptions requestOptions = e.response!.requestOptions;

          final response = e.response;
          if (response == null) return handler.next(e);
          if (response.statusCode != 401) return handler.next(e);

          final token = await getToken();

          if (token == null) {
            // AppController.instance.logout();
            // Get.offAllNamed('/login');
            return handler.reject(e);
          }

          AppController.instance.setApiToken(token);

          requestOptions.headers["authorization"] = "Bearer $token";

          final newResponse = await Dio(BaseOptions(
            baseUrl: API_URL,
            headers: requestOptions.headers,
            queryParameters: requestOptions.queryParameters,
            validateStatus: requestOptions.validateStatus,
            contentType: requestOptions.contentType,
            extra: requestOptions.extra,
            method: requestOptions.method,
          )).request(
            requestOptions.path,
            data: requestOptions.data,
            onReceiveProgress: requestOptions.onReceiveProgress,
            onSendProgress: requestOptions.onSendProgress,
            cancelToken: requestOptions.cancelToken,
          );

          return handler.resolve(newResponse);
        },
        onRequest: (options, handler) {
          options.headers
              .addAll({"authorization": "Bearer ${AppController.apiToken}"});

          if (options.method.toUpperCase() == "POST" ||
              options.method.toUpperCase() == "PUT") {
            options.headers.addAll({"Content-Type": "application/json"});
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.statusCode == 500) {
            Get.log('500 SERVER ERROR at ${response.requestOptions.path}'
                ' with code ${response.statusCode}');
          }

          handler.next(response);
        },
      ),
    );
  }

  static Future<bool> checkIfUserExist(String email) async {
    final dio = ApiService.getDio;
    final res = await dio.get('$API_URL/auth/user-exist?email=$email');
    return res.data["exist"] as bool;
  }

  static Future<bool> checkIfPhoneIsUsed(String phone) async {
    final dio = ApiService.getDio;
    final res = await dio
        .get('$API_URL/auth/phone-is-used?', queryParameters: {"phone": phone});
    return res.data["exist"] as bool;
  }

  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    final dio = ApiService.getDio;
    final res = await dio.get('$API_URL/profile/profile-info?userId=$userId');
    if (res.statusCode == 200) return res.data as Map<String, dynamic>?;
    return null;
  }

  Future<String?> getToken() async {
    final dio = Dio();

    try {
      final res = await dio.post("$API_URL/auth/token", data: {
        "email": AppController.instance.user.value.email,
        "password": AppController.instance.user.value.password,
      });

      if (res.statusCode == 200) return res.data['token'] as String;
      return null;
    } on DioException catch (e) {
      Get.log('Dio Get Token Error : $e');
      return null;
    }
  }

  bool _validateStatus(status) {
    if (status == null) return false;
    if (_validStatus.contains(status)) return true;
    return false;
  }

  static Future<Maintenance?> fetchMaitenance(String id) async {
    try {
      final res = await ApiService.getDio.get(
        "/maintenances/single-maintenance?id=$id",
      );

      if (res.statusCode == 200) {
        return Maintenance.fromMap(res.data);
      } else {
        return null;
      }
    } catch (e) {
      Get.log("$e");
      return null;
    }
  }

  static Future<PropertyAd?> fetchPropertyAd(String adId) async {
    try {
      final res = await getDio.get("$API_URL/ads/property-ad/$adId");

      if (res.statusCode == 200) return PropertyAd.fromMap(res.data);
      return null;
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      return null;
    }
  }

  static Future<RoommateAd?> fetchRoommateAd(String adId) async {
    try {
      final res = await getDio.get("$API_URL/ads/roommate-ad/$adId");

      if (res.statusCode == 200) return RoommateAd.fromMap(res.data);
      return null;
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      return null;
    }
  }

  static Future<PropertyBooking?> fetchBooking(String bookingId) async {
    try {
      final res = await getDio.get("/bookings/property-ad/$bookingId");

      if (res.statusCode == 200) {
        return PropertyBooking.fromMap(res.data);
      }
      return null;
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      return null;
    }
  }

  @pragma("vm:entry-point")
  static Future<User?> fetchUser(String userId) async {
    try {
      final res = await getDio.get("/profile/profile-info?userId=$userId");

      if (res.statusCode == 200) {
        return User.fromMap(res.data);
      }
      return null;
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      return null;
    }
  }

  @pragma("vm:entry-point")
  static Future<void> updateMessage(Map<String, dynamic> data) async {
    try {
      final res =
          await Dio().post("$API_URL/messaging-v2/update-message", data: data);

      _log(res.statusCode);
    } on DioException catch (e) {
      _log(e.message);
    }
  }

  static Future<int?> setUnreadBookingCount() async {
    try {
      final res = await ApiService.getDio.get(
        "/bookings/property-ad/unviewed-bookings-count",
      );

      if (res.statusCode == 200) {
        Home.unViewBookingsCount(res.data);
        return res.data;
      }
      return null;
    } catch (e) {
      Get.log("$e");
      return null;
    }
  }

  static Future<bool?> setLanlordIsBlocked() async {
    try {
      final res = await ApiService.getDio.get("/profile/dashboard-is-blocked");

      if (res.statusCode == 200) {
        AppController.dashboardIsBlocked = res.data["isBlocked"];
        return AppController.dashboardIsBlocked;
      }
      return null;
    } catch (e) {
      Get.log("$e");
      return null;
    }
  }

  static Future<void> updateUserProfile() async {
    try {
      final res = await ApiService.getDio.get("/profile");

      if (res.statusCode == 200) {
        final user = User.fromMap(res.data);
        AppController.instance.user(user);
        AppController.saveUser(user);
      }
    } catch (e) {
      Get.log("$e");
    }
  }

  static Future<bool> logoutUser(
    String userId,
    String fcmToken,
  ) async {
    try {
      final res = await Dio().post(
        "$API_URL/auth/logout",
        data: {"fcmToken": fcmToken, "userId": userId},
      );

      if (res.statusCode == 200) {
        return true;
      }
      Get.log("Api_Service logout status code : ${res.statusCode}");
      return false;
    } catch (e, trace) {
      Get.log("$e");
      Get.log("$trace");
      return false;
    }
  }

  static Future<List<RoommateAd>> getUserRoommateAds(String id) async {
    final res = await getDio.get("/user/$id/roommate-ads");
    return (res.data as List).map((e) => RoommateAd.fromMap(e)).toList();
  }

  static Future<List<PropertyAd>> getUserPropertyAds(String id) async {
    final res = await getDio.get("/user/$id/property-ads");
    return (res.data as List).map((e) => PropertyAd.fromMap(e)).toList();
  }

  static Future<ChatConversationV2?> fetchConversation(key) async {
    try {
      final res = await getDio.get("/messaging-v2/conversation/$key");

      if (res.statusCode == 200) {
        return ChatConversationV2.fromMap(res.data);
      }
      return null;
    } catch (e) {
      Get.log("$e");
      return null;
    }
  }

  static Future<ChatMessageV2?> fetchMessage(messageId) async {
    try {
      final res = await getDio.get("/messaging-v2/$messageId");

      if (res.statusCode == 200) {
        return ChatMessageV2.fromMap(res.data);
      }
      return null;
    } catch (e) {
      Get.log("$e");
      return null;
    }
  }
}

// void _log(data) => print("[ API_SERVICE ] : $data");
void _log(data) {}
