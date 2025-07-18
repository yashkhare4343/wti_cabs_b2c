class PaymentVerificationResponse {
  final String? status;
  final String? message;

  PaymentVerificationResponse({this.status, this.message});

  factory PaymentVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResponse(
      status: json['status'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (status != null) 'status': status,
      if (message != null) 'message': message,
    };
  }
}
