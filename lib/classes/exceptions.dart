class ApiServiceException implements Exception {
  String? message;
  int? statusCode;
  String? code;

  ApiServiceException({this.message, this.statusCode, this.code});

  @override
  String toString() {
    return 'BaseApiException : Message : '
        '$message, Status Code : $statusCode, code : $code';
  }
}
