class SelfDriveCancelReservationResponse {
  final bool? success;
  final String? message;
  final int? statusCode;
  final CancelResult? result;

  SelfDriveCancelReservationResponse({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory SelfDriveCancelReservationResponse.fromJson(Map<String, dynamic> json) {
    return SelfDriveCancelReservationResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: json['result'] != null
          ? CancelResult.fromJson(json['result'])
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

class CancelResult {
  final bool? reservationCancelled;
  final bool? mailSent;
  final bool? whatsappSent;

  CancelResult({
    this.reservationCancelled,
    this.mailSent,
    this.whatsappSent,
  });

  factory CancelResult.fromJson(Map<String, dynamic> json) {
    return CancelResult(
      reservationCancelled: json['reservationCancelled'] as bool?,
      mailSent: json['mailSent'] as bool?,
      whatsappSent: json['whatsappSent'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservationCancelled': reservationCancelled,
      'mailSent': mailSent,
      'whatsappSent': whatsappSent,
    };
  }
}
