import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:roomy_finder/classes/place_autocomplete.dart';
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

  static Future<Iterable<PlaceAutoCompletePredicate>> searchPlaceAutoComplete({
    required String input,
    String language = "en",
    String types = "localities",
  }) async {
    if (input.isEmpty) return [];
    // final encodedCity = Uri.encodeComponent(city);
    final encodedInput = Uri.encodeComponent(input);

    var query = {
      "key": GOOGLE_CLOUD_API_KEY,
      "input": encodedInput,
      "language": language,
    };

    final res = await Dio().get(
      "https://maps.googleapis.com/maps/api/place/autocomplete/json",
      queryParameters: query,
    );

    if (res.statusCode == 200) {
      final data = res.data;
      if ((data["predictions"] as List).isNotEmpty) {}
      if (data["status"] == "OK") {
        final predicates = (data["predictions"] as List).map(
          (e) => PlaceAutoCompletePredicate(
            mainText: e["structured_formatting"]["main_text"],
            secondaryText: e["structured_formatting"]["secondary_text"],
            description: e["description"],
            placeId: e["place_id"],
            types: List<String>.from(e["types"]),
          ),
        );

        return predicates;
      } else {
        return [];
      }
    }
    return [];
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
