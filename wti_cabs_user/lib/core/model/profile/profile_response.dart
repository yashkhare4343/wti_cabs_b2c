class ProfileResponse {
  final bool? userExists;
  final AuthResult? result;
  final bool? isTokenValid;

  ProfileResponse({this.userExists, this.result, this.isTokenValid});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      userExists: json['userExists'] as bool?,
      result: json['result'] != null ? AuthResult.fromJson(json['result']) : null,
      isTokenValid: json['isTokenValid'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userExists': userExists,
      'result': result?.toJson(),
      'isTokenValid': isTokenValid,
    };
  }
}

class AuthResult {
  final Otp? otp;
  final String? authType;
  final String? id;
  final String? userID;
  final String? firstName;
  final int? contact;
  final String? contactCode;
  final String? gender;
  final String? countryName;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? emailID;
  final String? password;
  final String? userType;
  final List<dynamic>? couponCodesUsed;
  final List<dynamic>? offersUsed;
  final String? refreshToken;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  AuthResult({
    this.otp,
    this.authType,
    this.id,
    this.userID,
    this.firstName,
    this.contact,
    this.contactCode,
    this.gender,
    this.countryName,
    this.address,
    this.city,
    this.postalCode,
    this.emailID,
    this.password,
    this.userType,
    this.couponCodesUsed,
    this.offersUsed,
    this.refreshToken,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      otp: json['otp'] != null ? Otp.fromJson(json['otp']) : null,
      authType: json['auth_type'] as String?,
      id: json['_id'] as String?,
      userID: json['userID'] as String?,
      firstName: json['firstName'] as String?,
      contact: json['contact'] as int?,
      contactCode: json['contactCode'] as String?,
      gender: json['gender'] as String?,
      countryName: json['countryName'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      postalCode: json['postalCode'] as String?,
      emailID: json['emailID'] as String?,
      password: json['password'] as String?,
      userType: json['userType'] as String?,
      couponCodesUsed: json['couponCodesUsed'] as List<dynamic>?,
      offersUsed: json['offersUsed'] as List<dynamic>?,
      refreshToken: json['refreshToken'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'otp': otp?.toJson(),
      'auth_type': authType,
      '_id': id,
      'userID': userID,
      'firstName': firstName,
      'contact': contact,
      'contactCode': contactCode,
      'gender': gender,
      'countryName': countryName,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'emailID': emailID,
      'password': password,
      'userType': userType,
      'couponCodesUsed': couponCodesUsed,
      'offersUsed': offersUsed,
      'refreshToken': refreshToken,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
    };
  }
}

class Otp {
  final String? code;
  final String? otpExpiry;

  Otp({this.code, this.otpExpiry});

  factory Otp.fromJson(Map<String, dynamic> json) {
    return Otp(
      code: json['code'] as String?,
      otpExpiry: json['otpExpiry'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'otpExpiry': otpExpiry,
    };
  }
}
