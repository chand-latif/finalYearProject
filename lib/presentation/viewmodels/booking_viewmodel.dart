import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for booking operations.
/// Used by both customers and sellers for managing bookings.
class BookingViewModel extends BaseViewModel {
  final BookingRepository _bookingRepository;

  List<BookingModel> _bookings = [];
  BookingModel? _selectedBooking;
  BookingStats? _stats;

  BookingViewModel({required BookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  /// All bookings
  List<BookingModel> get bookings => _bookings;

  /// Currently selected booking
  BookingModel? get selectedBooking => _selectedBooking;

  /// Booking stats
  BookingStats? get stats => _stats;

  /// Pending bookings
  List<BookingModel> get pendingBookings =>
      _bookings.where((b) => b.isPending).toList();

  /// Accepted bookings
  List<BookingModel> get acceptedBookings =>
      _bookings.where((b) => b.isAccepted).toList();

  /// In progress bookings
  List<BookingModel> get inProgressBookings =>
      _bookings.where((b) => b.isInProgress).toList();

  /// Completed bookings
  List<BookingModel> get completedBookings =>
      _bookings.where((b) => b.isCompleted).toList();

  /// Cancelled bookings
  List<BookingModel> get cancelledBookings =>
      _bookings.where((b) => b.isCancelled).toList();

  /// Load all bookings
  Future<void> loadBookings() async {
    try {
      setLoading();
      _bookings = await _bookingRepository.getAllBookings();
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Load booking details
  Future<void> loadBookingDetails(int bookingId) async {
    try {
      setLoading();
      _selectedBooking = await _bookingRepository.getBookingDetails(bookingId);
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Create a new booking
  Future<bool> createBooking({
    required int serviceId,
    required DateTime bookingDate,
    required String bookingTime,
    required String address,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    try {
      setLoading();
      final booking = await _bookingRepository.createBooking(
        serviceId: serviceId,
        bookingDate: bookingDate,
        bookingTime: bookingTime,
        address: address,
        latitude: latitude,
        longitude: longitude,
        description: description,
      );
      _selectedBooking = booking;
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Update booking
  Future<bool> updateBooking({
    required int bookingId,
    DateTime? bookingDate,
    String? bookingTime,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    try {
      setLoading();
      await _bookingRepository.updateBooking(
        bookingId: bookingId,
        bookingDate: bookingDate,
        bookingTime: bookingTime,
        address: address,
        latitude: latitude,
        longitude: longitude,
        description: description,
      );
      await loadBookings(); // Refresh list
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Cancel booking (for customer)
  Future<bool> cancelBooking(int bookingId) async {
    try {
      setLoading();
      await _bookingRepository.cancelBooking(bookingId);
      await loadBookings(); // Refresh list
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Accept booking (for seller)
  Future<bool> acceptBooking(int bookingId) async {
    try {
      setLoading();
      await _bookingRepository.acceptBooking(bookingId);
      await loadBookings(); // Refresh list
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Reject booking (for seller)
  Future<bool> rejectBooking(int bookingId) async {
    try {
      setLoading();
      await _bookingRepository.rejectBooking(bookingId);
      await loadBookings(); // Refresh list
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Start work on booking (for seller)
  Future<bool> startBooking(int bookingId) async {
    try {
      setLoading();
      await _bookingRepository.startBooking(bookingId);
      await loadBookings(); // Refresh list
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Complete booking (for seller)
  Future<bool> completeBooking(int bookingId) async {
    try {
      setLoading();
      await _bookingRepository.completeBooking(bookingId);
      await loadBookings(); // Refresh list
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Load booking stats
  Future<void> loadStats() async {
    try {
      _stats = await _bookingRepository.getBookingStats();
      notifyListeners();
    } catch (e) {
      // Silent fail for stats
    }
  }

  /// Clear selected booking
  void clearSelectedBooking() {
    _selectedBooking = null;
    notifyListeners();
  }
}
