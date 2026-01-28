/// Service model representing a company's service offering.
class ServiceModel {
  final int serviceId;
  final int companyId;
  final String serviceName;
  final String? serviceDescription;
  final double price;
  final String? serviceImage;
  final int categoryId;
  final String? categoryName;
  final bool isPublished;
  final ServiceRating? rating;
  final DateTime? createdAt;

  // Company info (when fetched with service)
  final String? companyName;
  final String? companyLogo;

  ServiceModel({
    required this.serviceId,
    required this.companyId,
    required this.serviceName,
    this.serviceDescription,
    required this.price,
    this.serviceImage,
    required this.categoryId,
    this.categoryName,
    this.isPublished = true,
    this.rating,
    this.createdAt,
    this.companyName,
    this.companyLogo,
  });

  /// Get full image URL
  String get imageUrl {
    if (serviceImage == null || serviceImage!.isEmpty) return '';
    if (serviceImage!.startsWith('http')) return serviceImage!;
    return 'https://fixease.pk$serviceImage';
  }

  /// Get full company logo URL
  String get companyLogoUrl {
    if (companyLogo == null || companyLogo!.isEmpty) return '';
    if (companyLogo!.startsWith('http')) return companyLogo!;
    return 'https://fixease.pk$companyLogo';
  }

  /// Formatted price string
  String get formattedPrice => 'Rs. ${price.toStringAsFixed(0)}';

  /// Create ServiceModel from API JSON response
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['serviceId'] ?? json['companyServiceId'] ?? 0,
      companyId: json['companyId'] ?? 0,
      serviceName: json['serviceName'] ?? json['companyServiceName'] ?? '',
      serviceDescription: json['serviceDescription'] ?? json['companyServiceDescription'],
      price: (json['price'] ?? json['companyServicePrice'] ?? 0).toDouble(),
      serviceImage: json['serviceImage'] ?? json['companyServiceImage'],
      categoryId: json['categoryId'] ?? json['serviceCategoryId'] ?? 0,
      categoryName: json['categoryName'] ?? json['serviceCategoryName'],
      isPublished: json['isPublished'] ?? json['companyServiceStatus'] == 'Published',
      rating: json['serviceRating'] != null 
          ? ServiceRating.fromJson(json['serviceRating']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      companyName: json['companyName'],
      companyLogo: json['companyLogo'],
    );
  }

  /// Convert ServiceModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'companyId': companyId,
      'serviceName': serviceName,
      'serviceDescription': serviceDescription,
      'price': price,
      'serviceImage': serviceImage,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isPublished': isPublished,
    };
  }

  /// Create a copy with modified fields
  ServiceModel copyWith({
    int? serviceId,
    int? companyId,
    String? serviceName,
    String? serviceDescription,
    double? price,
    String? serviceImage,
    int? categoryId,
    String? categoryName,
    bool? isPublished,
    ServiceRating? rating,
    DateTime? createdAt,
    String? companyName,
    String? companyLogo,
  }) {
    return ServiceModel(
      serviceId: serviceId ?? this.serviceId,
      companyId: companyId ?? this.companyId,
      serviceName: serviceName ?? this.serviceName,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      price: price ?? this.price,
      serviceImage: serviceImage ?? this.serviceImage,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isPublished: isPublished ?? this.isPublished,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
    );
  }
}

/// Service rating information
class ServiceRating {
  final double averageRating;
  final int totalRatings;

  ServiceRating({
    required this.averageRating,
    required this.totalRatings,
  });

  String get formattedRating => averageRating.toStringAsFixed(1);

  factory ServiceRating.fromJson(Map<String, dynamic> json) {
    return ServiceRating(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageRating': averageRating,
      'totalRatings': totalRatings,
    };
  }
}

/// Service category
class ServiceCategory {
  final int categoryId;
  final String categoryName;
  final String? categoryIcon;

  ServiceCategory({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      categoryId: json['categoryId'] ?? json['serviceCategoryId'] ?? 0,
      categoryName: json['categoryName'] ?? json['serviceCategoryName'] ?? '',
      categoryIcon: json['categoryIcon'],
    );
  }
}
