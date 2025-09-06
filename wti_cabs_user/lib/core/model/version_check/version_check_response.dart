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
class UpdateFcmToken {
  final bool? isCompatible;
  final String? message;

  UpdateFcmToken({
    this.isCompatible,
    this.message,
  });

  factory UpdateFcmToken.fromJson(Map<String, dynamic> json) {
    return UpdateFcmToken(
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
