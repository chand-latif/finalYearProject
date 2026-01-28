import '../../data/models/company_model.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/company_repository.dart';
import '../../data/repositories/service_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for the customer home screen.
/// Manages featured companies, categories, and service browsing.
class CustomerHomeViewModel extends BaseViewModel {
  final CompanyRepository _companyRepository;
  final ServiceRepository _serviceRepository;

  List<CompanyModel> _featuredCompanies = [];
  List<CompanyModel> _allCompanies = [];
  List<ServiceModel> _categoryServices = [];
  bool _isLoadingCompanies = false;
  bool _isLoadingServices = false;

  CustomerHomeViewModel({
    required CompanyRepository companyRepository,
    required ServiceRepository serviceRepository,
  })  : _companyRepository = companyRepository,
        _serviceRepository = serviceRepository;

  /// Featured companies for the home screen
  List<CompanyModel> get featuredCompanies => _featuredCompanies;

  /// All companies
  List<CompanyModel> get allCompanies => _allCompanies;

  /// Services for selected category
  List<ServiceModel> get categoryServices => _categoryServices;

  /// Whether companies are loading
  bool get isLoadingCompanies => _isLoadingCompanies;

  /// Whether services are loading
  bool get isLoadingServices => _isLoadingServices;

  /// Service categories with icons
  List<Map<String, dynamic>> get serviceCategories => const [
        {'name': 'Carpenter', 'id': 14, 'icon': 'carpenter', 'color': 0xFFFF9800},
        {'name': 'Painter', 'id': 10, 'icon': 'format_paint', 'color': 0xFF2196F3},
        {'name': 'Plumber', 'id': 9, 'icon': 'plumbing', 'color': 0xFF03A9F4},
        {'name': 'Electrician', 'id': 11, 'icon': 'electrical_services', 'color': 0xFFFFC107},
        {'name': 'AC Repair', 'id': 12, 'icon': 'ac_unit', 'color': 0xFF009688},
        {'name': 'Cleaner', 'id': 13, 'icon': 'cleaning_services', 'color': 0xFF9C27B0},
      ];

  /// Load featured companies
  Future<void> loadFeaturedCompanies() async {
    try {
      _isLoadingCompanies = true;
      notifyListeners();

      // Get all companies
      final companies = await _companyRepository.getAllCompanies();

      // For each company, get their services to calculate ratings
      for (int i = 0; i < companies.length; i++) {
        try {
          final services = await _serviceRepository.getPublishedServices(
            companies[i].companyId,
          );

          int totalRatings = 0;
          double totalRatingSum = 0;

          for (var service in services) {
            if (service.rating != null) {
              totalRatings += service.rating!.totalRatings;
              totalRatingSum += service.rating!.averageRating * 
                  service.rating!.totalRatings;
            }
          }

          companies[i] = companies[i].copyWith(
            totalRatings: totalRatings,
            averageRating: totalRatings > 0 ? totalRatingSum / totalRatings : 0.0,
            servicesCount: services.length,
          );
        } catch (e) {
          // Continue if we can't get services for a company
        }
      }

      // Sort by total ratings and take top 3
      companies.sort((a, b) => b.totalRatings.compareTo(a.totalRatings));
      _featuredCompanies = companies.take(3).toList();
      _allCompanies = companies;

      _isLoadingCompanies = false;
      notifyListeners();
    } catch (e) {
      _isLoadingCompanies = false;
      setError(e.toString());
    }
  }

  /// Load all companies
  Future<void> loadAllCompanies() async {
    try {
      _isLoadingCompanies = true;
      notifyListeners();

      _allCompanies = await _companyRepository.getAllCompanies();

      _isLoadingCompanies = false;
      notifyListeners();
    } catch (e) {
      _isLoadingCompanies = false;
      setError(e.toString());
    }
  }

  /// Load services by category
  Future<void> loadServicesByCategory(int categoryId) async {
    try {
      _isLoadingServices = true;
      notifyListeners();

      _categoryServices = await _serviceRepository.getServicesByCategory(categoryId);

      _isLoadingServices = false;
      notifyListeners();
    } catch (e) {
      _isLoadingServices = false;
      setError(e.toString());
    }
  }

  /// Get company by ID
  Future<CompanyModel?> getCompany(int companyId) async {
    try {
      return await _companyRepository.getCompanyProfile(companyId);
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }

  /// Get services for a company
  Future<List<ServiceModel>> getCompanyServices(int companyId) async {
    try {
      return await _serviceRepository.getPublishedServices(companyId);
    } catch (e) {
      setError(e.toString());
      return [];
    }
  }

  /// Clear category services
  void clearCategoryServices() {
    _categoryServices = [];
    notifyListeners();
  }
}
