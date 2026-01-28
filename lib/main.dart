import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/services/storage_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/company_repository.dart';
import 'data/repositories/service_repository.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/booking_viewmodel.dart';
import 'presentation/viewmodels/customer_home_viewmodel.dart';
import 'presentation/viewmodels/seller_home_viewmodel.dart';
import 'presentation/viewmodels/service_viewmodel.dart';
import 'app.dart';

/// Custom HTTP overrides for development (allows self-signed certificates)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  // Allow bad certificates in development
  HttpOverrides.global = MyHttpOverrides();
  
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();

  // Create API client
  final apiClient = ApiClient(storageService: storageService);

  // Create repositories
  final authRepository = AuthRepository(
    apiClient: apiClient,
    storageService: storageService,
  );
  final companyRepository = CompanyRepository(apiClient: apiClient);
  final serviceRepository = ServiceRepository(apiClient: apiClient);
  final bookingRepository = BookingRepository(apiClient: apiClient);

  // Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        // ViewModels
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomerHomeViewModel(
            companyRepository: companyRepository,
            serviceRepository: serviceRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SellerHomeViewModel(
            bookingRepository: bookingRepository,
            companyRepository: companyRepository,
            serviceRepository: serviceRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingViewModel(bookingRepository: bookingRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceViewModel(serviceRepository: serviceRepository),
        ),
      ],
      child: const FixEasyApp(),
    ),
  );
}
