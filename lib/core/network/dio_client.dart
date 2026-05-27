import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

/// Endpoints whose 401 responses must NOT trigger the global redirect to
/// `/welcome` — login failure is just a wrong password, and forgot/reset
/// password are anonymous flows that surface 4xx through their own UI.
const Set<String> _kAuthFlowPaths = {
  ApiConstants.login,
  ApiConstants.forgotPassword,
  ApiConstants.resetPassword,
  ApiConstants.otpSend,
  ApiConstants.otpVerify,
};

/// Hook the router can register so the interceptor can redirect on session
/// expiry without `DioClient` itself knowing about `go_router`.
typedef OnUnauthorized = void Function();

class DioClient {
  late final Dio _dio;
  final SharedPreferences? _prefs;
  OnUnauthorized? _onUnauthorized;
  bool _redirecting = false;

  DioClient({SharedPreferences? prefs}) : _prefs = prefs {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        validateStatus: (status) => status != null && status < 500,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          _maybeHandleUnauthorized(response.requestOptions, response.statusCode);
          handler.next(response);
        },
        onError: (err, handler) {
          _maybeHandleUnauthorized(err.requestOptions, err.response?.statusCode);
          handler.next(err);
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );
  }

  Dio get dio => _dio;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Registered by the router. Called once when an authenticated request
  /// returns 401 so the user is taken back to `/welcome` with the local
  /// session cleared.
  void registerUnauthorizedHandler(OnUnauthorized handler) {
    _onUnauthorized = handler;
  }

  void _maybeHandleUnauthorized(RequestOptions request, int? statusCode) {
    if (statusCode != 401) return;
    if (_redirecting) return;

    // Don't redirect for explicit auth-flow endpoints — their UI surfaces
    // the error directly (e.g. wrong password on login).
    final path = request.path;
    if (_kAuthFlowPaths.any(path.endsWith)) return;

    _redirecting = true;
    clearAuthToken();
    _prefs?.remove('CACHED_AUTH_TOKEN');

    final handler = _onUnauthorized;
    if (handler != null) {
      // Defer to the next microtask so we don't navigate from inside the
      // interceptor while a request is still being processed.
      Future.microtask(() {
        try {
          handler();
        } finally {
          _redirecting = false;
        }
      });
    } else {
      _redirecting = false;
    }
  }
}
