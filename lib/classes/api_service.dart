import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/data/constants.dart';

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
            AppController.instance.logout();
            Get.offAllNamed('/login');
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

  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    final dio = ApiService.getDio;
    final res = await dio.get('$API_URL/profile//profile-info?userId=$userId');
    if (res.statusCode == 200) return res.data as Map<String, dynamic>?;
    return null;
  }
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
  } on DioError catch (e) {
    Get.log('Dio Get Token Error : $e');
    return null;
  }
}

bool _validateStatus(status) {
  if (status == null) return false;
  if (_validStatus.contains(status)) return true;
  return false;
}
