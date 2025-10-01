class PaymentReservationResponse {
  bool? success;
  String? message;
  int? statusCode;
  ReservationResult? result;

  PaymentReservationResponse({this.success, this.message, this.statusCode, this.result});

  factory PaymentReservationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentReservationResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: json['result'] != null
          ? ReservationResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'statusCode': statusCode,
    'result': result?.toJson(),
  };
}

class ReservationResult {
  List<BookingSummary>? bookingSummary;
  String? vehicleImg;
  PickupDrop? pickup;
  PickupDrop? drop;

  ReservationResult({this.bookingSummary, this.vehicleImg, this.pickup, this.drop});

  factory ReservationResult.fromJson(Map<String, dynamic> json) {
    return ReservationResult(
      bookingSummary: json['bookingSummary'] != null
          ? (json['bookingSummary'] as List)
          .map((e) => BookingSummary.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
      vehicleImg: json['vehicleImg'] as String?,
      pickup: json['pickup'] != null ? PickupDrop.fromJson(json['pickup'] as Map<String, dynamic>) : null,
      drop: json['drop'] != null ? PickupDrop.fromJson(json['drop'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'bookingSummary': bookingSummary?.map((e) => e.toJson()).toList(),
    'vehicleImg': vehicleImg,
    'pickup': pickup?.toJson(),
    'drop': drop?.toJson(),
  };
}

class BookingSummary {
  String? label;
  dynamic value; // Could be String, int, etc.

  BookingSummary({this.label, this.value});

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      label: json['label'] as String?,
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'value': value,
  };
}

class PickupDrop {
  String? title;
  String? address;
  String? date;
  String? time;

  PickupDrop({this.title, this.address, this.date, this.time});

  factory PickupDrop.fromJson(Map<String, dynamic> json) {
    return PickupDrop(
      title: json['title'] as String?,
      address: json['address'] as String?,
      date: json['date'] as String?,
      time: json['time'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'address': address,
    'date': date,
    'time': time,
  };
}
