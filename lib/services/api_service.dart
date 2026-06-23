// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：HTTP API服务封装

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// API Service — singleton Dio-based client for the backend
// ---------------------------------------------------------------------------

/// HTTP API服务类（单例模式），封装所有后端接口调用
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

  /// 从本地存储加载认证令牌
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  /// 保存认证令牌到本地存储
  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// 清除本地存储的认证令牌
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
  /// 处理API响应，统一错误检查
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
  /// 处理API响应，统一错误检查
    return _handleResponse(response);
  }

  /// Fetch the current user profile. Requires a valid token in [_token].
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/user/profile');
  /// 处理API响应，统一错误检查
    return _handleResponse(response);
  }

  /// Search for a user by phone number.
  Future<Map<String, dynamic>> searchUser(String phone) async {
    final response = await _dio.get(
      '/user/search',
      queryParameters: {'phone': phone},
    );
  /// 处理API响应，统一错误检查
    return _handleResponse(response);
  }

  /// 通过手机号查找用户ID，如果输入已是ID则直接返回
  Future<String> resolveUserId(String phoneOrId) async {
    // 非纯数字视为已有ID
    if (RegExp(r'^\d{11}$').hasMatch(phoneOrId)) {
      try {
        final user = await searchUser(phoneOrId);
        final id = user['id'] as String?;
        if (id != null && id.isNotEmpty) return id;
      } catch (_) {
        // lookup failed, fall through to use as-is
      }
    }
    return phoneOrId;
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
  /// 处理API响应，统一错误检查
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
  // Read Receipt API (placeholder)
  // -------------------------------------------------------------------------

  /// 标记与某用户的会话为已读。后端接口暂未实现时静默忽略。
  Future<void> markConversationRead(String otherId) async {
    try {
      await _dio.post('/messages/read', data: {'with': otherId});
    } catch (_) {
      // Backend API not implemented yet — ignore
    }
  }

  // -------------------------------------------------------------------------
  // Friend API
  // -------------------------------------------------------------------------

  /// Send a friend request by phone number.
  /// Returns null on success (request sent).
  /// Returns a user-info Map when users are already friends.
  /// Throws [Exception] on other errors.
  Future<Map<String, dynamic>?> sendFriendRequest(String toPhone) async {
    String? errorMsg;

    try {
      final response = await _dio.post('/friends/request', data: {'to_phone': toPhone});
      // Check response body for application-level errors
      final data = response.data as Map<String, dynamic>?;
      if (data != null) {
        final code = data['code'] as int?;
        if (code != null && code != 200) {
          errorMsg = data['message'] as String? ?? '请求失败';
        }
      }
    } on DioException catch (e) {
      errorMsg = _extractErrorMessage(e);
      if (errorMsg.isEmpty) errorMsg = '请求失败';
    }

    if (errorMsg != null) {
      // If already friends, search for the user and return their info
      if (errorMsg.toLowerCase().contains('already friends')) {
        try {
          return await searchUser(toPhone);
        } catch (_) {
          return null;
        }
      }
      throw Exception(errorMsg);
    }

    return null; // success — request sent
  }

  /// Extract a human-readable error message from a DioException
  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) return (data['message'] as String?) ?? '';
    if (data is String) return data;
    return e.message ?? '';
  }

  /// Get incoming friend requests.
  Future<List<dynamic>> getFriendRequests() async {
    final response = await _dio.get('/friends/requests');
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  /// Accept a friend request.
  Future<void> acceptFriendRequest(String requestId) async {
    await _dio.post('/friends/accept', data: {'request_id': requestId});
  }

  /// Reject a friend request.
  Future<void> rejectFriendRequest(String requestId) async {
    await _dio.post('/friends/reject', data: {'request_id': requestId});
  }

  /// Get the friend list.
  Future<List<dynamic>> getFriendList() async {
    final response = await _dio.get('/friends/list');
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  // -------------------------------------------------------------------------
  // Call API
  // -------------------------------------------------------------------------

  /// Start a call (audio or video).
  Future<Map<String, dynamic>> startCall({
    required String toUserId,
    required String callType, // "audio" or "video"
  }) async {
    final response = await _dio.post('/call/start', data: {
      'to_user_id': toUserId,
      'call_type': callType,
    });
  /// 处理API响应，统一错误检查
    return _handleResponse(response);
  }

  /// Accept an incoming call.
  Future<Map<String, dynamic>> acceptCall(String callId) async {
    final response = await _dio.post('/call/accept', data: {
      'call_id': callId,
    });
  /// 处理API响应，统一错误检查
    return _handleResponse(response);
  }

  /// Reject an incoming call.
  Future<Map<String, dynamic>> rejectCall(String callId) async {
    final response = await _dio.post('/call/reject', data: {
      'call_id': callId,
    });
  /// 处理API响应，统一错误检查
    return _handleResponse(response);
  }

  /// End an active call.
  Future<Map<String, dynamic>> endCall(String callId) async {
    final response = await _dio.post('/call/end', data: {
      'call_id': callId,
    });
  /// 处理API响应，统一错误检查
    return _handleResponse(response);
  }

  // -------------------------------------------------------------------------
  // Housing API
  // -------------------------------------------------------------------------

  /// Publish a housing listing.
  Future<Map<String, dynamic>> publishHousing(Map<String, dynamic> data) async {
    final response = await _dio.post('/housing/publish', data: data);
    return _handleResponse(response);
  }

  /// List housing listings with filters.
  Future<Map<String, dynamic>> listHousing({int page = 1, int pageSize = 20, String? province, String? city, String? district, String? propertyType, double? priceMin, double? priceMax, String? decoration, String? keyword}) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (province != null) params['province'] = province;
    if (city != null) params['city'] = city;
    if (district != null) params['district'] = district;
    if (propertyType != null) params['property_type'] = propertyType;
    if (priceMin != null) params['price_min'] = priceMin;
    if (priceMax != null) params['price_max'] = priceMax;
    if (decoration != null) params['decoration'] = decoration;
    if (keyword != null) params['keyword'] = keyword;
    final response = await _dio.get('/housing/list', queryParameters: params);
    return _handleResponse(response);
  }

  /// Get housing detail.
  Future<Map<String, dynamic>> getHousingDetail(String id) async {
    final response = await _dio.get('/housing/$id');
    return _handleResponse(response);
  }

  /// Get my listings.
  Future<List<dynamic>> getMyHousingListings() async {
    final response = await _dio.get('/housing/my');
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  /// Add favorite.
  Future<void> addHousingFavorite(String id) async {
    await _dio.post('/housing/$id/favorite');
  }

  /// Remove favorite.
  Future<void> removeHousingFavorite(String id) async {
    await _dio.delete('/housing/$id/favorite');
  }

  /// Get favorites.
  Future<List<dynamic>> getHousingFavorites() async {
    final response = await _dio.get('/housing/favorites');
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  /// Get browse history.
  Future<List<dynamic>> getHousingBrowseHistory() async {
    final response = await _dio.get('/housing/history');
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  /// Update housing listing.
  Future<Map<String, dynamic>> updateHousing(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/housing/$id', data: data);
    return _handleResponse(response);
  }

  /// Delete housing listing.
  Future<void> deleteHousing(String id) async {
    await _dio.delete('/housing/$id');
  }

  // -------------------------------------------------------------------------
  // Jobs API
  // -------------------------------------------------------------------------

  /// Publish a job.
  Future<Map<String, dynamic>> publishJob(Map<String, dynamic> data) async {
    final response = await _dio.post('/jobs/publish', data: data);
    return _handleResponse(response);
  }

  /// List jobs.
  Future<Map<String, dynamic>> listJobs({int page = 1, int pageSize = 20, String? city, String? district, String? education, String? experience, String? keyword}) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (city != null) params['city'] = city;
    if (district != null) params['district'] = district;
    if (education != null) params['education'] = education;
    if (experience != null) params['experience'] = experience;
    if (keyword != null) params['keyword'] = keyword;
    final response = await _dio.get('/jobs/list', queryParameters: params);
    return _handleResponse(response);
  }

  /// Get job detail.
  Future<Map<String, dynamic>> getJobDetail(String id) async {
    final response = await _dio.get('/jobs/$id');
    return _handleResponse(response);
  }

  /// Apply for a job.
  Future<void> applyJob(String jobId) async {
    await _dio.post('/jobs/apply', data: {'job_id': jobId});
  }

  /// Get my applications.
  Future<List<dynamic>> getMyApplications() async {
    final response = await _dio.get('/jobs/applications');
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  /// Add job favorite.
  Future<void> addJobFavorite(String id) async {
    await _dio.post('/jobs/$id/favorite');
  }

  /// Remove job favorite.
  Future<void> removeJobFavorite(String id) async {
    await _dio.delete('/jobs/$id/favorite');
  }

  /// Get job favorites.
  Future<List<dynamic>> getJobFavorites() async {
    final response = await _dio.get('/jobs/favorites');
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  /// Save/Update resume.
  Future<Map<String, dynamic>> saveResume(Map<String, dynamic> data) async {
    final response = await _dio.post('/resume/create', data: data);
    return _handleResponse(response);
  }

  /// Get my resume.
  Future<Map<String, dynamic>> getMyResume() async {
    final response = await _dio.get('/resume/my');
    return _handleResponse(response);
  }

  /// Register company.
  Future<Map<String, dynamic>> registerCompany(Map<String, dynamic> data) async {
    final response = await _dio.post('/company/register', data: data);
    return _handleResponse(response);
  }

  /// Get company profile.
  Future<Map<String, dynamic>> getCompanyProfile() async {
    final response = await _dio.get('/company/profile');
    return _handleResponse(response);
  }

  /// Update company profile.
  Future<Map<String, dynamic>> updateCompanyProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/company/profile', data: data);
    return _handleResponse(response);
  }

  /// Schedule interview.
  Future<Map<String, dynamic>> scheduleInterview(Map<String, dynamic> data) async {
    final response = await _dio.post('/interview/schedule', data: data);
    return _handleResponse(response);
  }

  /// Get my interviews.
  Future<List<dynamic>> getMyInterviews() async {
    final response = await _dio.get('/interview/list');
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  // -------------------------------------------------------------------------
  // Mall API
  // -------------------------------------------------------------------------

  /// Publish product.
  Future<Map<String, dynamic>> publishProduct(Map<String, dynamic> data) async {
    final response = await _dio.post('/mall/product/publish', data: data);
    return _handleResponse(response);
  }

  /// List products.
  Future<Map<String, dynamic>> listProducts({int page = 1, int pageSize = 20, String? category, String? keyword}) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (category != null) params['category'] = category;
    if (keyword != null) params['keyword'] = keyword;
    final response = await _dio.get('/mall/product/list', queryParameters: params);
    return _handleResponse(response);
  }

  /// Get product detail.
  Future<Map<String, dynamic>> getProductDetail(String id) async {
    final response = await _dio.get('/mall/product/$id');
    return _handleResponse(response);
  }

  /// Add to cart.
  Future<void> addToCart(String productId, int quantity) async {
    await _dio.post('/mall/cart/add', data: {'product_id': productId, 'quantity': quantity});
  }

  /// Update cart item quantity.
  Future<void> updateCartItem(String productId, int quantity) async {
    await _dio.put('/mall/cart/update', data: {'product_id': productId, 'quantity': quantity});
  }

  /// Remove from cart.
  Future<void> removeFromCart(String productId) async {
    await _dio.delete('/mall/cart/$productId');
  }

  /// Get cart.
  Future<List<dynamic>> getCart() async {
    final response = await _dio.get('/mall/cart');
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  /// Create order.
  Future<Map<String, dynamic>> createOrder(List<Map<String, dynamic>> items) async {
    final response = await _dio.post('/mall/order/create', data: {'items': items});
    return _handleResponse(response);
  }

  /// List orders.
  Future<Map<String, dynamic>> listOrders({int page = 1, int pageSize = 20, String? status}) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (status != null) params['status'] = status;
    final response = await _dio.get('/mall/order/list', queryParameters: params);
    return _handleResponse(response);
  }

  /// Get order detail.
  Future<Map<String, dynamic>> getOrderDetail(String id) async {
    final response = await _dio.get('/mall/order/$id');
    return _handleResponse(response);
  }

  /// Ship order.
  Future<void> shipOrder(String id, {String? trackingNumber}) async {
    await _dio.post('/mall/order/$id/ship', data: {'tracking_number': trackingNumber ?? ''});
  }

  /// Receive order.
  Future<void> receiveOrder(String id) async {
    await _dio.post('/mall/order/$id/receive');
  }

  /// Complete order.
  Future<void> completeOrder(String id) async {
    await _dio.post('/mall/order/$id/complete');
  }

  /// Request refund.
  Future<void> requestRefund(String id, String reason) async {
    await _dio.post('/mall/order/$id/refund', data: {'reason': reason});
  }

  /// Create dispute.
  Future<Map<String, dynamic>> createDispute(Map<String, dynamic> data) async {
    final response = await _dio.post('/mall/dispute', data: data);
    return _handleResponse(response);
  }

  // -------------------------------------------------------------------------
  // Escrow API
  // -------------------------------------------------------------------------

  /// Create escrow order.
  Future<Map<String, dynamic>> createEscrow(Map<String, dynamic> data) async {
    final response = await _dio.post('/escrow/create', data: data);
    return _handleResponse(response);
  }

  /// List escrow orders.
  Future<Map<String, dynamic>> listEscrows({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get('/escrow/list', queryParameters: {'page': page, 'page_size': pageSize});
    return _handleResponse(response);
  }

  /// Get escrow detail.
  Future<Map<String, dynamic>> getEscrowDetail(String id) async {
    final response = await _dio.get('/escrow/$id');
    return _handleResponse(response);
  }

  /// Accept escrow.
  Future<void> acceptEscrow(String id) async {
    await _dio.post('/escrow/$id/accept');
  }

  /// Pay deposit.
  Future<void> payEscrowDeposit(String id) async {
    await _dio.post('/escrow/$id/deposit');
  }

  /// Confirm phase.
  Future<void> confirmEscrowPhase(String id, int phase) async {
    await _dio.post('/escrow/$id/confirm-phase', data: {'phase': phase});
  }

  /// Submit dispute.
  Future<void> submitEscrowDispute(String id, String note) async {
    await _dio.post('/escrow/$id/dispute', data: {'note': note});
  }

  // -------------------------------------------------------------------------
  // Dating API
  // -------------------------------------------------------------------------

  /// Save dating profile.
  Future<Map<String, dynamic>> saveDatingProfile(Map<String, dynamic> data) async {
    final response = await _dio.post('/dating/profile', data: data);
    return _handleResponse(response);
  }

  /// Get my dating profile.
  Future<Map<String, dynamic>> getMyDatingProfile() async {
    final response = await _dio.get('/dating/profile');
    return _handleResponse(response);
  }

  /// Get recommend list.
  Future<List<dynamic>> getDatingRecommend({String? gender, int? ageMin, int? ageMax}) async {
    final params = <String, dynamic>{};
    if (gender != null) params['gender'] = gender;
    if (ageMin != null) params['age_min'] = ageMin;
    if (ageMax != null) params['age_max'] = ageMax;
    final response = await _dio.get('/dating/recommend', queryParameters: params);
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  /// Like/dislike a user.
  Future<void> likeDatingUser(String toUid, {bool liked = true}) async {
    await _dio.post('/dating/like', data: {'to_uid': toUid, 'liked': liked});
  }

  /// Get matches.
  Future<List<dynamic>> getDatingMatches() async {
    final response = await _dio.get('/dating/matches');
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw Exception('empty response');
    if (body['code'] != 200) throw Exception(body['message'] ?? 'error');
    final data = body['data'];
    if (data is List) return data;
    return [];
  }

  // -------------------------------------------------------------------------
  // Mail API
  // -------------------------------------------------------------------------

  /// Send mail.
  Future<Map<String, dynamic>> sendMail(Map<String, dynamic> data) async {
    final response = await _dio.post('/mail/send', data: data);
    return _handleResponse(response);
  }

  /// Get inbox.
  Future<Map<String, dynamic>> getInbox({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get('/mail/inbox', queryParameters: {'page': page, 'page_size': pageSize});
    return _handleResponse(response);
  }

  /// Get sent mails.
  Future<Map<String, dynamic>> getSentMails({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get('/mail/sent', queryParameters: {'page': page, 'page_size': pageSize});
    return _handleResponse(response);
  }

  /// Get mail detail.
  Future<Map<String, dynamic>> getMailDetail(String id) async {
    final response = await _dio.get('/mail/$id');
    return _handleResponse(response);
  }

  /// Move mail to trash.
  Future<void> moveMailToTrash(String id) async {
    await _dio.post('/mail/$id/trash');
  }

  /// Delete mail permanently.
  Future<void> deleteMail(String id) async {
    await _dio.delete('/mail/$id');
  }

  // -------------------------------------------------------------------------
  // Upload API
  // -------------------------------------------------------------------------

  /// Upload an image file.
  Future<Map<String, dynamic>> uploadImage(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/upload/image', data: formData);
    return _handleResponse(response);
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
