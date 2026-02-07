class HiddenCouponResponse {
  final bool? success;
  final CouponData? data;

  HiddenCouponResponse({
    this.success,
    this.data,
  });

  factory HiddenCouponResponse.fromJson(Map<String, dynamic> json) {
    return HiddenCouponResponse(
      success: json['success'] as bool?,
      data: json['data'] != null
          ? CouponData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
    };
  }
}

class CouponData {
  final String? id;
  final String? codeName;
  final int? codePercentage;
  final int? maximumDiscountAmount;
  final String? codeDescription;
  final bool? couponIsActive;

  CouponData({
    this.id,
    this.codeName,
    this.codePercentage,
    this.maximumDiscountAmount,
    this.codeDescription,
    this.couponIsActive,
  });

  factory CouponData.fromJson(Map<String, dynamic> json) {
    return CouponData(
      id: json['_id'] as String?,
      codeName: json['codeName'] as String?,
      codePercentage: json['codePercentage'] as int?,
      maximumDiscountAmount: json['maximumDiscountAmount'] as int?,
      codeDescription: json['codeDescription'] as String?,
      couponIsActive: json['couponIsActive'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'codeName': codeName,
      'codePercentage': codePercentage,
      'maximumDiscountAmount': maximumDiscountAmount,
      'codeDescription': codeDescription,
      'couponIsActive': couponIsActive,
    };
  }
}
