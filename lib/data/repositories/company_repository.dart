import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/company_model.dart';

/// Repository handling all company-related API calls.
class CompanyRepository {
  final ApiClient _apiClient;

  CompanyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get list of all companies
  Future<List<CompanyModel>> getAllCompanies() async {
    final response = await _apiClient.get(
      ApiConstants.listAllCompanies,
      includeAuth: false,
    );

    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => CompanyModel.fromJson(json)).toList();
  }

  /// Get company profile by ID
  Future<CompanyModel> getCompanyProfile(int companyId) async {
    final response = await _apiClient.get(
      ApiConstants.getCompanyProfile,
      queryParams: {'CompanyId': companyId},
      includeAuth: false,
    );

    return CompanyModel.fromJson(response['data']);
  }

  /// Create company profile (for sellers)
  Future<CompanyModel> createCompanyProfile({
    required int userId,
    required String companyName,
    String? companyDescription,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createCompanyProfile,
      body: {
        'userId': userId,
        'companyName': companyName,
        'companyDescription': companyDescription,
        'companyAddress': companyAddress,
        'companyPhone': companyPhone,
        'companyEmail': companyEmail,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return CompanyModel.fromJson(response['data']);
  }

  /// Update company profile
  Future<CompanyModel> updateCompanyProfile({
    required int companyId,
    String? companyName,
    String? companyDescription,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.updateCompanyProfile,
      body: {
        'companyId': companyId,
        'companyName': companyName,
        'companyDescription': companyDescription,
        'companyAddress': companyAddress,
        'companyPhone': companyPhone,
        'companyEmail': companyEmail,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return CompanyModel.fromJson(response['data']);
  }

  /// Upload company logo
  Future<void> uploadCompanyLogo({
    required int companyId,
    required String logoPath,
  }) async {
    await _apiClient.uploadFile(
      '${ApiConstants.companyProfile}/UploadLogo',
      filePath: logoPath,
      fieldName: 'file',
      fields: {'companyId': companyId.toString()},
    );
  }

  /// Get featured companies (sorted by rating)
  Future<List<CompanyModel>> getFeaturedCompanies({int limit = 3}) async {
    final companies = await getAllCompanies();
    
    // Sort by total ratings descending
    companies.sort((a, b) => b.totalRatings.compareTo(a.totalRatings));
    
    return companies.take(limit).toList();
  }
}
