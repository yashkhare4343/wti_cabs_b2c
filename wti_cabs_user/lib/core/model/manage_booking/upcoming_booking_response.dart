class UpcomingBookingResponse {
  final bool? chauffeurReservationsFetched;
  final List<ChauffeurResult>? result;
  final bool? isTokenValid;

  UpcomingBookingResponse({
    this.chauffeurReservationsFetched,
    this.result,
    this.isTokenValid,
  });

  factory UpcomingBookingResponse.fromJson(Map<String, dynamic> json) {
    return UpcomingBookingResponse(
      chauffeurReservationsFetched: json['chauffeurReservationsFetched'],
      result: (json['result'] as List?)?.map((e) => ChauffeurResult.fromJson(e)).toList(),
      isTokenValid: json['isTokenValid'],
    );
  }
}

class ChauffeurResult {
  final String? id;
  final String? countryName;
  final String? timezone;
  final String? searchId;
  final String? referenceNumber;
  final String? partnername;
  final String? paymentId;
  final RecieptId? recieptId;
  final String? orderReferenceNumber;
  final String? startTime;
  final String? endTime;
  final num? platformFee;
  final num? oneWayDistance;
  final num? distance;
  final dynamic package;
  final num? baseKm;
  final List<dynamic>? flags;
  final int? verificationCode;
  final VehicleDetails? vehicleDetails;
  final Place? source;
  final Place? destination;
  final List<dynamic>? stopovers;
  final TripTypeDetails? tripTypeDetails;
  final bool? paid;
  final Passenger? passenger;
  final String? guestId;
  final String? userType;
  final List<dynamic>? extrasSelected;
  final num? totalFare;
  final num? amountToBeCollected;
  final String? cancelledBy;
  final String? cancellationReason;
  final String? canceltime;
  final String? bookingStatus;
  final bool? isModifiedFlag;
  final String? couponCodeUsed;
  final String? offerUsed;
  final dynamic vendorAllocation;
  final dynamic carAllocated;
  final dynamic driverAllocated;
  final dynamic trackingEvents;
  final String? tripState;
  final String? stripeCustId;
  final String? stripeReceiptId;
  final String? stripePaymentId;
  final String? razorpayOrderId;
  final String? razorpayReceiptId;
  final String? razorpayPaymentId;
  final String? finalPaymentId;
  final int? paymentGatewayUsed;
  final String? flightNumber;
  final String? gstNumber;
  final String? performaInvoiceNumber;
  final String? remarks;
  final int? version;
  final num? differenceInTotalFare;
  final String? createdAt;
  final String? updatedAt;
  final int? v;
  final int? reservationCount;
  final bool? isInvoiceBtnVisible;

  ChauffeurResult({
    this.id,
    this.countryName,
    this.timezone,
    this.searchId,
    this.referenceNumber,
    this.partnername,
    this.paymentId,
    this.recieptId,
    this.orderReferenceNumber,
    this.startTime,
    this.endTime,
    this.platformFee,
    this.oneWayDistance,
    this.distance,
    this.package,
    this.baseKm,
    this.flags,
    this.verificationCode,
    this.vehicleDetails,
    this.source,
    this.destination,
    this.stopovers,
    this.tripTypeDetails,
    this.paid,
    this.passenger,
    this.guestId,
    this.userType,
    this.extrasSelected,
    this.totalFare,
    this.amountToBeCollected,
    this.cancelledBy,
    this.cancellationReason,
    this.canceltime,
    this.bookingStatus,
    this.isModifiedFlag,
    this.couponCodeUsed,
    this.offerUsed,
    this.vendorAllocation,
    this.carAllocated,
    this.driverAllocated,
    this.trackingEvents,
    this.tripState,
    this.stripeCustId,
    this.stripeReceiptId,
    this.stripePaymentId,
    this.razorpayOrderId,
    this.razorpayReceiptId,
    this.razorpayPaymentId,
    this.finalPaymentId,
    this.paymentGatewayUsed,
    this.flightNumber,
    this.gstNumber,
    this.performaInvoiceNumber,
    this.remarks,
    this.version,
    this.differenceInTotalFare,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.reservationCount,
    this.isInvoiceBtnVisible,
  });

