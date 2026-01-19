class VersionCheckResponse {
  final bool? isCompatible;
  final String? message;

  VersionCheckResponse({
    this.isCompatible,
    this.message,
  });

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes' || v == 'y') return true;
      if (v == 'false' || v == '0' || v == 'no' || v == 'n') return false;
    }
    return null;
  }

  factory VersionCheckResponse.fromJson(Map<String, dynamic> json) {
    return VersionCheckResponse(
      isCompatible: _parseBool(json['isCompatible']),
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
