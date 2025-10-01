class SelfDriveUserResponse {
  final bool? success;
  final String? message;
  final int? statusCode;
  final UserResult? result;

  SelfDriveUserResponse({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory SelfDriveUserResponse.fromJson(Map<String, dynamic> json) {
    return SelfDriveUserResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: json['result'] != null
          ? UserResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'statusCode': statusCode,
      'result': result?.toJson(),
    };
  }
}

class UserResult {
  final bool? userCreated;
  final bool? userExist;
  final String? userObjId;
  final String? country;

  UserResult({
    this.userCreated,
    this.userExist,
    this.userObjId,
    this.country,
  });

  factory UserResult.fromJson(Map<String, dynamic> json) {
    return UserResult(
      userCreated: json['userCreated'] as bool?,
      userExist: json['userExist'] as bool?,
      userObjId: json['user_obj_id'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCreated': userCreated,
      'userExist': userExist,
      'user_obj_id': userObjId,
      'country': country,
    };
  }
}