  factory ChauffeurResult.fromJson(Map<String, dynamic> json) {
    return ChauffeurResult(
      id: json['_id'],
      countryName: json['countryName'],
      timezone: json['timezone'],
      searchId: json['search_id'],
      referenceNumber: json['reference_number'],
      partnername: json['partnername'],
      paymentId: json['payment_id'],
      recieptId: json['reciept_id'] != null ? RecieptId.fromJson(json['reciept_id']) : null,
      orderReferenceNumber: json['order_reference_number'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      platformFee: json['platform_fee'],
      oneWayDistance: json['one_way_distance'],
      distance: json['distance'],
      package: json['package'],
      baseKm: json['base_km'],
      flags: json['flags'],
      verificationCode: json['verification_code'],
      vehicleDetails: json['vehicle_details'] != null ? VehicleDetails.fromJson(json['vehicle_details']) : null,
      source: json['source'] != null ? Place.fromJson(json['source']) : null,
      destination: json['destination'] != null ? Place.fromJson(json['destination']) : null,
      stopovers: json['stopovers'],
      tripTypeDetails: json['trip_type_details'] != null ? TripTypeDetails.fromJson(json['trip_type_details']) : null,
      paid: json['paid'],
      passenger: json['passenger'] != null ? Passenger.fromJson(json['passenger']) : null,
      guestId: json['guest_id'],
      userType: json['userType'],
      extrasSelected: json['extrasSelected'],
      totalFare: json['total_fare'],
      amountToBeCollected: json['amount_to_be_collected'],
      cancelledBy: json['cancelled_by'],
      cancellationReason: json['cancellation_reason'],
      canceltime: json['canceltime'],
      bookingStatus: json['BookingStatus'],
      isModifiedFlag: json['isModifiedFlag'],
      couponCodeUsed: json['couponCodeUsed'],
      offerUsed: json['offerUsed'],
      vendorAllocation: json['VendorAllocation'],
      carAllocated: json['CarAllocated'],
      driverAllocated: json['DriverAllocated'],
      trackingEvents: json['tracking_events'],
      tripState: json['trip_State'],
      stripeCustId: json['stripe_cust_id'],
      stripeReceiptId: json['stripe_receipt_id'],
      stripePaymentId: json['stripe_payment_id'],
      razorpayOrderId: json['razorpay_order_id'],
      razorpayReceiptId: json['razorpay_receipt_id'],
      razorpayPaymentId: json['razorpay_payment_id'],
      finalPaymentId: json['final_payment_id'],
      paymentGatewayUsed: json['payment_gateway_used'],
      flightNumber: json['flightNumber'],
      gstNumber: json['gst_number'],
      performaInvoiceNumber: json['performa_invoice_number'],
      remarks: json['remarks'],
      version: json['version'],
      differenceInTotalFare: json['difference_in_total_fare'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
      reservationCount: json['reservationCount'],
      isInvoiceBtnVisible: json['isInvoiceBtnVisible'],
    );
  }
}



class Passenger {
  final String? id;
  final String? firstName;

  Passenger({this.id, this.firstName});

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['_id'],
      firstName: json['firstName'],
    );
  }
}

class Place {
  final String? state;
  final String? address;
  final String? country;
  final String? city;
  final String? placeId;
  final List<dynamic>? types;

  Place({this.state, this.address, this.country, this.city, this.placeId, this.types});

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      state: json['state'],
      address: json['address'],
      country: json['country'],
      city: json['city'],
      placeId: json['place_id'],
      types: json['types'],
    );
  }
}

class TripTypeDetails {
  final String? basicTripType;
  final String? tripType;
  final String? airportType;

  TripTypeDetails({this.basicTripType, this.tripType, this.airportType});

  factory TripTypeDetails.fromJson(Map<String, dynamic> json) {
    return TripTypeDetails(
      basicTripType: json['basic_trip_type'],
      tripType: json['trip_type'],
      airportType: json['airport_type'],
    );
  }
}

class RecieptId {
  String? id;
  String? countryName;
  num? paymentCount;
  String? reservationId;
  Currency? currency;
  String? baseCurrency;
  String? orderReferenceNumber;
  String? recieptId;
  String? invoiceId;
  num? addonCharges;
  num? freeWaitingTime;
  num? waitingInterval;
  num? normalWaitingCharge;
  List<dynamic>? airportWaitingChargeSlab;
  List<dynamic>? extraChargeSlab;
  num? congestionCharges;
  num? extraGlobalCharge;
  FareDetails? fareDetails;
  bool? isModifiedFlag;
  String? paymentType;
  num? partPaymentPercentage;
  bool? isFullPaymentCompleted;
  bool? isExtraAmountCollected;
  bool? isOffer;
  bool? isReciept;
  ExtraFareBreakup? extraFareBreakup;
  String? createdAt;
  String? updatedAt;
  num? v;

