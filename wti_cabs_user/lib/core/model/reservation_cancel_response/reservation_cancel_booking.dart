class ReservationCancelResponse {
  final bool? reservationCancelled;
  final String? id;
  final String? message;
  final bool? mailSent;

  ReservationCancelResponse({
    this.reservationCancelled,
    this.id,
    this.message,
    this.mailSent,
  });

  factory ReservationCancelResponse.fromJson(Map<String, dynamic> json) {
    return ReservationCancelResponse(
      reservationCancelled: json['ReservationCancelled'] as bool?,
      id: json['ID'] as String?,
      message: json['message'] as String?,
      mailSent: json['mailSent'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ReservationCancelled': reservationCancelled,
      'ID': id,
      'message': message,
      'mailSent': mailSent,
    };
  }
}
