class OtpResponse {
  final String? accessToken;
  final String? refreshToken;
  final bool? auth;
  final String? description;

  OtpResponse({
    this.accessToken,
    this.refreshToken,
    this.auth,
    this.description,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      auth: json['auth'] as bool?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'auth': auth,
      'description': description,
    };
  }
}
