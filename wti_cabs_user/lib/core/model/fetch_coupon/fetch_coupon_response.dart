class FetchCouponResponse {
  final int? status;
  final bool? couponCodesFetched;
  final List<CouponData>? data;

  FetchCouponResponse({
    this.status,
    this.couponCodesFetched,
    this.data,
  });

  factory FetchCouponResponse.fromJson(Map<String, dynamic> json) {
    return FetchCouponResponse(
      status: json['status'],
      couponCodesFetched: json['couponCodesFetched'],
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => CouponData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'couponCodesFetched': couponCodesFetched,
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

class CouponData {
  final String? id;
  final String? codeName;
  final num? codePercentage;
  final String? codeDescription;

  CouponData({
    this.id,
    this.codeName,
    this.codePercentage,
    this.codeDescription,
  });

  factory CouponData.fromJson(Map<String, dynamic> json) {
    return CouponData(
      id: json['_id'],
      codeName: json['codeName'],
      codePercentage: json['codePercentage'],
      codeDescription: json['codeDescription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'codeName': codeName,
      'codePercentage': codePercentage,
      'codeDescription': codeDescription,
    };
  }
}
