class VersionCheckResponse {
  final bool? isCompatible;
  final String? message;

  VersionCheckResponse({
    this.isCompatible,
    this.message,
  });

  factory VersionCheckResponse.fromJson(Map<String, dynamic> json) {
    return VersionCheckResponse(
      isCompatible: json['isCompatible'] as bool?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCompatible': isCompatible,
      'message': message,
    };
  }
}

// fcm response
class UpdateFcmTokenResponse {
  final bool? success;
  final String? message;

  UpdateFcmTokenResponse({
    this.success,
    this.message,
  });

  factory UpdateFcmTokenResponse.fromJson(Map<String, dynamic> json) {
    return UpdateFcmTokenResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}
