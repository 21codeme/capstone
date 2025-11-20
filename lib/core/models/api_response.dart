class ApiResponse<T> {
  final T? data;
  final String message;
  final bool isSuccess;
  final int statusCode;
  final String? errorCode;

  ApiResponse._({
    required this.data,
    required this.message,
    required this.isSuccess,
    required this.statusCode,
    this.errorCode,
  });

  factory ApiResponse.success({
    T? data,
    String message = 'Success',
    int statusCode = 200,
  }) {
    return ApiResponse._(
      data: data,
      message: message,
      isSuccess: true,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error({
    String message = 'Error',
    int statusCode = 400,
    String? errorCode,
  }) {
    return ApiResponse._(
      data: null,
      message: message,
      isSuccess: false,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>)? fromJson) {
    final isSuccess = json['success'] ?? false;
    final message = json['message'] ?? 'No message';
    final statusCode = json['status_code'] ?? 200;
    final errorCode = json['error_code'];

    if (isSuccess) {
      T? data;
      if (fromJson != null && json['data'] != null) {
        data = fromJson(json['data']);
      }
      return ApiResponse.success(
        data: data,
        message: message,
        statusCode: statusCode,
      );
    } else {
      return ApiResponse.error(
        message: message,
        statusCode: statusCode,
        errorCode: errorCode,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'success': isSuccess,
      'message': message,
      'status_code': statusCode,
      if (errorCode != null) 'error_code': errorCode,
      if (data != null) 'data': data,
    };
  }

  @override
  String toString() {
    return 'ApiResponse{data: $data, message: $message, isSuccess: $isSuccess, statusCode: $statusCode, errorCode: $errorCode}';
  }
}









