class SdProvisionResponse {
  final bool? success;
  final String? message;
  final int? statusCode;
  final ReservationResult? result;

  SdProvisionResponse({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory SdProvisionResponse.fromJson(Map<String, dynamic> json) {
    return SdProvisionResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: json['result'] != null
          ? ReservationResult.fromJson(json['result'] as Map<String, dynamic>)
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

class ReservationResult {
  final String? reservationId;
  final String? orderReferenceNumber;
  final bool? reservationCreated;
  final bool? receiptCreated;
  final OrderData? orderData;

  ReservationResult({
    this.reservationId,
    this.orderReferenceNumber,
    this.reservationCreated,
    this.receiptCreated,
    this.orderData,
  });

  factory ReservationResult.fromJson(Map<String, dynamic> json) {
    return ReservationResult(
      reservationId: json['reservation_id'] as String?,
      orderReferenceNumber: json['order_reference_number'] as String?,
      reservationCreated: json['reservationCreated'] as bool?,
      receiptCreated: json['receiptCreated'] as bool?,
      orderData: json['orderData'] != null
          ? OrderData.fromJson(json['orderData'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservation_id': reservationId,
      'order_reference_number': orderReferenceNumber,
      'reservationCreated': reservationCreated,
      'receiptCreated': receiptCreated,
      'orderData': orderData?.toJson(),
    };
  }
}

class OrderData {
  final bool? success;
  final String? message;
  final int? statusCode;
  final PaymentResult? result;

  OrderData({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: json['result'] != null
          ? PaymentResult.fromJson(json['result'] as Map<String, dynamic>)
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

class PaymentResult {
  final String? paymentIntentID;
  final String? clientSecret;

  PaymentResult({
    this.paymentIntentID,
    this.clientSecret,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      paymentIntentID: json['paymentIntentID'] as String?,
      clientSecret: json['clientSecret'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentIntentID': paymentIntentID,
      'clientSecret': clientSecret,
    };
  }
}
