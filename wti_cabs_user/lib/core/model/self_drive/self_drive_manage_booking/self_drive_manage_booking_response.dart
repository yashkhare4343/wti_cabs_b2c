class SelfDriveManageBookingResponse {
  final bool? success;
  final String? message;
  final int? statusCode;
  final List<ReservationResult>? result;

  SelfDriveManageBookingResponse({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory SelfDriveManageBookingResponse.fromJson(Map<String, dynamic> json) {
    return SelfDriveManageBookingResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: (json['result'] as List<dynamic>?)
          ?.map((e) => ReservationResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'statusCode': statusCode,
    'result': result?.map((e) => e.toJson()).toList(),
  };
}

class ReservationResult {
  final String? orderReferenceNumber;
  final SelectedCar? selectedCar;
  final List<BookingSummary>? bookingSummary;
  final PickupDrop? pickup;
  final PickupDrop? drop;
  final Price? price;

  ReservationResult({
    this.orderReferenceNumber,
    this.selectedCar,
    this.bookingSummary,
    this.pickup,
    this.drop,
    this.price,
  });

  factory ReservationResult.fromJson(Map<String, dynamic> json) {
    return ReservationResult(
      orderReferenceNumber: json['order_reference_number'] as String?,
      selectedCar: json['selectedCar'] != null
          ? SelectedCar.fromJson(json['selectedCar'] as Map<String, dynamic>)
          : null,
      bookingSummary: (json['bookingSummary'] as List<dynamic>?)
          ?.map((e) => BookingSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      pickup: json['pickup'] != null
          ? PickupDrop.fromJson(json['pickup'] as Map<String, dynamic>)
          : null,
      drop: json['drop'] != null
          ? PickupDrop.fromJson(json['drop'] as Map<String, dynamic>)
          : null,
      price: json['price'] != null
          ? Price.fromJson(json['price'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'order_reference_number': orderReferenceNumber,
    'selectedCar': selectedCar?.toJson(),
    'bookingSummary': bookingSummary?.map((e) => e.toJson()).toList(),
    'pickup': pickup?.toJson(),
    'drop': drop?.toJson(),
    'price': price?.toJson(),
  };
}

class SelectedCar {
  final String? img;
  final String? model;

  SelectedCar({this.img, this.model});

  factory SelectedCar.fromJson(Map<String, dynamic> json) {
    return SelectedCar(
      img: json['img'] as String?,
      model: json['model'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'img': img,
    'model': model,
  };
}

class BookingSummary {
  final String? text;
  final String? value;

  BookingSummary({this.text, this.value});

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      text: json['text'] as String?,
      value: json['value'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'value': value,
  };
}

class PickupDrop {
  final String? address;
  final String? date;
  final String? time;

  PickupDrop({this.address, this.date, this.time});

  factory PickupDrop.fromJson(Map<String, dynamic> json) {
    return PickupDrop(
      address: json['address'] as String?,
      date: json['date'] as String?,
      time: json['time'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'address': address,
    'date': date,
    'time': time,
  };
}

class Price {
  final num? amount;
  final String? currency;

  Price({this.amount, this.currency});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      amount: json['amount'] as num?,
      currency: json['currency'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'currency': currency,
  };
}
