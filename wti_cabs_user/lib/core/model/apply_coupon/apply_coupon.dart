class ApplyCouponResponse {
  final String? message;
  final num? newTotalAmount;
  final num? discountAmount;
  final int? errorCode;

  ApplyCouponResponse({
    this.message,
    this.newTotalAmount,
    this.discountAmount,
    this.errorCode,
  });

  factory ApplyCouponResponse.fromJson(Map<String, dynamic> json) {
    return ApplyCouponResponse(
      message: json['message'] as String?,
      newTotalAmount: json['newTotalAmount'] as num?,
      discountAmount: json['discountAmount'] as num?,
      errorCode: json['errorCode'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'newTotalAmount': newTotalAmount,
      'discountAmount': discountAmount,
      'errorCode': errorCode,
    };
  }
}