  RecieptId({
    this.id,
    this.countryName,
    this.paymentCount,
    this.reservationId,
    this.currency,
    this.baseCurrency,
    this.orderReferenceNumber,
    this.recieptId,
    this.invoiceId,
    this.addonCharges,
    this.freeWaitingTime,
    this.waitingInterval,
    this.normalWaitingCharge,
    this.airportWaitingChargeSlab,
    this.extraChargeSlab,
    this.congestionCharges,
    this.extraGlobalCharge,
    this.fareDetails,
    this.isModifiedFlag,
    this.paymentType,
    this.partPaymentPercentage,
    this.isFullPaymentCompleted,
    this.isExtraAmountCollected,
    this.isOffer,
    this.isReciept,
    this.extraFareBreakup,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory RecieptId.fromJson(Map<String, dynamic> json) => RecieptId(
    id: json['_id'],
    countryName: json['countryName'],
    paymentCount: json['paymentCount'],
    reservationId: json['reservation_id'],
    currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
    baseCurrency: json['baseCurrency'],
    orderReferenceNumber: json['order_reference_number'],
    recieptId: json['reciept_id'],
    invoiceId: json['invoice_id'],
    addonCharges: json['addon_charges'],
    freeWaitingTime: json['freeWaitingTime'],
    waitingInterval: json['waitingInterval'],
    normalWaitingCharge: json['normalWaitingCharge'],
    airportWaitingChargeSlab: json['airportWaitingChargeSlab'],
    extraChargeSlab: json['extraChargeSlab'],
    congestionCharges: json['congestion_charges'],
    extraGlobalCharge: json['extra_global_charge'],
    fareDetails: json['fare_details'] != null ? FareDetails.fromJson(json['fare_details']) : null,
    isModifiedFlag: json['isModifiedFlag'],
    paymentType: json['paymentType'],
    partPaymentPercentage: json['part_payment_percentage'],
    isFullPaymentCompleted: json['isFullPaymentCompleted'],
    isExtraAmountCollected: json['isExtraAmountCollected'],
    isOffer: json['isOffer'],
    isReciept: json['isReciept'],
    extraFareBreakup: json['extra_fare_breakup'] != null ? ExtraFareBreakup.fromJson(json['extra_fare_breakup']) : null,
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
    v: json['__v'],
  );
}

class Currency {
  String? currencyName;
  num? currencyRate;

  Currency({this.currencyName, this.currencyRate});

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
    currencyName: json['currencyName'],
    currencyRate: json['currencyRate'],
  );
}

class FareDetails {
  num? actualFare;
  num? sellerDiscount;
  num? baseFare;
  num? totalDriverCharges;
  num? stateTax;
  num? tollCharges;
  num? nightCharges;
  num? holidayCharges;
  num? totalTax;
  num? amountPaid;
  num? amountToBeCollected;
  num? actualAmountCollected;
  num? totalFare;
  num? airportEntryFee;
  num? airportFinalWaitingCharge;
  num? perKmCharge;
  num? perKmExtraCharge;
  ExtraTimeFare? extraTimeFare;
  ExtraCharges? extraCharges;
  NightChargesRate? nightChargesRate;
  HolidayChargesRate? holidayChargesRate;

  FareDetails({
    this.actualFare,
    this.sellerDiscount,
    this.baseFare,
    this.totalDriverCharges,
    this.stateTax,
    this.tollCharges,
    this.nightCharges,
    this.holidayCharges,
    this.totalTax,
    this.amountPaid,
    this.amountToBeCollected,
    this.actualAmountCollected,
    this.totalFare,
    this.airportEntryFee,
    this.airportFinalWaitingCharge,
    this.perKmCharge,
    this.perKmExtraCharge,
    this.extraTimeFare,
    this.extraCharges,
    this.nightChargesRate,
    this.holidayChargesRate,
  });

