import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String _tokenKey = 'dermaire_jwt_token';
  static const String _userKey = 'dermaire_user_data';

  String get defaultBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    } catch (_) {}
    return 'http://127.0.0.1:8000/api/v1';
  }

  late String baseUrl = defaultBaseUrl;
  String? _authToken;
  Map<String, dynamic>? _currentUser;

  String? get authToken => _authToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_tokenKey);
      final rawUser = prefs.getString(_userKey);
      if (rawUser != null) {
        _currentUser = jsonDecode(rawUser) as Map<String, dynamic>;
      }
    } catch (_) {}
  }

  Map<String, String> _headers([bool isJson = true]) {
    final headers = <String, String>{};
    if (isJson) headers['Content-Type'] = 'application/json';
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String role = 'patient',
    bool acceptSafety = true,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
        'accept_safety': acceptSafety,
      }),
    );
    if (res.body.isEmpty) {
      throw ApiException('Empty response from server (status ${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      await _persistAuth(data);
      return data;
    }
    throw ApiException(data['message']?.toString() ?? 'Registration failed', data);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.body.isEmpty) {
      throw ApiException('Empty response from server (status ${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      await _persistAuth(data);
      return data;
    }
    throw ApiException(data['message']?.toString() ?? 'Login failed', data);
  }

  Future<void> _persistAuth(Map<String, dynamic> data) async {
    _authToken = data['access_token'] as String?;
    _currentUser = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_authToken != null) await prefs.setString(_tokenKey, _authToken!);
      await prefs.setString(_userKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> logout() async {
    _authToken = null;
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (_) {}
  }

  Future<bool> deleteAccount() async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/users/me'), headers: _headers(false));
      await logout();
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      await logout();
      return true;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final res = await http.get(Uri.parse('$baseUrl/users/me'), headers: _headers(false));
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final user = jsonDecode(res.body) as Map<String, dynamic>;
      _currentUser = user;
      return user;
    }
    return null;
  }

  Future<Map<String, dynamic>> updateSkinProfile({
    String? skinType,
    String? selectedGoal,
    List<String>? skinConcerns,
  }) async {
    final bodyMap = <String, dynamic>{};
    if (skinType != null) bodyMap['skin_type'] = skinType;
    if (selectedGoal != null) bodyMap['selected_goal'] = selectedGoal;
    if (skinConcerns != null) bodyMap['skin_concerns'] = skinConcerns;

    final res = await http.patch(
      Uri.parse('$baseUrl/users/skin-profile'),
      headers: _headers(),
      body: jsonEncode(bodyMap),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      _currentUser = data;
      return data;
    }
    throw ApiException(data['message']?.toString() ?? 'Failed to update skin profile', data);
  }

  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: _headers(),
      body: jsonEncode({'message': message}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw ApiException(data['message']?.toString() ?? 'Chat failed', data);
  }

  Future<List<Map<String, dynamic>>> getProducts({
    String? category,
    bool? inRoutine,
    bool? inExperiment,
  }) async {
    final qp = <String, String>{};
    if (category != null) qp['category'] = category;
    if (inRoutine != null) qp['in_routine'] = inRoutine.toString();
    if (inExperiment != null) qp['in_experiment'] = inExperiment.toString();
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: qp.isNotEmpty ? qp : null);
    final res = await http.get(uri, headers: _headers(false));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> product) async {
    final res = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: _headers(),
      body: jsonEncode(product),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw ApiException(data['message']?.toString() ?? 'Failed to add product', data);
  }

  Future<void> deleteProduct(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/products/$id'), headers: _headers(false));
    if (res.statusCode != 204 && res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException(data['message']?.toString() ?? 'Failed to delete product', data);
    }
  }

  Future<Map<String, dynamic>> checkInteractions(List<String> ingredients) async {
    final res = await http.post(
      Uri.parse('$baseUrl/products/check-interactions'),
      headers: _headers(),
      body: jsonEncode({'ingredients': ingredients}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getCurrentExperiment() async {
    final res = await http.get(Uri.parse('$baseUrl/experiments/current'), headers: _headers(false));
    if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>> togglePauseExperiment(String experimentId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/experiments/$experimentId/toggle-pause'),
      headers: _headers(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCheckIns() async {
    final res = await http.get(Uri.parse('$baseUrl/checkins'), headers: _headers(false));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> submitCheckIn({
    required String timeOfDay,
    required double hydration,
    required double texture,
    required double redness,
    String? notes,
    String? experimentId,
    List<int>? photoBytes,
    String? photoFilename,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/checkins'));
    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }
    request.fields['time_of_day'] = timeOfDay;
    request.fields['hydration_score'] = hydration.toString();
    request.fields['texture_score'] = texture.toString();
    request.fields['redness_score'] = redness.toString();
    if (notes != null) request.fields['notes'] = notes;
    if (experimentId != null) request.fields['experiment_id'] = experimentId;

    if (photoBytes != null && photoBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: photoFilename ?? 'skin_photo.jpg',
      ));
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw ApiException(data['message']?.toString() ?? 'Check-in failed', data);
  }

  Future<Map<String, dynamic>> generateDoctorQr({int minutes = 60}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/doctor/generate-qr?minutes_valid=$minutes'),
      headers: _headers(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<bool> claimDoctorAccess(String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/doctor/claim'),
      headers: _headers(),
      body: jsonEncode({'access_token': token}),
    );
    return res.statusCode == 200;
  }

  Future<bool> revokeDoctorAccess(String patientId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/doctor/revoke/$patientId'),
      headers: _headers(false),
    );
    return res.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> getDoctorPatients() async {
    final res = await http.get(Uri.parse('$baseUrl/doctor/patients'), headers: _headers(false));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> addClinicalNote({
    required String patientId,
    required String content,
    String priority = 'routine',
    String? followUp,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/doctor/patients/$patientId/notes'),
      headers: _headers(),
      body: jsonEncode({
        'content': content,
        'priority': priority,
        'follow_up': followUp,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> redeemReward(String rewardId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/rewards/redeem'),
      headers: _headers(),
      body: jsonEncode({'reward_id': rewardId}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw ApiException(data['message']?.toString() ?? 'Redemption failed', data);
  }
}

class ApiException implements Exception {
  ApiException(this.message, [this.details]);
  final String message;
  final Map<String, dynamic>? details;

  @override
  String toString() => message;
}
