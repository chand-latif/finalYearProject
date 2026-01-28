import '../../core/exceptions/app_exception.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for authentication-related operations.
/// Manages login, signup, logout, OTP verification, and password reset.
class AuthViewModel extends BaseViewModel {
  final AuthRepository _authRepository;

  UserModel? _currentUser;
  bool _isAuthenticated = false;

  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Current authenticated user
  UserModel? get currentUser => _currentUser;

  /// Whether user is authenticated
  bool get isAuthenticated => _isAuthenticated;

  /// Whether user is a customer
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  /// Whether user is a seller
  bool get isSeller => _currentUser?.isSeller ?? false;

  /// Whether seller has company profile
  bool get hasCompanyProfile => _currentUser?.isCompanyProfileExist ?? false;

  /// Company ID (for sellers)
  int? get companyId => _currentUser?.companyId;

  /// Check authentication status on app start
  Future<void> checkAuthStatus() async {
    try {
      if (_authRepository.isAuthenticated()) {
        setLoading();
        _currentUser = await _authRepository.getUserInfo();
        _isAuthenticated = true;
        setSuccess();
      }
    } catch (e) {
      // Token might be expired, clear it
      await _authRepository.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      setIdle();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      setLoading();
      _currentUser = await _authRepository.signIn(
        email: email,
        password: password,
      );
      _isAuthenticated = true;
      setSuccess();
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      // Return special value for unverified account
      if (e.message == 'Account UnVerified !!') {
        return false; // Caller should handle OTP verification
      }
      return false;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Sign up new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String userType,
  }) async {
    try {
      setLoading();
      await _authRepository.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        userType: userType,
      );
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Resend OTP code
  Future<bool> resendOtp(String email) async {
    try {
      setLoading();
      await _authRepository.resendOtp(email);
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Verify OTP code
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      setLoading();
      await _authRepository.verifyOtp(email: email, otp: otp);
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Request password reset
  Future<bool> forgotPassword(String email) async {
    try {
      setLoading();
      await _authRepository.forgotPassword(email);
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Reset password with OTP
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      setLoading();
      await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      setIdle();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Refresh user information
  Future<void> refreshUser() async {
    try {
      _currentUser = await _authRepository.getUserInfo();
      notifyListeners();
    } catch (e) {
      // Silent fail - don't show error for background refresh
    }
  }
}
