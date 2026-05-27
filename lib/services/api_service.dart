import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// API Service — singleton Dio-based client for the backend
// ---------------------------------------------------------------------------

class ApiService {
  static const String _baseUrl = 'http://localhost:8080/api';
  static const String _tokenKey = 'auth_token';

  final Dio _dio;
  String? _token;

  // -------------------------------------------------------------------------
  // Singleton
  // -------------------------------------------------------------------------

  ApiService._(this._dio) {
    // Interceptor: automatically attach Authorization header on every request.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
    ));
  }

  static final ApiService _instance = ApiService._(
    Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    )),
  );

  static ApiService get instance => _instance;

  // -------------------------------------------------------------------------
  // Token management
  // -------------------------------------------------------------------------

  String? get token => _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // -------------------------------------------------------------------------
  // Auth API
  // -------------------------------------------------------------------------

  /// Register a new user. Returns the response data map.
  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String code,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'phone': phone,
      'password': password,
      'code': code,
    });
    return _handleResponse(response);
  }

  /// Log in with phone + password. Returns the response data map.
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    return _handleResponse(response);
  }

  /// Fetch the current user profile. Requires a valid token in [_token].
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/user/profile');
    return _handleResponse(response);
  }

  /// Search for a user by phone number.
  Future<Map<String, dynamic>> searchUser(String phone) async {
    final response = await _dio.get(
      '/user/search',
      queryParameters: {'phone': phone},
    );
    return _handleResponse(response);
  }

  // -------------------------------------------------------------------------
  // Message API
  // -------------------------------------------------------------------------

  /// Send a message to another user.
  Future<Map<String, dynamic>> sendMessage({
    required String toId,
    required String content,
    String type = 'text',
  }) async {
    final response = await _dio.post(
      '/messages/send',
      data: {'to_id': toId, 'content': content, 'type': type},
    );
    return _handleResponse(response);
  }

  /// Get chat history with another user.
  Future<List<dynamic>> getChatHistory(String otherId, {int limit = 50, int offset = 0}) async {
    final response = await _dio.get(
      '/messages/chat',
      queryParameters: {'with': otherId, 'limit': limit, 'offset': offset},
    );
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    if (data is Map && data['messages'] is List) return data['messages'];
    return [];
  }

  /// Get conversation list.
  Future<List<dynamic>> getConversations() async {
    final response = await _dio.get('/messages/conversations');
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  Map<String, dynamic> _handleResponse(Response response) {
    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('服务器返回为空');
    }
    final code = data['code'] as int?;
    if (code != 200) {
      throw Exception(data['message'] ?? '请求失败');
    }
    return data['data'] as Map<String, dynamic>;
  }
}
