import '../../data/models/booking_model.dart';
import '../../data/models/company_model.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/company_repository.dart';
import '../../data/repositories/service_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for the seller/service provider home screen.
/// Manages booking stats, recent bookings, and company profile.
class SellerHomeViewModel extends BaseViewModel {
  final BookingRepository _bookingRepository;
  final CompanyRepository _companyRepository;
  final ServiceRepository _serviceRepository;

  BookingStats? _bookingStats;
  CompanyModel? _company;
  List<BookingModel> _recentBookings = [];
  List<ServiceModel> _myServices = [];
  double _averageRating = 0.0;
  int _totalRatings = 0;

  bool _isLoadingStats = false;
  bool _isLoadingCompany = false;
  bool _isLoadingBookings = false;

  SellerHomeViewModel({
    required BookingRepository bookingRepository,
    required CompanyRepository companyRepository,
    required ServiceRepository serviceRepository,
  })  : _bookingRepository = bookingRepository,
        _companyRepository = companyRepository,
        _serviceRepository = serviceRepository;

  /// Booking statistics
  BookingStats? get bookingStats => _bookingStats;

  /// Current company profile
  CompanyModel? get company => _company;

  /// Recent bookings
  List<BookingModel> get recentBookings => _recentBookings;

  /// My services
  List<ServiceModel> get myServices => _myServices;

  /// Average rating across all services
  double get averageRating => _averageRating;

  /// Total number of ratings
  int get totalRatings => _totalRatings;

  /// Company name
  String? get companyName => _company?.companyName;

  /// Company logo URL
  String get companyLogoUrl => _company?.logoUrl ?? '';

  /// Loading states
  bool get isLoadingStats => _isLoadingStats;
  bool get isLoadingCompany => _isLoadingCompany;
  bool get isLoadingBookings => _isLoadingBookings;

  /// Load all dashboard data
  Future<void> loadDashboard(int companyId) async {
    await Future.wait([
      loadBookingStats(),
      loadCompanyProfile(companyId),
      loadRecentBookings(),
      loadServicesForRating(companyId),
    ]);
  }

  /// Load booking statistics
  Future<void> loadBookingStats() async {
    try {
      _isLoadingStats = true;
      notifyListeners();

      _bookingStats = await _bookingRepository.getBookingStats();

      _isLoadingStats = false;
      notifyListeners();
    } catch (e) {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Load company profile
  Future<void> loadCompanyProfile(int companyId) async {
    try {
      _isLoadingCompany = true;
      notifyListeners();

      _company = await _companyRepository.getCompanyProfile(companyId);

      _isLoadingCompany = false;
      notifyListeners();
    } catch (e) {
      _isLoadingCompany = false;
      notifyListeners();
    }
  }

  /// Load recent bookings
  Future<void> loadRecentBookings() async {
    try {
      _isLoadingBookings = true;
      notifyListeners();

      _recentBookings = await _bookingRepository.getRecentBookings(limit: 3);

      _isLoadingBookings = false;
      notifyListeners();
    } catch (e) {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }

  /// Load services for rating calculation
  Future<void> loadServicesForRating(int companyId) async {
    try {
      _myServices = await _serviceRepository.getPublishedServices(companyId);

      int totalRatings = 0;
      double totalRatingSum = 0;

      for (var service in _myServices) {
        if (service.rating != null) {
          totalRatings += service.rating!.totalRatings;
          totalRatingSum += service.rating!.averageRating * 
              service.rating!.totalRatings;
        }
      }

      _totalRatings = totalRatings;
      _averageRating = totalRatings > 0 ? totalRatingSum / totalRatings : 0.0;

      notifyListeners();
    } catch (e) {
      // Silent fail for rating calculation
    }
  }

  /// Update booking status
  Future<bool> updateBookingStatus(int bookingId, String status) async {
    try {
      await _bookingRepository.updateBookingStatus(
        bookingId: bookingId,
        status: status,
      );
      // Refresh data
      await loadBookingStats();
      await loadRecentBookings();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Accept a booking
  Future<bool> acceptBooking(int bookingId) async {
    return updateBookingStatus(bookingId, 'Accepted');
  }

  /// Reject a booking
  Future<bool> rejectBooking(int bookingId) async {
    return updateBookingStatus(bookingId, 'Rejected');
  }

  /// Start work on a booking
  Future<bool> startBooking(int bookingId) async {
    return updateBookingStatus(bookingId, 'InProgress');
  }

  /// Complete a booking
  Future<bool> completeBooking(int bookingId) async {
    return updateBookingStatus(bookingId, 'Completed');
  }

  /// Refresh all data
  Future<void> refresh(int companyId) async {
    await loadDashboard(companyId);
  }
}
