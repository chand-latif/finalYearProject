import 'package:flutter/foundation.dart';

/// Enum representing the loading state of a ViewModel.
enum ViewState {
  idle,
  loading,
  success,
  error,
}

/// Base ViewModel class that all other ViewModels extend.
/// Provides common functionality like loading state and error handling.
abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  /// Current state of the ViewModel
  ViewState get state => _state;

  /// Whether the ViewModel is currently loading
  bool get isLoading => _state == ViewState.loading;

  /// Whether the ViewModel is in idle state
  bool get isIdle => _state == ViewState.idle;

  /// Whether the ViewModel has succeeded
  bool get isSuccess => _state == ViewState.success;

  /// Whether the ViewModel has an error
  bool get hasError => _state == ViewState.error;

  /// Current error message (if any)
  String? get errorMessage => _errorMessage;

  /// Set the state to loading
  @protected
  void setLoading() {
    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set the state to success
  @protected
  void setSuccess() {
    _state = ViewState.success;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set the state to idle
  @protected
  void setIdle() {
    _state = ViewState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set the state to error with an optional message
  @protected
  void setError([String? message]) {
    _state = ViewState.error;
    _errorMessage = message ?? 'Something went wrong';
    notifyListeners();
  }

  /// Clear any error state
  void clearError() {
    if (_state == ViewState.error) {
      _state = ViewState.idle;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Execute an async operation with automatic loading state management
  @protected
  Future<T?> runAsync<T>(Future<T> Function() operation) async {
    try {
      setLoading();
      final result = await operation();
      setSuccess();
      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }

  /// Execute an async operation without changing state on success
  /// Useful for operations that don't need a success state
  @protected
  Future<T?> runAsyncSilent<T>(Future<T> Function() operation) async {
    try {
      setLoading();
      final result = await operation();
      setIdle();
      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }
}
