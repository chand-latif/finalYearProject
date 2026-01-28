/// API configuration constants for the FixEasy app.
/// Centralized location for all endpoint URLs.

class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();

  /// Base URL for all API requests
  static const String baseUrl = 'https://fixease.pk/api';

  // ==================== Auth Endpoints ====================
  static const String signIn = '/User/SignIn';
  static const String signUp = '/User/SignUp';
  static const String getUserInfo = '/User/GetUserInformation';
  static const String resendOtp = '/User/ResendVerificationOTP';
  static const String verifyOtp = '/User/VerifyOTP';
  static const String forgotPassword = '/User/ForgetPassword';
  static const String resetPassword = '/User/ResetPassword';

  // ==================== Company Endpoints ====================
  static const String companyProfile = '/CompanyProfile';
  static const String listAllCompanies = '/CompanyProfile/ListOfAllCompanyProfile';
  static const String getCompanyProfile = '/CompanyProfile/ListCompanyProfile';
  static const String createCompanyProfile = '/CompanyProfile/CreateCompanyProfile';
  static const String updateCompanyProfile = '/CompanyProfile/UpdateCompanyProfile';

  // ==================== Service Endpoints ====================
  static const String companyServices = '/CompanyServices';
  static const String publishedServices = '/CompanyServices/getListOfPublishedCompanyServices';
  static const String allServices = '/CompanyServices/GetListOfAllCompanyServices';
  static const String createService = '/CompanyServices/CreateCompanyService';
  static const String updateService = '/CompanyServices/UpdateCompanyService';
  static const String deleteService = '/CompanyServices/DeleteCompanyService';
  static const String servicesByCategory = '/CompanyServices/GetCompanyServicesByCategoryId';

  // ==================== Booking Endpoints ====================
  static const String bookings = '/BookingService';
  static const String createBooking = '/BookingService/CreateBooking';
  static const String getAllBookings = '/BookingService/GetAllBookings';
  static const String getBookingDetails = '/BookingService/GetBookingDetails';
  static const String setBookingStatus = '/BookingService/SetBookingStatus';
  static const String providerStats = '/BookingService/getServiceProviderStats';
  static const String updateBooking = '/BookingService/UpdateBooking';
  static const String deleteBooking = '/BookingService/DeleteBooking';

  // ==================== Review Endpoints ====================
  static const String reviews = '/Reviews';
  static const String createReview = '/Reviews/CreateReview';
  static const String getServiceReviews = '/Reviews/GetServiceReviews';

  // ==================== Category Endpoints ====================
  static const String categories = '/Categories';
  static const String allCategories = '/Categories/GetAllCategories';
}
