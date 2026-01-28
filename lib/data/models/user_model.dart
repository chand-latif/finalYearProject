/// User model representing authenticated user data.
class UserModel {
  final int userId;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String userType; // 'Customer' or 'Seller'
  final bool isEmailVerified;
  final bool isCompanyProfileExist;
  final int? companyId;
  final String? profileImage;

  UserModel({
    required this.userId,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.userType,
    this.isEmailVerified = false,
    this.isCompanyProfileExist = false,
    this.companyId,
    this.profileImage,
  });

  /// Full name combining first and last name
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    return '$first $last'.trim();
  }

  /// Check if user is a customer
  bool get isCustomer => userType == 'Customer';

  /// Check if user is a seller
  bool get isSeller => userType == 'Seller';

  /// Create UserModel from API JSON response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      userType: json['userType'] ?? 'Customer',
      isEmailVerified: json['isEmailVerified'] ?? false,
      isCompanyProfileExist: json['isCompanyProfileExist'] ?? false,
      companyId: json['companyId'],
      profileImage: json['profileImage'],
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'isEmailVerified': isEmailVerified,
      'isCompanyProfileExist': isCompanyProfileExist,
      'companyId': companyId,
      'profileImage': profileImage,
    };
  }

  /// Create a copy with modified fields
  UserModel copyWith({
    int? userId,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? userType,
    bool? isEmailVerified,
    bool? isCompanyProfileExist,
    int? companyId,
    String? profileImage,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isCompanyProfileExist: isCompanyProfileExist ?? this.isCompanyProfileExist,
      companyId: companyId ?? this.companyId,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

/// Authentication response containing token and user info
class AuthResponse {
  final String accessToken;
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final tokenData = json['jwtAccessToken'];
    return AuthResponse(
      accessToken: tokenData?['access_Token'] ?? '',
      user: UserModel.fromJson(json),
    );
  }
}