  factory FareDetails.fromJson(Map<String, dynamic> json) => FareDetails(
    actualFare: json['actual_fare'],
    sellerDiscount: json['seller_discount'],
    baseFare: json['base_fare'],
    totalDriverCharges: json['total_driver_charges'],
    stateTax: json['state_tax'],
    tollCharges: json['toll_charges'],
    nightCharges: json['night_charges'],
    holidayCharges: json['holiday_charges'],
    totalTax: json['total_tax'],
    amountPaid: json['amount_paid'],
    amountToBeCollected: json['amount_to_be_collected'],
    actualAmountCollected: json['actual_amount_collected'],
    totalFare: json['total_fare'],
    airportEntryFee: json['airport_entry_fee'],
    airportFinalWaitingCharge: json['airport_final_waiting_charge'],
    perKmCharge: json['per_km_charge'],
    perKmExtraCharge: json['per_km_extra_charge'],
    extraTimeFare: json['extra_time_fare'] != null ? ExtraTimeFare.fromJson(json['extra_time_fare']) : null,
    extraCharges: json['extra_charges'] != null ? ExtraCharges.fromJson(json['extra_charges']) : null,
    nightChargesRate: json['night_charges_rate'] != null ? NightChargesRate.fromJson(json['night_charges_rate']) : null,
    holidayChargesRate: json['holiday_charges_rate'] != null ? HolidayChargesRate.fromJson(json['holiday_charges_rate']) : null,
  );
}

class ExtraTimeFare {
  num? rate;
  num? applicableTime;

  ExtraTimeFare({this.rate, this.applicableTime});

  factory ExtraTimeFare.fromJson(Map<String, dynamic> json) => ExtraTimeFare(
    rate: json['rate'],
    applicableTime: json['applicable_time'],
  );
}

class ExtraCharges {
  NightCharge? nightCharges;
  ParkingCharges? parkingCharges;
  GenericTax? stateTax;
  GenericTax? tollCharges;
  WaitingCharges? waitingCharges;

  ExtraCharges({
    this.nightCharges,
    this.parkingCharges,
    this.stateTax,
    this.tollCharges,
    this.waitingCharges,
  });

  factory ExtraCharges.fromJson(Map<String, dynamic> json) => ExtraCharges(
    nightCharges: json['night_charges'] != null ? NightCharge.fromJson(json['night_charges']) : null,
    parkingCharges: json['parking_charges'] != null ? ParkingCharges.fromJson(json['parking_charges']) : null,
    stateTax: json['state_tax'] != null ? GenericTax.fromJson(json['state_tax']) : null,
    tollCharges: json['toll_charges'] != null ? GenericTax.fromJson(json['toll_charges']) : null,
    waitingCharges: json['waiting_charges'] != null ? WaitingCharges.fromJson(json['waiting_charges']) : null,
  );
}

class NightCharge {
  num? amount;
  num? applicableTimeFrom;
  num? applicableTimeTill;
  bool? isApplicable;
  bool? isIncludedInBaseFare;
  bool? isIncludedInGrandTotal;

  NightCharge({
    this.amount,
    this.applicableTimeFrom,
    this.applicableTimeTill,
    this.isApplicable,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
  });

  factory NightCharge.fromJson(Map<String, dynamic> json) => NightCharge(
    amount: json['amount'],
    applicableTimeFrom: json['applicable_time_from'],
    applicableTimeTill: json['applicable_time_till'],
    isApplicable: json['is_applicable'],
    isIncludedInBaseFare: json['is_included_in_base_fare'],
    isIncludedInGrandTotal: json['is_included_in_grand_total'],
  );
}

class ParkingCharges {
  num? amount;
  bool? isApplicable;
  bool? isIncludedInBaseFare;
  bool? isIncludedInGrandTotal;

  ParkingCharges({
    this.amount,
    this.isApplicable,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
  });

  factory ParkingCharges.fromJson(Map<String, dynamic> json) => ParkingCharges(
    amount: json['amount'],
    isApplicable: json['is_applicable'],
    isIncludedInBaseFare: json['is_included_in_base_fare'],
    isIncludedInGrandTotal: json['is_included_in_grand_total'],
  );
}

class GenericTax {
  num? amount;
  bool? isApplicable;
  bool? isIncludedInBaseFare;
  bool? isIncludedInGrandTotal;

  GenericTax({
    this.amount,
    this.isApplicable,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
  });

  factory GenericTax.fromJson(Map<String, dynamic> json) => GenericTax(
    amount: json['amount'],
    isApplicable: json['is_applicable'],
    isIncludedInBaseFare: json['is_included_in_base_fare'],
    isIncludedInGrandTotal: json['is_included_in_grand_total'],
  );
}

class WaitingCharges {
  num? amount;
  num? applicableTime;
  num? freeWaitingTime;
  bool? isApplicable;
  bool? isIncludedInBaseFare;
  bool? isIncludedInGrandTotal;

  WaitingCharges({
    this.amount,
    this.applicableTime,
    this.freeWaitingTime,
    this.isApplicable,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
  });

