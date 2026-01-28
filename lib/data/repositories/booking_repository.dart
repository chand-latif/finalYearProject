import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/booking_model.dart';

/// Repository handling all booking-related API calls.
class BookingRepository {
  final ApiClient _apiClient;

  BookingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get all bookings for the current user
  Future<List<BookingModel>> getAllBookings() async {
    final response = await _apiClient.get(ApiConstants.getAllBookings);

    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => BookingModel.fromJson(json)).toList();
  }

  /// Get booking details by ID
  Future<BookingModel> getBookingDetails(int bookingId) async {
    final response = await _apiClient.get(
      ApiConstants.getBookingDetails,
      queryParams: {'BookingId': bookingId},
    );

    return BookingModel.fromJson(response['data']);
  }

  /// Create a new booking
  Future<BookingModel> createBooking({
    required int serviceId,
    required DateTime bookingDate,
    required String bookingTime,
    required String address,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createBooking,
      body: {
        'companyServiceId': serviceId,
        'bookingDate': bookingDate.toIso8601String().split('T')[0],
        'bookingTime': bookingTime,
        'bookingAddress': address,
        'latitude': latitude,
        'longitude': longitude,
        'bookingDescription': description,
      },
    );

    return BookingModel.fromJson(response['data']);
  }

  /// Update booking status
  Future<void> updateBookingStatus({
    required int bookingId,
    required String status,
  }) async {
    await _apiClient.put(
      ApiConstants.setBookingStatus,
      queryParams: {
        'BookingId': bookingId,
        'Status': status,
      },
    );
  }

  /// Get booking stats for seller
  Future<BookingStats> getBookingStats() async {
    final response = await _apiClient.get(ApiConstants.providerStats);
    return BookingStats.fromJson(response['data']);
  }

  /// Update booking details
  Future<BookingModel> updateBooking({
    required int bookingId,
    DateTime? bookingDate,
    String? bookingTime,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.updateBooking,
      body: {
        'bookingServiceId': bookingId,
        if (bookingDate != null) 'bookingDate': bookingDate.toIso8601String().split('T')[0],
        if (bookingTime != null) 'bookingTime': bookingTime,
        if (address != null) 'bookingAddress': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (description != null) 'bookingDescription': description,
      },
    );

    return BookingModel.fromJson(response['data']);
  }

  /// Delete/cancel a booking
  Future<void> deleteBooking(int bookingId) async {
    await _apiClient.delete(
      ApiConstants.deleteBooking,
      queryParams: {'BookingId': bookingId},
    );
  }

  /// Get recent bookings (for dashboard)
  Future<List<BookingModel>> getRecentBookings({int limit = 3}) async {
    final bookings = await getAllBookings();
    return bookings.take(limit).toList();
  }

  /// Get bookings by status
  Future<List<BookingModel>> getBookingsByStatus(String status) async {
    final allBookings = await getAllBookings();
    return allBookings
        .where((b) => b.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  /// Accept a booking (for seller)
  Future<void> acceptBooking(int bookingId) async {
    await updateBookingStatus(bookingId: bookingId, status: 'Accepted');
  }

  /// Reject a booking (for seller)
  Future<void> rejectBooking(int bookingId) async {
    await updateBookingStatus(bookingId: bookingId, status: 'Rejected');
  }

  /// Start work on a booking (for seller)
  Future<void> startBooking(int bookingId) async {
    await updateBookingStatus(bookingId: bookingId, status: 'InProgress');
  }

  /// Complete a booking (for seller)
  Future<void> completeBooking(int bookingId) async {
    await updateBookingStatus(bookingId: bookingId, status: 'Completed');
  }

  /// Cancel a booking (for customer)
  Future<void> cancelBooking(int bookingId) async {
    await updateBookingStatus(bookingId: bookingId, status: 'Cancelled');
  }
}
