class ChauffeurReservationsResponse {
  final bool? chauffeurReservationsFetched;
  final List<Result>? result;

  ChauffeurReservationsResponse({
    this.chauffeurReservationsFetched,
    this.result,
  });

  factory ChauffeurReservationsResponse.fromJson(Map<String, dynamic> json) {
    return ChauffeurReservationsResponse(
      chauffeurReservationsFetched: json['chauffeurReservationsFetched'] as bool?,
      result: (json['result'] as List<dynamic>?)
          ?.map((e) => Result.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'chauffeurReservationsFetched': chauffeurReservationsFetched,
    'result': result?.map((e) => e.toJson()).toList(),
  };
}

class Result {
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
  final num? verificationCode;
  final VehicleDetails? vehicleDetails;
  final Location? source;
  final Location? destination;
  final List<dynamic>? stopovers;
  final TripTypeDetails? tripTypeDetails;
  final bool? paid;
  final String? passenger;
  final dynamic guestId;
  final String? userType;
  final List<dynamic>? extrasSelected;
  final num? totalFare;
  final num? amountToBeCollected;
  final dynamic cancelledBy;
  final dynamic cancellationReason;
  final dynamic canceltime;
  final String? bookingStatus;
  final bool? isModifiedFlag;
  final dynamic couponCodeUsed;
  final dynamic offerUsed;
  final dynamic vendorAllocation;
  final dynamic carAllocated;
  final dynamic driverAllocated;
  final dynamic trackingEvents;
  final String? tripState;
  final dynamic stripeCustId;
  final dynamic stripeReceiptId;
  final dynamic stripePaymentId;
  final String? razorpayOrderId;
  final String? razorpayReceiptId;
  final String? razorpayPaymentId;
  final dynamic finalPaymentId;
  final num? paymentGatewayUsed;
  final String? flightNumber;
  final String? gstNumber;
  final String? performaInvoiceNumber;
  final String? remarks;
  final num? version;
  final num? differenceInTotalFare;
  final String? createdAt;
  final String? updatedAt;
  final num? v;
  final num? reservationCount;
  final String? carImageUrl;

  Result({
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
    this.carImageUrl,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      id: json['_id'] as String?,
      countryName: json['countryName'] as String?,
      timezone: json['timezone'] as String?,
      searchId: json['search_id'] as String?,
      referenceNumber: json['reference_number'] as String?,
      partnername: json['partnername'] as String?,
      paymentId: json['payment_id'] as String?,
      recieptId: json['reciept_id'] != null
          ? RecieptId.fromJson(json['reciept_id'] as Map<String, dynamic>)
          : null,
      orderReferenceNumber: json['order_reference_number'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      platformFee: json['platform_fee'] as num?,
      oneWayDistance: json['one_way_distance'] as num?,
      distance: json['distance'] as num?,
      package: json['package'],
      baseKm: json['base_km'] as num?,
      flags: json['flags'] as List<dynamic>?,
      verificationCode: json['verification_code'] as num?,
      vehicleDetails: json['vehicle_details'] != null
          ? VehicleDetails.fromJson(
          json['vehicle_details'] as Map<String, dynamic>)
          : null,
      source: json['source'] != null
          ? Location.fromJson(json['source'] as Map<String, dynamic>)
          : null,
      destination: json['destination'] != null
          ? Location.fromJson(json['destination'] as Map<String, dynamic>)
          : null,
      stopovers: json['stopovers'] as List<dynamic>?,
      tripTypeDetails: json['trip_type_details'] != null
          ? TripTypeDetails.fromJson(
          json['trip_type_details'] as Map<String, dynamic>)
          : null,
      paid: json['paid'] as bool?,
      passenger: json['passenger'] as String?,
      guestId: json['guest_id'],
      userType: json['userType'] as String?,
      extrasSelected: json['extrasSelected'] as List<dynamic>?,
      totalFare: json['total_fare'] as num?,
      amountToBeCollected: json['amount_to_be_collected'] as num?,
      cancelledBy: json['cancelled_by'],
      cancellationReason: json['cancellation_reason'],
      canceltime: json['canceltime'],
      bookingStatus: json['BookingStatus'] as String?,
      isModifiedFlag: json['isModifiedFlag'] as bool?,
      couponCodeUsed: json['couponCodeUsed'],
      offerUsed: json['offerUsed'],
      vendorAllocation: json['VendorAllocation'],
      carAllocated: json['CarAllocated'],
      driverAllocated: json['DriverAllocated'],
      trackingEvents: json['tracking_events'],
      tripState: json['trip_State'] as String?,
      stripeCustId: json['stripe_cust_id'],
      stripeReceiptId: json['stripe_receipt_id'],
      stripePaymentId: json['stripe_payment_id'],
      razorpayOrderId: json['razorpay_order_id'] as String?,
      razorpayReceiptId: json['razorpay_receipt_id'] as String?,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      finalPaymentId: json['final_payment_id'],
      paymentGatewayUsed: json['payment_gateway_used'] as num?,
      flightNumber: json['flightNumber'] as String?,
      gstNumber: json['gst_number'] as String?,
      performaInvoiceNumber: json['performa_invoice_number'] as String?,
      remarks: json['remarks'] as String?,
      version: json['version'] as num?,
      differenceInTotalFare: json['difference_in_total_fare'] as num?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      v: json['__v'] as num?,
      reservationCount: json['reservationCount'] as num?,
      carImageUrl: json['carImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "countryName": countryName,
    "timezone": timezone,
    "search_id": searchId,
    "reference_number": referenceNumber,
    "partnername": partnername,
    "payment_id": paymentId,
    "reciept_id": recieptId?.toJson(),
    "order_reference_number": orderReferenceNumber,
    "start_time": startTime,
    "end_time": endTime,
    "platform_fee": platformFee,
    "one_way_distance": oneWayDistance,
    "distance": distance,
    "package": package,
    "base_km": baseKm,
    "flags": flags,
    "verification_code": verificationCode,
    "vehicle_details": vehicleDetails?.toJson(),
    "source": source?.toJson(),
    "destination": destination?.toJson(),
    "stopovers": stopovers,
    "trip_type_details": tripTypeDetails?.toJson(),
    "paid": paid,
    "passenger": passenger,
    "guest_id": guestId,
    "userType": userType,
    "extrasSelected": extrasSelected,
    "total_fare": totalFare,
    "amount_to_be_collected": amountToBeCollected,
    "cancelled_by": cancelledBy,
    "cancellation_reason": cancellationReason,
    "canceltime": canceltime,
    "BookingStatus": bookingStatus,
    "isModifiedFlag": isModifiedFlag,
    "couponCodeUsed": couponCodeUsed,
    "offerUsed": offerUsed,
    "VendorAllocation": vendorAllocation,
    "CarAllocated": carAllocated,
    "DriverAllocated": driverAllocated,
    "tracking_events": trackingEvents,
    "trip_State": tripState,
    "stripe_cust_id": stripeCustId,
    "stripe_receipt_id": stripeReceiptId,
    "stripe_payment_id": stripePaymentId,
    "razorpay_order_id": razorpayOrderId,
    "razorpay_receipt_id": razorpayReceiptId,
    "razorpay_payment_id": razorpayPaymentId,
    "final_payment_id": finalPaymentId,
    "payment_gateway_used": paymentGatewayUsed,
    "flightNumber": flightNumber,
    "gst_number": gstNumber,
    "performa_invoice_number": performaInvoiceNumber,
    "remarks": remarks,
    "version": version,
    "difference_in_total_fare": differenceInTotalFare,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "__v": v,
    "reservationCount": reservationCount,
    "carImageUrl": carImageUrl,
  };
}

class RecieptId {
  final String? id;
  final String? countryName;
  final num? paymentCount;
  final dynamic reservationId;
  final Currency? currency;
  final String? baseCurrency;
  final String? orderReferenceNumber;
  final String? recieptId;
  final dynamic invoiceId;
  final num? addonCharges;
  final num? freeWaitingTime;
  final num? waitingInterval;
  final num? normalWaitingCharge;
  final List<dynamic>? airportWaitingChargeSlab;
  final List<dynamic>? extraChargeSlab;
  final num? congestionCharges;
  final num? extraGlobalCharge;
  final FareDetails? fareDetails;
  final bool? isModifiedFlag;
  final String? paymentType;
  final num? partPaymentPercentage;
  final bool? isFullPaymentCompleted;
  final bool? isExtraAmountCollected;
  final bool? isOffer;
  final bool? isReciept;
  final ExtraFareBreakup? extraFareBreakup;
  final String? createdAt;
  final String? updatedAt;
  final num? v;

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

  factory RecieptId.fromJson(Map<String, dynamic> json) {
    return RecieptId(
      id: json['_id'] as String?,
      countryName: json['countryName'] as String?,
      paymentCount: json['paymentCount'] as num?,
      reservationId: json['reservation_id'],
      currency: json['currency'] != null
          ? Currency.fromJson(json['currency'] as Map<String, dynamic>)
          : null,
      baseCurrency: json['baseCurrency'] as String?,
      orderReferenceNumber: json['order_reference_number'] as String?,
      recieptId: json['reciept_id'] as String?,
      invoiceId: json['invoice_id'],
      addonCharges: json['addon_charges'] as num?,
      freeWaitingTime: json['freeWaitingTime'] as num?,
      waitingInterval: json['waitingInterval'] as num?,
      normalWaitingCharge: json['normalWaitingCharge'] as num?,
      airportWaitingChargeSlab:
      json['airportWaitingChargeSlab'] as List<dynamic>?,
      extraChargeSlab: json['extraChargeSlab'] as List<dynamic>?,
      congestionCharges: json['congestion_charges'] as num?,
      extraGlobalCharge: json['extra_global_charge'] as num?,
      fareDetails: json['fare_details'] != null
          ? FareDetails.fromJson(json['fare_details'] as Map<String, dynamic>)
          : null,
      isModifiedFlag: json['isModifiedFlag'] as bool?,
      paymentType: json['paymentType'] as String?,
      partPaymentPercentage: json['part_payment_percentage'] as num?,
      isFullPaymentCompleted: json['isFullPaymentCompleted'] as bool?,
      isExtraAmountCollected: json['isExtraAmountCollected'] as bool?,
      isOffer: json['isOffer'] as bool?,
      isReciept: json['isReciept'] as bool?,
      extraFareBreakup: json['extra_fare_breakup'] != null
          ? ExtraFareBreakup.fromJson(
          json['extra_fare_breakup'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      v: json['__v'] as num?,
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "countryName": countryName,
    "paymentCount": paymentCount,
    "reservation_id": reservationId,
    "currency": currency?.toJson(),
    "baseCurrency": baseCurrency,
    "order_reference_number": orderReferenceNumber,
    "reciept_id": recieptId,
    "invoice_id": invoiceId,
    "addon_charges": addonCharges,
    "freeWaitingTime": freeWaitingTime,
    "waitingInterval": waitingInterval,
    "normalWaitingCharge": normalWaitingCharge,
    "airportWaitingChargeSlab": airportWaitingChargeSlab,
    "extraChargeSlab": extraChargeSlab,
    "congestion_charges": congestionCharges,
    "extra_global_charge": extraGlobalCharge,
    "fare_details": fareDetails?.toJson(),
    "isModifiedFlag": isModifiedFlag,
    "paymentType": paymentType,
    "part_payment_percentage": partPaymentPercentage,
    "isFullPaymentCompleted": isFullPaymentCompleted,
    "isExtraAmountCollected": isExtraAmountCollected,
    "isOffer": isOffer,
    "isReciept": isReciept,
    "extra_fare_breakup": extraFareBreakup?.toJson(),
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "__v": v,
  };
}

class Currency {
  final String? currencyName;
  final num? currencyRate;

  Currency({this.currencyName, this.currencyRate});

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
    currencyName: json['currencyName'] as String?,
    currencyRate: json['currencyRate'] as num?,
  );

  Map<String, dynamic> toJson() => {
    'currencyName': currencyName,
    'currencyRate': currencyRate,
  };
}
class FareDetails {
  final num? actualFare;
  final num? sellerDiscount;
  final num? baseFare;
  final num? totalDriverCharges;
  final num? stateTax;
  final num? tollCharges;
  final num? nightCharges;
  final num? holidayCharges;
  final num? totalTax;
  final num? amountPaid;
  final num? amountToBeCollected;
  final num? actualAmountCollected;
  final num? totalFare;
  final num? airportEntryFee;
  final num? airportFinalWaitingCharge;
  final num? perKmCharge;
  final num? perKmExtraCharge;
  final ExtraTimeFare? extraTimeFare;
  final ExtraCharges? extraCharges;
  final NightChargesRate? nightChargesRate;
  final HolidayChargesRate? holidayChargesRate;

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

  factory FareDetails.fromJson(Map<String, dynamic> json) {
    return FareDetails(
      actualFare: json['actual_fare'] as num?,
      sellerDiscount: json['seller_discount'] as num?,
      baseFare: json['base_fare'] as num?,
      totalDriverCharges: json['total_driver_charges'] as num?,
      stateTax: json['state_tax'] as num?,
      tollCharges: json['toll_charges'] as num?,
      nightCharges: json['night_charges'] as num?,
      holidayCharges: json['holiday_charges'] as num?,
      totalTax: json['total_tax'] as num?,
      amountPaid: json['amount_paid'] as num?,
      amountToBeCollected: json['amount_to_be_collected'] as num?,
      actualAmountCollected: json['actual_amount_collected'] as num?,
      totalFare: json['total_fare'] as num?,
      airportEntryFee: json['airport_entry_fee'] as num?,
      airportFinalWaitingCharge: json['airport_final_waiting_charge'] as num?,
      perKmCharge: json['per_km_charge'] as num?,
      perKmExtraCharge: json['per_km_extra_charge'] as num?,
      extraTimeFare: json['extra_time_fare'] != null
          ? ExtraTimeFare.fromJson(
          json['extra_time_fare'] as Map<String, dynamic>)
          : null,
      extraCharges: json['extra_charges'] != null
          ? ExtraCharges.fromJson(json['extra_charges'] as Map<String, dynamic>)
          : null,
      nightChargesRate: json['night_charges_rate'] != null
          ? NightChargesRate.fromJson(
          json['night_charges_rate'] as Map<String, dynamic>)
          : null,
      holidayChargesRate: json['holiday_charges_rate'] != null
          ? HolidayChargesRate.fromJson(
          json['holiday_charges_rate'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "actual_fare": actualFare,
    "seller_discount": sellerDiscount,
    "base_fare": baseFare,
    "total_driver_charges": totalDriverCharges,
    "state_tax": stateTax,
    "toll_charges": tollCharges,
    "night_charges": nightCharges,
    "holiday_charges": holidayCharges,
    "total_tax": totalTax,
    "amount_paid": amountPaid,
    "amount_to_be_collected": amountToBeCollected,
    "actual_amount_collected": actualAmountCollected,
    "total_fare": totalFare,
    "airport_entry_fee": airportEntryFee,
    "airport_final_waiting_charge": airportFinalWaitingCharge,
    "per_km_charge": perKmCharge,
    "per_km_extra_charge": perKmExtraCharge,
    "extra_time_fare": extraTimeFare?.toJson(),
    "extra_charges": extraCharges?.toJson(),
    "night_charges_rate": nightChargesRate?.toJson(),
    "holiday_charges_rate": holidayChargesRate?.toJson(),
  };
}

class ExtraTimeFare {
  final num? rate;
  final num? applicableTime;

  ExtraTimeFare({this.rate, this.applicableTime});

  factory ExtraTimeFare.fromJson(Map<String, dynamic> json) => ExtraTimeFare(
    rate: json['rate'] as num?,
    applicableTime: json['applicable_time'] as num?,
  );

  Map<String, dynamic> toJson() => {
    "rate": rate,
    "applicable_time": applicableTime,
  };
}

class ExtraCharges {
  final ChargeDetail? nightCharges;
  final ChargeDetail? tollCharges;
  final ChargeDetail? stateTax;
  final ChargeDetail? parkingCharges;
  final WaitingCharges? waitingCharges;

  ExtraCharges({
    this.nightCharges,
    this.tollCharges,
    this.stateTax,
    this.parkingCharges,
    this.waitingCharges,
  });

  factory ExtraCharges.fromJson(Map<String, dynamic> json) => ExtraCharges(
    nightCharges: json['night_charges'] != null
        ? ChargeDetail.fromJson(
        json['night_charges'] as Map<String, dynamic>)
        : null,
    tollCharges: json['toll_charges'] != null
        ? ChargeDetail.fromJson(
        json['toll_charges'] as Map<String, dynamic>)
        : null,
    stateTax: json['state_tax'] != null
        ? ChargeDetail.fromJson(json['state_tax'] as Map<String, dynamic>)
        : null,
    parkingCharges: json['parking_charges'] != null
        ? ChargeDetail.fromJson(
        json['parking_charges'] as Map<String, dynamic>)
        : null,
    waitingCharges: json['waiting_charges'] != null
        ? WaitingCharges.fromJson(
        json['waiting_charges'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    "night_charges": nightCharges?.toJson(),
    "toll_charges": tollCharges?.toJson(),
    "state_tax": stateTax?.toJson(),
    "parking_charges": parkingCharges?.toJson(),
    "waiting_charges": waitingCharges?.toJson(),
  };
}

class ChargeDetail {
  final num? amount;
  final bool? isIncludedInBaseFare;
  final bool? isIncludedInGrandTotal;
  final num? applicableTimeFrom;
  final num? applicableTimeTill;
  final bool? isApplicable;

  ChargeDetail({
    this.amount,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
    this.applicableTimeFrom,
    this.applicableTimeTill,
    this.isApplicable,
  });

  factory ChargeDetail.fromJson(Map<String, dynamic> json) => ChargeDetail(
    amount: json['amount'] as num?,
    isIncludedInBaseFare: json['is_included_in_base_fare'] as bool?,
    isIncludedInGrandTotal: json['is_included_in_grand_total'] as bool?,
    applicableTimeFrom: json['applicable_time_from'] as num?,
    applicableTimeTill: json['applicable_time_till'] as num?,
    isApplicable: json['is_applicable'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    "amount": amount,
    "is_included_in_base_fare": isIncludedInBaseFare,
    "is_included_in_grand_total": isIncludedInGrandTotal,
    "applicable_time_from": applicableTimeFrom,
    "applicable_time_till": applicableTimeTill,
    "is_applicable": isApplicable,
  };
}

class WaitingCharges {
  final num? amount;
  final num? freeWaitingTime;
  final num? applicableTime;
  final bool? isIncludedInBaseFare;
  final bool? isIncludedInGrandTotal;
  final bool? isApplicable;

  WaitingCharges({
    this.amount,
    this.freeWaitingTime,
    this.applicableTime,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
    this.isApplicable,
  });

  factory WaitingCharges.fromJson(Map<String, dynamic> json) => WaitingCharges(
    amount: json['amount'] as num?,
    freeWaitingTime: json['free_waiting_time'] as num?,
    applicableTime: json['applicable_time'] as num?,
    isIncludedInBaseFare: json['is_included_in_base_fare'] as bool?,
    isIncludedInGrandTotal: json['is_included_in_grand_total'] as bool?,
    isApplicable: json['is_applicable'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    "amount": amount,
    "free_waiting_time": freeWaitingTime,
    "applicable_time": applicableTime,
    "is_included_in_base_fare": isIncludedInBaseFare,
    "is_included_in_grand_total": isIncludedInGrandTotal,
    "is_applicable": isApplicable,
  };
}

class NightChargesRate {
  final num? rate;
  final num? hikePercentage;
  final bool? isNightChargesApplicable;

  NightChargesRate({
    this.rate,
    this.hikePercentage,
    this.isNightChargesApplicable,
  });

  factory NightChargesRate.fromJson(Map<String, dynamic> json) =>
      NightChargesRate(
        rate: json['rate'] as num?,
        hikePercentage: json['hikePercentage'] as num?,
        isNightChargesApplicable:
        json['isNightChargesApplicable'] as bool?,
      );

  Map<String, dynamic> toJson() => {
    "rate": rate,
    "hikePercentage": hikePercentage,
    "isNightChargesApplicable": isNightChargesApplicable,
  };
}

class HolidayChargesRate {
  final num? rate;
  final num? hikePercentage;
  final bool? isHolidayChargesApplicable;

  HolidayChargesRate({
    this.rate,
    this.hikePercentage,
    this.isHolidayChargesApplicable,
  });

  factory HolidayChargesRate.fromJson(Map<String, dynamic> json) =>
      HolidayChargesRate(
        rate: json['rate'] as num?,
        hikePercentage: json['hikePercentage'] as num?,
        isHolidayChargesApplicable:
        json['isHolidayChargesApplicable'] as bool?,
      );

  Map<String, dynamic> toJson() => {
    "rate": rate,
    "hikePercentage": hikePercentage,
    "isHolidayChargesApplicable": isHolidayChargesApplicable,
  };
}
class Location {
  final String? address;
  final num? latitude;
  final num? longitude;
  final String? state;
  final String? country;
  final String? city;
  final String? placeId;
  final List<String>? types;

  Location({
    this.address,
    this.latitude,
    this.longitude,
    this.state,
    this.country,
    this.city,
    this.placeId,
    this.types,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    address: json['address'] as String?,
    latitude: json['latitude'] as num?,
    longitude: json['longitude'] as num?,
    state: json['state'] as String?,
    country: json['country'] as String?,
    city: json['city'] as String?,
    placeId: json['place_id'] as String?,
    types: (json['types'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    "address": address,
    "latitude": latitude,
    "longitude": longitude,
    "state": state,
    "country": country,
    "city": city,
    "place_id": placeId,
    "types": types,
  };
}
class TripTypeDetails {
  final String? basicTripType;
  final String? tripType;
  final String? airportType;

  TripTypeDetails({this.basicTripType, this.tripType, this.airportType});

  factory TripTypeDetails.fromJson(Map<String, dynamic> json) =>
      TripTypeDetails(
        basicTripType: json['basic_trip_type'] as String?,
        tripType: json['trip_type'] as String?,
        airportType: json['airport_type'] as String?,
      );

  Map<String, dynamic> toJson() => {
    "basic_trip_type": basicTripType,
    "trip_type": tripType,
    "airport_type": airportType,
  };
}

class VehicleDetails {
  final dynamic fleetId;
  final String? skuId;
  final String? type;
  final String? subcategory;
  final String? combustionType;
  final String? model;
  final bool? carrier;
  final String? makeYearType;
  final String? makeYear;
  final String? title;

  VehicleDetails({
    this.fleetId,
    this.skuId,
    this.type,
    this.subcategory,
    this.combustionType,
    this.model,
    this.carrier,
    this.makeYearType,
    this.makeYear,
    this.title,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) => VehicleDetails(
    fleetId: json['fleet_id'],
    skuId: json['sku_id'] as String?,
    type: json['type'] as String?,
    subcategory: json['subcategory'] as String?,
    combustionType: json['combustion_type'] as String?,
    model: json['model'] as String?,
    carrier: json['carrier'] as bool?,
    makeYearType: json['make_year_type'] as String?,
    makeYear: json['make_year'] as String?,
    title: json['title'] as String?,
  );

  Map<String, dynamic> toJson() => {
    "fleet_id": fleetId,
    "sku_id": skuId,
    "type": type,
    "subcategory": subcategory,
    "combustion_type": combustionType,
    "model": model,
    "carrier": carrier,
    "make_year_type": makeYearType,
    "make_year": makeYear,
    "title": title,
  };
}

class ExtraFareBreakup {
  final ExtraAmount? extraTravelled;
  final ExtraAmount? extraTime;
  final SimpleAmount? nightCharges;
  final SimpleAmount? tollCharges;
  final SimpleAmount? stateTax;
  final SimpleAmount? parkingCharges;
  final SimpleAmount? waitingCharges;
  final SimpleAmount? miscellaneous;
  final SimpleAmount? tax;

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

  factory ExtraFareBreakup.fromJson(Map<String, dynamic> json) =>
      ExtraFareBreakup(
        extraTravelled: json['extra_travelled'] != null
            ? ExtraAmount.fromJson(
            json['extra_travelled'] as Map<String, dynamic>)
            : null,
        extraTime: json['extra_time'] != null
            ? ExtraAmount.fromJson(
            json['extra_time'] as Map<String, dynamic>)
            : null,
        nightCharges: json['night_charges'] != null
            ? SimpleAmount.fromJson(
            json['night_charges'] as Map<String, dynamic>)
            : null,
        tollCharges: json['toll_charges'] != null
            ? SimpleAmount.fromJson(
            json['toll_charges'] as Map<String, dynamic>)
            : null,
        stateTax: json['state_tax'] != null
            ? SimpleAmount.fromJson(
            json['state_tax'] as Map<String, dynamic>)
            : null,
        parkingCharges: json['parking_charges'] != null
            ? SimpleAmount.fromJson(
            json['parking_charges'] as Map<String, dynamic>)
            : null,
        waitingCharges: json['waiting_charges'] != null
            ? SimpleAmount.fromJson(
            json['waiting_charges'] as Map<String, dynamic>)
            : null,
        miscellaneous: json['miscellaneous'] != null
            ? SimpleAmount.fromJson(
            json['miscellaneous'] as Map<String, dynamic>)
            : null,
        tax: json['tax'] != null
            ? SimpleAmount.fromJson(json['tax'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
    "extra_travelled": extraTravelled?.toJson(),
    "extra_time": extraTime?.toJson(),
    "night_charges": nightCharges?.toJson(),
    "toll_charges": tollCharges?.toJson(),
    "state_tax": stateTax?.toJson(),
    "parking_charges": parkingCharges?.toJson(),
    "waiting_charges": waitingCharges?.toJson(),
    "miscellaneous": miscellaneous?.toJson(),
    "tax": tax?.toJson(),
  };
}

class ExtraAmount {
  final num? amount;
  final num? extraKms;
  final num? extraMinutes;

  ExtraAmount({this.amount, this.extraKms, this.extraMinutes});

  factory ExtraAmount.fromJson(Map<String, dynamic> json) => ExtraAmount(
    amount: json['amount'] as num?,
    extraKms: json['extra_kms'] as num?,
    extraMinutes: json['extra_minutes'] as num?,
  );

  Map<String, dynamic> toJson() => {
    "amount": amount,
    "extra_kms": extraKms,
    "extra_minutes": extraMinutes,
  };
}

class SimpleAmount {
  final num? amount;

  SimpleAmount({this.amount});

  factory SimpleAmount.fromJson(Map<String, dynamic> json) =>
      SimpleAmount(amount: json['amount'] as num?);

  Map<String, dynamic> toJson() => {"amount": amount};
}
