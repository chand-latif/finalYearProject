import '../../data/models/service_model.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/service_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for service operations.
/// Used by sellers for service management and customers for browsing.
class ServiceViewModel extends BaseViewModel {
  final ServiceRepository _serviceRepository;

  List<ServiceModel> _services = [];
  ServiceModel? _selectedService;
  List<ReviewModel> _reviews = [];

  ServiceViewModel({required ServiceRepository serviceRepository})
      : _serviceRepository = serviceRepository;

  /// All services
  List<ServiceModel> get services => _services;

  /// Currently selected service
  ServiceModel? get selectedService => _selectedService;

  /// Reviews for selected service
  List<ReviewModel> get reviews => _reviews;

  /// Published services only
  List<ServiceModel> get publishedServices =>
      _services.where((s) => s.isPublished).toList();

  /// Draft services only
  List<ServiceModel> get draftServices =>
      _services.where((s) => !s.isPublished).toList();

  /// Load services for a company (all including drafts - for seller)
  Future<void> loadCompanyServices(int companyId) async {
    try {
      setLoading();
      _services = await _serviceRepository.getAllCompanyServices(companyId);
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Load published services for a company (for customers)
  Future<void> loadPublishedServices(int companyId) async {
    try {
      setLoading();
      _services = await _serviceRepository.getPublishedServices(companyId);
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Load services by category
  Future<void> loadServicesByCategory(int categoryId) async {
    try {
      setLoading();
      _services = await _serviceRepository.getServicesByCategory(categoryId);
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Select a service
  void selectService(ServiceModel service) {
    _selectedService = service;
    notifyListeners();
  }

  /// Load reviews for selected service
  Future<void> loadReviews(int serviceId) async {
    try {
      _reviews = await _serviceRepository.getServiceReviews(serviceId);
      notifyListeners();
    } catch (e) {
      // Silent fail for reviews
      _reviews = [];
      notifyListeners();
    }
  }

  /// Create a new service
  Future<bool> createService({
    required int companyId,
    required String serviceName,
    required String serviceDescription,
    required double price,
    required int categoryId,
    bool isPublished = true,
    String? imagePath,
  }) async {
    try {
      setLoading();
      final service = await _serviceRepository.createService(
        companyId: companyId,
        serviceName: serviceName,
        serviceDescription: serviceDescription,
        price: price,
        categoryId: categoryId,
        isPublished: isPublished,
      );

      // Upload image if provided
      if (imagePath != null) {
        await _serviceRepository.uploadServiceImage(
          serviceId: service.serviceId,
          imagePath: imagePath,
        );
      }

      // Refresh services list
      await loadCompanyServices(companyId);
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Update an existing service
  Future<bool> updateService({
    required int serviceId,
    required int companyId,
    String? serviceName,
    String? serviceDescription,
    double? price,
    int? categoryId,
    bool? isPublished,
    String? imagePath,
  }) async {
    try {
      setLoading();
      await _serviceRepository.updateService(
        serviceId: serviceId,
        serviceName: serviceName,
        serviceDescription: serviceDescription,
        price: price,
        categoryId: categoryId,
        isPublished: isPublished,
      );

      // Upload new image if provided
      if (imagePath != null) {
        await _serviceRepository.uploadServiceImage(
          serviceId: serviceId,
          imagePath: imagePath,
        );
      }

      // Refresh services list
      await loadCompanyServices(companyId);
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Delete a service
  Future<bool> deleteService(int serviceId, int companyId) async {
    try {
      setLoading();
      await _serviceRepository.deleteService(serviceId);
      await loadCompanyServices(companyId);
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Create a review for a service
  Future<bool> createReview({
    required int serviceId,
    required int bookingId,
    required double rating,
    String? comment,
  }) async {
    try {
      setLoading();
      await _serviceRepository.createReview(
        serviceId: serviceId,
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );
      // Refresh reviews
      await loadReviews(serviceId);
      setSuccess();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Clear selected service
  void clearSelectedService() {
    _selectedService = null;
    _reviews = [];
    notifyListeners();
  }

  /// Clear services list
  void clearServices() {
    _services = [];
    notifyListeners();
  }
}
