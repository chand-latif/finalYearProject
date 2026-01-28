import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../exceptions/app_exception.dart';

/// Service for handling local storage operations using SharedPreferences.
/// Provides a clean API for storing and retrieving auth tokens and user data.
class StorageService {
  SharedPreferences? _prefs;

  /// Initialize the storage service. Must be called before using any methods.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      throw StorageException(
        'Failed to initialize storage',
        originalException: e,
      );
    }
  }

  /// Get the SharedPreferences instance
  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StorageException(
        'StorageService not initialized. Call init() first.',
      );
    }
    return _prefs!;
  }

  // ==================== Auth Token ====================

  /// Save the authentication token
  Future<void> saveAuthToken(String token) async {
    await _preferences.setString(AppConstants.authTokenKey, token);
  }

  /// Get the stored authentication token
  String? getAuthToken() {
    return _preferences.getString(AppConstants.authTokenKey);
  }

  /// Check if user is authenticated (has a valid token)
  bool isAuthenticated() {
    final token = getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Remove the authentication token (logout)
  Future<void> removeAuthToken() async {
    await _preferences.remove(AppConstants.authTokenKey);
  }

  // ==================== User Type ====================

  /// Save the user type (Customer or Seller)
  Future<void> saveUserType(String userType) async {
    await _preferences.setString(AppConstants.userTypeKey, userType);
  }

  /// Get the stored user type
  String? getUserType() {
    return _preferences.getString(AppConstants.userTypeKey);
  }

  /// Check if user is a customer
  bool isCustomer() {
    return getUserType() == AppConstants.customerType;
  }

  /// Check if user is a seller
  bool isSeller() {
    return getUserType() == AppConstants.sellerType;
  }

  // ==================== User ID ====================

  /// Save the user ID
  Future<void> saveUserId(int userId) async {
    await _preferences.setInt(AppConstants.userIdKey, userId);
  }

  /// Get the stored user ID
  int? getUserId() {
    return _preferences.getInt(AppConstants.userIdKey);
  }

  // ==================== Company ID ====================

  /// Save the company ID (for sellers)
  Future<void> saveCompanyId(int companyId) async {
    await _preferences.setInt(AppConstants.companyIdKey, companyId);
  }

  /// Get the stored company ID
  int? getCompanyId() {
    return _preferences.getInt(AppConstants.companyIdKey);
  }

  // ==================== Clear All ====================

  /// Clear all stored data (full logout)
  Future<void> clearAll() async {
    await _preferences.remove(AppConstants.authTokenKey);
    await _preferences.remove(AppConstants.userTypeKey);
    await _preferences.remove(AppConstants.userIdKey);
    await _preferences.remove(AppConstants.companyIdKey);
  }

  /// Save multiple user data at once after login
  Future<void> saveUserData({
    required String token,
    required String userType,
    required int userId,
    int? companyId,
  }) async {
    await saveAuthToken(token);
    await saveUserType(userType);
    await saveUserId(userId);
    if (companyId != null) {
      await saveCompanyId(companyId);
    }
  }
}
