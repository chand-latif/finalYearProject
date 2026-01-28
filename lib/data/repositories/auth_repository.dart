import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';

/// Repository handling all authentication-related API calls.
class AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthRepository({
    required ApiClient apiClient,
    required StorageService storageService,
  })  : _apiClient = apiClient,
        _storageService = storageService;

  /// Sign in user with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.signIn,
      body: {
        'userEmail': email,
        'password': password,
      },
      includeAuth: false,
    );

    final data = response['data'];
    
    // Extract and save token
    final token = data['jwtAccessToken']?['access_Token'];
    if (token != null) {
      await _storageService.saveAuthToken(token);
    }

    // Fetch and return user info
    return await getUserInfo();
  }

  /// Sign up new user
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String userType,
  }) async {
    await _apiClient.post(
      ApiConstants.signUp,
      body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'userType': userType,
      },
      includeAuth: false,
    );
  }

  /// Get current user information
  Future<UserModel> getUserInfo() async {
    final response = await _apiClient.get(ApiConstants.getUserInfo);
    final userData = response['data'];
    final user = UserModel.fromJson(userData);

    // Save user data to storage
    await _storageService.saveUserData(
      token: _storageService.getAuthToken() ?? '',
      userType: user.userType,
      userId: user.userId,
      companyId: user.companyId,
    );

    return user;
  }

  /// Resend OTP verification code
  Future<void> resendOtp(String email) async {
    await _apiClient.put(
      ApiConstants.resendOtp,
      queryParams: {'Email': email},
      includeAuth: false,
    );
  }

  /// Verify OTP code
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    await _apiClient.put(
      ApiConstants.verifyOtp,
      queryParams: {
        'Email': email,
        'OTP': otp,
      },
      includeAuth: false,
    );
  }

  /// Request password reset (forgot password)
  Future<void> forgotPassword(String email) async {
    await _apiClient.post(
      ApiConstants.forgotPassword,
      queryParams: {'Email': email},
      includeAuth: false,
    );
  }

  /// Reset password with OTP
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _apiClient.put(
      ApiConstants.resetPassword,
      body: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
      includeAuth: false,
    );
  }

  /// Sign out user (clear local storage)
  Future<void> signOut() async {
    await _storageService.clearAll();
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _storageService.isAuthenticated();
  }

  /// Get stored user type
  String? getUserType() {
    return _storageService.getUserType();
  }

  /// Check if user is customer
  bool isCustomer() {
    return _storageService.isCustomer();
  }

  /// Check if user is seller
  bool isSeller() {
    return _storageService.isSeller();
  }
}
