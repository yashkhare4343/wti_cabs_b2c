class MobileResponse {
  final bool? userAssociated;
  final bool? otpUpdated;
  final bool? isWhatsappOtpSent;
  final bool? mailSent;
  final String? result;

  MobileResponse({
    this.userAssociated,
    this.otpUpdated,
    this.isWhatsappOtpSent,
    this.mailSent,
    this.result,
  });

  factory MobileResponse.fromJson(Map<String, dynamic> json) {
    return MobileResponse(
      userAssociated: json['userAssociated'] as bool?,
      otpUpdated: json['otpUpdated'] as bool?,
      isWhatsappOtpSent: json['isWhatsappOtpSent'] as bool?,
      mailSent: json['mailSent'] as bool?,
      result: json['result'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userAssociated': userAssociated,
      'otpUpdated': otpUpdated,
      'isWhatsappOtpSent': isWhatsappOtpSent,
      'mailSent': mailSent,
      'result': result,
    };
  }
}