  factory WaitingCharges.fromJson(Map<String, dynamic> json) => WaitingCharges(
    amount: json['amount'],
    applicableTime: json['applicable_time'],
    freeWaitingTime: json['free_waiting_time'],
    isApplicable: json['is_applicable'],
    isIncludedInBaseFare: json['is_included_in_base_fare'],
    isIncludedInGrandTotal: json['is_included_in_grand_total'],
  );
}

class NightChargesRate {
  num? rate;
  num? hikePercentage;
  bool? isNightChargesApplicable;

  NightChargesRate({
    this.rate,
    this.hikePercentage,
    this.isNightChargesApplicable,
  });

  factory NightChargesRate.fromJson(Map<String, dynamic> json) => NightChargesRate(
    rate: json['rate'],
    hikePercentage: json['hikePercentage'],
    isNightChargesApplicable: json['isNightChargesApplicable'],
  );
}

class HolidayChargesRate {
  num? rate;
  num? hikePercentage;
  bool? isHolidayChargesApplicable;

  HolidayChargesRate({
    this.rate,
    this.hikePercentage,
    this.isHolidayChargesApplicable,
  });

  factory HolidayChargesRate.fromJson(Map<String, dynamic> json) => HolidayChargesRate(
    rate: json['rate'],
    hikePercentage: json['hikePercentage'],
    isHolidayChargesApplicable: json['isHolidayChargesApplicable'],
  );
}

class ExtraFareBreakup {
  ExtraTravelled? extraTravelled;
  ExtraTime? extraTime;
  AmountOnly? nightCharges;
  AmountOnly? tollCharges;
  AmountOnly? stateTax;
  AmountOnly? parkingCharges;
  AmountOnly? waitingCharges;
  AmountOnly? miscellaneous;
  AmountOnly? tax;

  ExtraFareBreakup({
    this.extraTravelled,
    this.extraTime,
    this.nightCharges,
    this.tollCharges,
    this.stateTax,
    this.parkingCharges,
    this.waitingCharges,
    this.miscellaneous,
    this.tax,
  });

  factory ExtraFareBreakup.fromJson(Map<String, dynamic> json) => ExtraFareBreakup(
    extraTravelled: json['extra_travelled'] != null ? ExtraTravelled.fromJson(json['extra_travelled']) : null,
    extraTime: json['extra_time'] != null ? ExtraTime.fromJson(json['extra_time']) : null,
    nightCharges: json['night_charges'] != null ? AmountOnly.fromJson(json['night_charges']) : null,
    tollCharges: json['toll_charges'] != null ? AmountOnly.fromJson(json['toll_charges']) : null,
    stateTax: json['state_tax'] != null ? AmountOnly.fromJson(json['state_tax']) : null,
    parkingCharges: json['parking_charges'] != null ? AmountOnly.fromJson(json['parking_charges']) : null,
    waitingCharges: json['waiting_charges'] != null ? AmountOnly.fromJson(json['waiting_charges']) : null,
    miscellaneous: json['miscellaneous'] != null ? AmountOnly.fromJson(json['miscellaneous']) : null,
    tax: json['tax'] != null ? AmountOnly.fromJson(json['tax']) : null,
  );
}

class ExtraTravelled {
  num? amount;
  num? extraKms;

  ExtraTravelled({this.amount, this.extraKms});

  factory ExtraTravelled.fromJson(Map<String, dynamic> json) => ExtraTravelled(
    amount: json['amount'],
    extraKms: json['extra_kms'],
  );
}

class ExtraTime {
  num? amount;
  num? extraMinutes;

  ExtraTime({this.amount, this.extraMinutes});

  factory ExtraTime.fromJson(Map<String, dynamic> json) => ExtraTime(
    amount: json['amount'],
    extraMinutes: json['extra_minutes'],
  );
}

class AmountOnly {
  num? amount;

  AmountOnly({this.amount});

  factory AmountOnly.fromJson(Map<String, dynamic> json) => AmountOnly(
    amount: json['amount'],
  );
}

class VehicleDetails {
  String? name;
  String? model;
  String? vehicleNumber;
  String? imageUrl;
  String ? type;

  VehicleDetails({this.name, this.model, this.vehicleNumber, this.imageUrl, this.type});

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      name: json['name'],
      model: json['model'],
      vehicleNumber: json['vehicleNumber'],
      imageUrl: json['imageUrl'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'model': model,
    'vehicleNumber': vehicleNumber,
    'imageUrl': imageUrl,
    'type': type,
  };
}
