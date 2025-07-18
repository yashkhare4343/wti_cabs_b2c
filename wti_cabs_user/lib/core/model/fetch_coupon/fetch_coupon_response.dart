class FetchCouponResponse {
  final bool? couponCodesFetched;
  final List<CouponData>? data;

  FetchCouponResponse({
    this.couponCodesFetched,
    this.data,
  });

  factory FetchCouponResponse.fromJson(Map<String, dynamic> json) {
    return FetchCouponResponse(
      couponCodesFetched: json['couponCodesFetched'],
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => CouponData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CouponData {
  final String? id;
  final String? countryName;
  final String? userType;
  final String? imageUrl;
  final String? codeName;
  final String? source;
  final String? destination;
  final String? discountType;
  final num? codePercentage;
  final num? maximumDiscountAmount;
  final num? minimumBookingAmount;
  final String? codeDescription;
  final String? startDate;
  final String? endDate;
  final String? validityFrom;
  final String? validityTo;
  final bool? couponIsActive;
  final String? couponBasedDiscount;
  final String? vehicleType;
  final num? tripType;
  final String? couponUsage;
  final String? couponCreatedBy;
  final String? createdAt;
  final String? updatedAt;
  final num? codeNumber;

  CouponData({
    this.id,
    this.countryName,
    this.userType,
    this.imageUrl,
    this.codeName,
    this.source,
    this.destination,
    this.discountType,
    this.codePercentage,
    this.maximumDiscountAmount,
    this.minimumBookingAmount,
    this.codeDescription,
    this.startDate,
    this.endDate,
    this.validityFrom,
    this.validityTo,
    this.couponIsActive,
    this.couponBasedDiscount,
    this.vehicleType,
    this.tripType,
    this.couponUsage,
    this.couponCreatedBy,
    this.createdAt,
    this.updatedAt,
    this.codeNumber,
  });

  factory CouponData.fromJson(Map<String, dynamic> json) {
    return CouponData(
      id: json['_id'],
      countryName: json['countryName'],
      userType: json['userType'],
      imageUrl: json['imageUrl'],
      codeName: json['codeName'],
      source: json['source'],
      destination: json['destination'],
      discountType: json['discountType'],
      codePercentage: json['codePercentage'],
      maximumDiscountAmount: json['maximumDiscountAmount'],
      minimumBookingAmount: json['minimumBookingAmount'],
      codeDescription: json['codeDescription'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      validityFrom: json['validityFrom'],
      validityTo: json['validityTo'],
      couponIsActive: json['couponIsActive'],
      couponBasedDiscount: json['couponBasedDiscount'],
      vehicleType: json['vehicleType'],
      tripType: json['tripType'],
      couponUsage: json['couponUsage'],
      couponCreatedBy: json['couponCreatedBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      codeNumber: json['codeNumber'],
    );
  }
}
