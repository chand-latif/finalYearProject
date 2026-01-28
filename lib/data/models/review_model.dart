/// Review model representing a service review from a customer.
class ReviewModel {
  final int reviewId;
  final int serviceId;
  final int userId;
  final int bookingId;
  final double rating;
  final String? comment;
  final DateTime? createdAt;

  // User info (when fetched with review)
  final String? userName;
  final String? userImage;

  ReviewModel({
    required this.reviewId,
    required this.serviceId,
    required this.userId,
    required this.bookingId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.userName,
    this.userImage,
  });

  /// Create ReviewModel from API JSON response
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId'] ?? json['serviceReviewId'] ?? 0,
      serviceId: json['serviceId'] ?? json['companyServiceId'] ?? 0,
      userId: json['userId'] ?? 0,
      bookingId: json['bookingId'] ?? json['bookingServiceId'] ?? 0,
      rating: (json['rating'] ?? json['serviceReviewRating'] ?? 0).toDouble(),
      comment: json['comment'] ?? json['serviceReviewComment'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      userName: json['userName'] ?? json['reviewerName'],
      userImage: json['userImage'] ?? json['reviewerImage'],
    );
  }

  /// Convert ReviewModel to JSON for creating review
  Map<String, dynamic> toJson() {
    return {
      'companyServiceId': serviceId,
      'bookingServiceId': bookingId,
      'serviceReviewRating': rating,
      'serviceReviewComment': comment,
    };
  }

  /// Create a copy with modified fields
  ReviewModel copyWith({
    int? reviewId,
    int? serviceId,
    int? userId,
    int? bookingId,
    double? rating,
    String? comment,
    DateTime? createdAt,
    String? userName,
    String? userImage,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      serviceId: serviceId ?? this.serviceId,
      userId: userId ?? this.userId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
    );
  }
}
