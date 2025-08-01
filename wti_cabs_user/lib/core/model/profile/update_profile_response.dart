class UpdateProfileResponse {
  final bool? userUpdated;
  final String? result;

  UpdateProfileResponse({
    this.userUpdated,
    this.result,
  });

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      userUpdated: json['userUpdated'] as bool?,
      result: json['result'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userUpdated': userUpdated,
      'result': result,
    };
  }
}
