import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/service_model.dart';
import '../models/review_model.dart';

/// Repository handling all service-related API calls.
class ServiceRepository {
  final ApiClient _apiClient;

  ServiceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get published services for a company
  Future<List<ServiceModel>> getPublishedServices(int companyId) async {
    final response = await _apiClient.get(
      ApiConstants.publishedServices,
      queryParams: {'CompanyId': companyId},
      includeAuth: false,
    );

    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => ServiceModel.fromJson(json)).toList();
  }

  /// Get all services for a company (including unpublished - for seller)
  Future<List<ServiceModel>> getAllCompanyServices(int companyId) async {
    final response = await _apiClient.get(
      ApiConstants.allServices,
      queryParams: {'CompanyId': companyId},
    );

    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => ServiceModel.fromJson(json)).toList();
  }

  /// Get services by category
  Future<List<ServiceModel>> getServicesByCategory(int categoryId) async {
    final response = await _apiClient.get(
      ApiConstants.servicesByCategory,
      queryParams: {'CategoryId': categoryId},
      includeAuth: false,
    );

    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => ServiceModel.fromJson(json)).toList();
  }

  /// Create a new service
  Future<ServiceModel> createService({
    required int companyId,
    required String serviceName,
    required String serviceDescription,
    required double price,
    required int categoryId,
    bool isPublished = true,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createService,
      body: {
        'companyId': companyId,
        'companyServiceName': serviceName,
        'companyServiceDescription': serviceDescription,
        'companyServicePrice': price,
        'serviceCategoryId': categoryId,
        'companyServiceStatus': isPublished ? 'Published' : 'Draft',
      },
    );

    return ServiceModel.fromJson(response['data']);
  }

  /// Update an existing service
  Future<ServiceModel> updateService({
    required int serviceId,
    String? serviceName,
    String? serviceDescription,
    double? price,
    int? categoryId,
    bool? isPublished,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.updateService,
      body: {
        'companyServiceId': serviceId,
        if (serviceName != null) 'companyServiceName': serviceName,
        if (serviceDescription != null) 'companyServiceDescription': serviceDescription,
        if (price != null) 'companyServicePrice': price,
        if (categoryId != null) 'serviceCategoryId': categoryId,
        if (isPublished != null) 'companyServiceStatus': isPublished ? 'Published' : 'Draft',
      },
    );

    return ServiceModel.fromJson(response['data']);
  }

  /// Delete a service
  Future<void> deleteService(int serviceId) async {
    await _apiClient.delete(
      ApiConstants.deleteService,
      queryParams: {'CompanyServiceId': serviceId},
    );
  }

  /// Upload service image
  Future<void> uploadServiceImage({
    required int serviceId,
    required String imagePath,
  }) async {
    await _apiClient.uploadFile(
      '${ApiConstants.companyServices}/UploadImage',
      filePath: imagePath,
      fieldName: 'file',
      fields: {'companyServiceId': serviceId.toString()},
    );
  }

  /// Get reviews for a service
  Future<List<ReviewModel>> getServiceReviews(int serviceId) async {
    final response = await _apiClient.get(
      ApiConstants.getServiceReviews,
      queryParams: {'CompanyServiceId': serviceId},
      includeAuth: false,
    );

    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => ReviewModel.fromJson(json)).toList();
  }

  /// Create a review for a service
  Future<void> createReview({
    required int serviceId,
    required int bookingId,
    required double rating,
    String? comment,
  }) async {
    await _apiClient.post(
      ApiConstants.createReview,
      body: {
        'companyServiceId': serviceId,
        'bookingServiceId': bookingId,
        'serviceReviewRating': rating,
        'serviceReviewComment': comment,
      },
    );
  }
}
