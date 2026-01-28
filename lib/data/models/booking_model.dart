/// Booking model representing a service booking.
class BookingModel {
  final int bookingId;
  final int serviceId;
  final int customerId;
  final int companyId;
  final String status;
  final DateTime bookingDate;
  final String? bookingTime;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? description;
  final double? totalPrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Related data (when fetched with booking)
  final String? serviceName;
  final String? serviceImage;
  final String? companyName;
  final String? companyLogo;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;

  BookingModel({
    required this.bookingId,
    required this.serviceId,
    required this.customerId,
    required this.companyId,
    required this.status,
    required this.bookingDate,
    this.bookingTime,
    this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.totalPrice,
    this.createdAt,
    this.updatedAt,
    this.serviceName,
    this.serviceImage,
    this.companyName,
    this.companyLogo,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
  });

  /// Get full service image URL
  String get serviceImageUrl {
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

  /// Check if booking is pending
  bool get isPending => status.toLowerCase() == 'pending';

  /// Check if booking is accepted
  bool get isAccepted => status.toLowerCase() == 'accepted';

  /// Check if booking is in progress
  bool get isInProgress => status.toLowerCase() == 'inprogress';

  /// Check if booking is completed
  bool get isCompleted => 
      status.toLowerCase() == 'completed' || 
      status.toLowerCase() == 'finished';

  /// Check if booking is cancelled
  bool get isCancelled => 
      status.toLowerCase() == 'cancelled' || 
      status.toLowerCase() == 'rejected';

  /// Create BookingModel from API JSON response
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'] ?? json['bookingServiceId'] ?? 0,
      serviceId: json['serviceId'] ?? json['companyServiceId'] ?? 0,
      customerId: json['customerId'] ?? json['userId'] ?? 0,
      companyId: json['companyId'] ?? 0,
      status: json['status'] ?? json['bookingStatus'] ?? 'Pending',
      bookingDate: json['bookingDate'] != null 
          ? DateTime.parse(json['bookingDate']) 
          : DateTime.now(),
      bookingTime: json['bookingTime'],
      address: json['address'] ?? json['bookingAddress'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] ?? json['bookingDescription'],
      totalPrice: (json['totalPrice'] ?? json['price'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
      serviceName: json['serviceName'] ?? json['companyServiceName'],
      serviceImage: json['serviceImage'] ?? json['companyServiceImage'],
      companyName: json['companyName'],
      companyLogo: json['companyLogo'],
      customerName: json['customerName'] ?? json['userName'],
      customerEmail: json['customerEmail'] ?? json['userEmail'],
      customerPhone: json['customerPhone'] ?? json['userPhone'],
    );
  }

  /// Convert BookingModel to JSON for creating/updating booking
  Map<String, dynamic> toJson() {
    return {
      'companyServiceId': serviceId,
      'bookingDate': bookingDate.toIso8601String().split('T')[0],
      'bookingTime': bookingTime,
      'bookingAddress': address,
      'latitude': latitude,
      'longitude': longitude,
      'bookingDescription': description,
    };
  }

  /// Create a copy with modified fields
  BookingModel copyWith({
    int? bookingId,
    int? serviceId,
    int? customerId,
    int? companyId,
    String? status,
    DateTime? bookingDate,
    String? bookingTime,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serviceName,
    String? serviceImage,
    String? companyName,
    String? companyLogo,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      serviceId: serviceId ?? this.serviceId,
      customerId: customerId ?? this.customerId,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceName: serviceName ?? this.serviceName,
      serviceImage: serviceImage ?? this.serviceImage,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }
}

/// Booking stats for seller dashboard
class BookingStats {
  final int pending;
  final int accepted;
  final int inProgress;
  final int completed;

  BookingStats({
    this.pending = 0,
    this.accepted = 0,
    this.inProgress = 0,
    this.completed = 0,
  });

  factory BookingStats.fromJson(Map<String, dynamic> json) {
    return BookingStats(
      pending: json['pending'] ?? 0,
      accepted: json['accepted'] ?? 0,
      inProgress: json['inProgress'] ?? 0,
      completed: json['finished'] ?? json['completed'] ?? 0,
    );
  }
}
