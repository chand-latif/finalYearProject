/// Company model representing a service provider's company profile.
class CompanyModel {
  final int companyId;
  final int userId;
  final String companyName;
  final String? companyDescription;
  final String? companyLogo;
  final String? companyAddress;
  final String? companyPhone;
  final String? companyEmail;
  final double? latitude;
  final double? longitude;
  final int? servicesCount;
  final double averageRating;
  final int totalRatings;
  final DateTime? createdAt;

  CompanyModel({
    required this.companyId,
    required this.userId,
    required this.companyName,
    this.companyDescription,
    this.companyLogo,
    this.companyAddress,
    this.companyPhone,
    this.companyEmail,
    this.latitude,
    this.longitude,
    this.servicesCount,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.createdAt,
  });

  /// Get full logo URL
  String get logoUrl {
    if (companyLogo == null || companyLogo!.isEmpty) return '';
    if (companyLogo!.startsWith('http')) return companyLogo!;
    return 'https://fixease.pk$companyLogo';
  }

  /// Formatted rating string
  String get formattedRating => averageRating.toStringAsFixed(1);

  /// Create CompanyModel from API JSON response
  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      companyId: json['companyId'] ?? 0,
      userId: json['userId'] ?? 0,
      companyName: json['companyName'] ?? '',
      companyDescription: json['companyDescription'],
      companyLogo: json['companyLogo'],
      companyAddress: json['companyAddress'],
      companyPhone: json['companyPhone'],
      companyEmail: json['companyEmail'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      servicesCount: json['servicesCount'],
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
    );
  }

  /// Convert CompanyModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'userId': userId,
      'companyName': companyName,
      'companyDescription': companyDescription,
      'companyLogo': companyLogo,
      'companyAddress': companyAddress,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'latitude': latitude,
      'longitude': longitude,
      'servicesCount': servicesCount,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
    };
  }

  /// Create a copy with modified fields
  CompanyModel copyWith({
    int? companyId,
    int? userId,
    String? companyName,
    String? companyDescription,
    String? companyLogo,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    double? latitude,
    double? longitude,
    int? servicesCount,
    double? averageRating,
    int? totalRatings,
    DateTime? createdAt,
  }) {
    return CompanyModel(
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      companyDescription: companyDescription ?? this.companyDescription,
      companyLogo: companyLogo ?? this.companyLogo,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      servicesCount: servicesCount ?? this.servicesCount,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
