class IndiaCabBooking {
  final bool? success;
  final Inventory? inventory;
  final OfferObject? offerObject;
  final TripType? tripType;
  final String? message;

  IndiaCabBooking({
    this.success,
    this.inventory,
    this.offerObject,
    this.tripType,
    this.message,
  });

  factory IndiaCabBooking.fromJson(Map<String, dynamic> json) {
    return IndiaCabBooking(
      success: json['success'] as bool?,
      inventory: json['inventory'] != null ? Inventory.fromJson(json['inventory']) : null,
      offerObject: json['offerObject'] != null ? OfferObject.fromJson(json['offerObject']) : null,
      tripType: json['tripType'] != null ? TripType.fromJson(json['tripType']) : null,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'inventory': inventory?.toJson(),
      'offerObject': offerObject?.toJson(),
      'tripType': tripType?.toJson(),
      'message': message,
    };
  }
}

class Inventory {
  final num? distanceBooked;
  final DateTime? startTime;
  final String? fleetId;
  final String? skuId;
  final Source? source;
  final String? type;
  final String? combustionType;
  final num? baseKm;
  final String? model;
  final String? tripType;
  final List<ExtrasIdArray>? extrasIdArray;
  final Rating? rating;
  final num? seats;
  final String? luggageCapacity;
  final String? carTagLine;
  final num? fakePercentageOff;
  final String? carImageUrl;
  final List<VehicleAmenity>? vehicleAmenities;
  final InclusionExclusionCharges? inclusionExclusionCharges;
  final String? reqResIdVehicleDetails;
  final CarTypes? carTypes;
  final String? communicationType;
  final bool? isInstantAvailable;
  final bool? isPartPaymentAllowed;
  final String? verificationType;

  Inventory({
    this.distanceBooked,
    this.startTime,
    this.fleetId,
    this.skuId,
    this.source,
    this.type,
    this.combustionType,
    this.baseKm,
    this.model,
    this.tripType,
    this.extrasIdArray,
    this.rating,
    this.seats,
    this.luggageCapacity,
    this.carTagLine,
    this.fakePercentageOff,
    this.carImageUrl,
    this.vehicleAmenities,
    this.inclusionExclusionCharges,
    this.reqResIdVehicleDetails,
    this.carTypes,
    this.communicationType,
    this.isInstantAvailable,
    this.isPartPaymentAllowed,
    this.verificationType,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      distanceBooked: json['distance_booked'] as num?,
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      fleetId: json['fleet_id'] as String?,
      skuId: json['sku_id'] as String?,
      source: json['source'] != null ? Source.fromJson(json['source']) : null,
      type: json['type'] as String?,
      combustionType: json['combustion_type'] as String?,
      baseKm: json['base_km'] as num?,
      model: json['model'] as String?,
      tripType: json['trip_type'] as String?,
      extrasIdArray: json['extrasIdArray'] != null
          ? (json['extrasIdArray'] as List).map((e) => ExtrasIdArray.fromJson(e)).toList()
          : null,
      rating: json['rating'] != null ? Rating.fromJson(json['rating']) : null,
      seats: json['seats'] as num?,
      luggageCapacity: json['luggageCapacity'] as String?,
      carTagLine: json['carTagLine'] as String?,
      fakePercentageOff: json['fakePercentageOff'] as num?,
      carImageUrl: json['carImageUrl'] as String?,
      vehicleAmenities: json['vehicleAmenities'] != null
          ? (json['vehicleAmenities'] as List).map((e) => VehicleAmenity.fromJson(e)).toList()
          : null,
      inclusionExclusionCharges: json['inclusionExclusionCharges'] != null
          ? InclusionExclusionCharges.fromJson(json['inclusionExclusionCharges'])
          : null,
      reqResIdVehicleDetails: json['reqResId_vehicle_details'] as String?,
      carTypes: json['car_types'] != null ? CarTypes.fromJson(json['car_types']) : null,
      communicationType: json['communication_type'] as String?,
      isInstantAvailable: json['is_instant_available'] as bool?,
      isPartPaymentAllowed: json['is_part_payment_allowed'] as bool?,
      verificationType: json['verification_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance_booked': distanceBooked,
      'start_time': startTime?.toIso8601String(),
      'fleet_id': fleetId,
      'sku_id': skuId,
      'source': source?.toJson(),
      'type': type,
      'combustion_type': combustionType,
      'base_km': baseKm,
      'model': model,
      'trip_type': tripType,
      'extrasIdArray': extrasIdArray?.map((e) => e.toJson()).toList(),
      'rating': rating?.toJson(),
      'seats': seats,
      'luggageCapacity': luggageCapacity,
      'carTagLine': carTagLine,
      'fakePercentageOff': fakePercentageOff,
      'carImageUrl': carImageUrl,
      'vehicleAmenities': vehicleAmenities?.map((e) => e.toJson()).toList(),
      'inclusionExclusionCharges': inclusionExclusionCharges?.toJson(),
      'reqResId_vehicle_details': reqResIdVehicleDetails,
      'car_types': carTypes?.toJson(),
      'communication_type': communicationType,
      'is_instant_available': isInstantAvailable,
      'is_part_payment_allowed': isPartPaymentAllowed,
      'verification_type': verificationType,
    };
  }
}

class CarTypes {
  final Amenities? amenities;
  final num? baseKm;
  final String? cancellationRule;
  final String? carImageUrl;
  final bool? carrier;
  final String? carTagLine;
  final String? combustionType;
  final List<ExtrasIdArray>? extrasIdArray;
  final num? fakePercentageOff;
  final FareDetails? fareDetails;
  final String? fleetId;
  final String? packageId;
  final bool? isActive;
  final String? luggageCapacity;
  final String? makeYearType;
  final String? model;
  final bool? pet;
  final Rating? rating;
  final num? seats;
  final String? skuId;
  final Source? source;
  final String? subcategory;
  final String? tripType;
  final String? type;

  CarTypes({
    this.amenities,
    this.baseKm,
    this.cancellationRule,
    this.carImageUrl,
    this.carrier,
    this.carTagLine,
    this.combustionType,
    this.extrasIdArray,
    this.fakePercentageOff,
    this.fareDetails,
    this.fleetId,
    this.packageId,
    this.isActive,
    this.luggageCapacity,
    this.makeYearType,
    this.model,
    this.pet,
    this.rating,
    this.seats,
    this.skuId,
    this.source,
    this.subcategory,
    this.tripType,
    this.type,
  });

  factory CarTypes.fromJson(Map<String, dynamic> json) {
    return CarTypes(
      amenities: json['amenities'] != null ? Amenities.fromJson(json['amenities']) : null,
      baseKm: json['base_km'] as num?,
      cancellationRule: json['cancellation_rule'] as String?,
      carImageUrl: json['carImageUrl'] as String?,
      carrier: json['carrier'] as bool?,
      carTagLine: json['carTagLine'] as String?,
      combustionType: json['combustion_type'] as String?,
      extrasIdArray: json['extrasIdArray'] != null
          ? (json['extrasIdArray'] as List).map((e) => ExtrasIdArray.fromJson(e)).toList()
          : null,
      fakePercentageOff: json['fakePercentageOff'] as num?,
      fareDetails: json['fare_details'] != null ? FareDetails.fromJson(json['fare_details']) : null,
      fleetId: json['fleet_id'] as String?,
      packageId: json['package_id'] as String?,
      isActive: json['isActive'] as bool?,
      luggageCapacity: json['luggageCapacity'] as String?,
      makeYearType: json['make_year_type'] as String?,
      model: json['model'] as String?,
      pet: json['pet'] as bool?,
      rating: json['rating'] != null ? Rating.fromJson(json['rating']) : null,
      seats: json['seats'] as num?,
      skuId: json['sku_id'] as String?,
      source: json['source'] != null ? Source.fromJson(json['source']) : null,
      subcategory: json['subcategory'] as String?,
      tripType: json['trip_type'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amenities': amenities?.toJson(),
      'base_km': baseKm,
      'cancellation_rule': cancellationRule,
      'carImageUrl': carImageUrl,
      'carrier': carrier,
      'carTagLine': carTagLine,
      'combustion_type': combustionType,
      'extrasIdArray': extrasIdArray?.map((e) => e.toJson()).toList(),
      'fakePercentageOff': fakePercentageOff,
      'fare_details': fareDetails?.toJson(),
      'fleet_id': fleetId,
      'package_id': packageId,
      'isActive': isActive,
      'luggageCapacity': luggageCapacity,
      'make_year_type': makeYearType,
      'model': model,
      'pet': pet,
      'rating': rating?.toJson(),
      'seats': seats,
      'sku_id': skuId,
      'source': source?.toJson(),
      'subcategory': subcategory,
      'trip_type': tripType,
      'type': type,
    };
  }
}

class Amenities {
  final Features? features;

  Amenities({this.features});

  factory Amenities.fromJson(Map<String, dynamic> json) {
    return Amenities(
      features: json['features'] != null ? Features.fromJson(json['features']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'features': features?.toJson(),
    };
  }
}

class Features {
  final List<String>? driver;
  final List<String>? services;
  final List<String>? vehicle;
  final List<String>? vehicleIcons;

  Features({
    this.driver,
    this.services,
    this.vehicle,
    this.vehicleIcons,
  });

  factory Features.fromJson(Map<String, dynamic> json) {
    return Features(
      driver: json['driver'] != null ? List<String>.from(json['driver']) : null,
      services: json['services'] != null ? List<String>.from(json['services']) : null,
      vehicle: json['vehicle'] != null ? List<String>.from(json['vehicle']) : null,
      vehicleIcons: json['vehicle_icons'] != null ? List<String>.from(json['vehicle_icons']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver': driver,
      'services': services,
      'vehicle': vehicle,
      'vehicle_icons': vehicleIcons,
    };
  }
}

class ExtrasIdArray {
  final Price? price;
  final String? id;
  final String? title;
  final String? description;

  ExtrasIdArray({
    this.price,
    this.id,
    this.title,
    this.description,
  });

  factory ExtrasIdArray.fromJson(Map<String, dynamic> json) {
    return ExtrasIdArray(
      price: json['price'] != null ? Price.fromJson(json['price']) : null,
      id: json['_id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price?.toJson(),
      '_id': id,
      'title': title,
      'description': description,
    };
  }
}

class Price {
  final num? daily;
  final num? maximum;

  Price({this.daily, this.maximum});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      daily: json['daily'] as num?,
      maximum: json['maximum'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily': daily,
      'maximum': maximum,
    };
  }
}

class FareDetails {
  final num? baseFare;
  final ExtraCharges? extraCharges;
  final ExtraTimeFare? extraTimeFare;
  final num? perKmCharge;
  final num? perKmExtraCharge;
  final num? sellerDiscount;
  final num? totalDriverCharges;

  FareDetails({
    this.baseFare,
    this.extraCharges,
    this.extraTimeFare,
    this.perKmCharge,
    this.perKmExtraCharge,
    this.sellerDiscount,
    this.totalDriverCharges,
  });

  factory FareDetails.fromJson(Map<String, dynamic> json) {
    return FareDetails(
      baseFare: json['base_fare'] as num?,
      extraCharges: json['extra_charges'] != null ? ExtraCharges.fromJson(json['extra_charges']) : null,
      extraTimeFare: json['extra_time_fare'] != null ? ExtraTimeFare.fromJson(json['extra_time_fare']) : null,
      perKmCharge: json['per_km_charge'] as num?,
      perKmExtraCharge: json['per_km_extra_charge'] as num?,
      sellerDiscount: json['seller_discount'] as num?,
      totalDriverCharges: json['total_driver_charges'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_fare': baseFare,
      'extra_charges': extraCharges?.toJson(),
      'extra_time_fare': extraTimeFare?.toJson(),
      'per_km_charge': perKmCharge,
      'per_km_extra_charge': perKmExtraCharge,
      'seller_discount': sellerDiscount,
      'total_driver_charges': totalDriverCharges,
    };
  }
}

class ExtraCharges {
  final NightCharges? nightCharges;
  final ParkingCharges? parkingCharges;
  final StateTax? stateTax;
  final TollCharges? tollCharges;
  final WaitingCharges? waitingCharges;

  ExtraCharges({
    this.nightCharges,
    this.parkingCharges,
    this.stateTax,
    this.tollCharges,
    this.waitingCharges,
  });

  factory ExtraCharges.fromJson(Map<String, dynamic> json) {
    return ExtraCharges(
      nightCharges: json['night_charges'] != null ? NightCharges.fromJson(json['night_charges']) : null,
      parkingCharges: json['parking_charges'] != null ? ParkingCharges.fromJson(json['parking_charges']) : null,
      stateTax: json['state_tax'] != null ? StateTax.fromJson(json['state_tax']) : null,
      tollCharges: json['toll_charges'] != null ? TollCharges.fromJson(json['toll_charges']) : null,
      waitingCharges: json['waiting_charges'] != null ? WaitingCharges.fromJson(json['waiting_charges']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'night_charges': nightCharges?.toJson(),
      'parking_charges': parkingCharges?.toJson(),
      'state_tax': stateTax?.toJson(),
      'toll_charges': tollCharges?.toJson(),
      'waiting_charges': waitingCharges?.toJson(),
    };
  }
}

class NightCharges {
  final num? amount;
  final num? applicableTimeFrom;
  final num? applicableTimeTill;
  final bool? isApplicable;
  final bool? isIncludedInBaseFare;
  final bool? isIncludedInGrandTotal;

  NightCharges({
    this.amount,
    this.applicableTimeFrom,
    this.applicableTimeTill,
    this.isApplicable,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
  });

  factory NightCharges.fromJson(Map<String, dynamic> json) {
    return NightCharges(
      amount: json['amount'] as num?,
      applicableTimeFrom: json['applicable_time_from'] as num?,
      applicableTimeTill: json['applicable_time_till'] as num?,
      isApplicable: json['is_applicable'] as bool?,
      isIncludedInBaseFare: json['is_included_in_base_fare'] as bool?,
      isIncludedInGrandTotal: json['is_included_in_grand_total'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'applicable_time_from': applicableTimeFrom,
      'applicable_time_till': applicableTimeTill,
      'is_applicable': isApplicable,
      'is_included_in_base_fare': isIncludedInBaseFare,
      'is_included_in_grand_total': isIncludedInGrandTotal,
    };
  }
}

class ParkingCharges {
  final num? amount;
  final bool? isApplicable;
  final bool? isIncludedInBaseFare;
  final bool? isIncludedInGrandTotal;

  ParkingCharges({
    this.amount,
    this.isApplicable,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
  });

  factory ParkingCharges.fromJson(Map<String, dynamic> json) {
    return ParkingCharges(
      amount: json['amount'] as num?,
      isApplicable: json['is_applicable'] as bool?,
      isIncludedInBaseFare: json['is_included_in_base_fare'] as bool?,
      isIncludedInGrandTotal: json['is_included_in_grand_total'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'is_applicable': isApplicable,
      'is_included_in_base_fare': isIncludedInBaseFare,
      'is_included_in_grand_total': isIncludedInGrandTotal,
    };
  }
}

class StateTax {
  final num? amount;
  final bool? isApplicable;
  final bool? isIncludedInBaseFare;
  final bool? isIncludedInGrandTotal;

  StateTax({
    this.amount,
    this.isApplicable,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
  });

  factory StateTax.fromJson(Map<String, dynamic> json) {
    return StateTax(
      amount: json['amount'] as num?,
      isApplicable: json['is_applicable'] as bool?,
      isIncludedInBaseFare: json['is_included_in_base_fare'] as bool?,
      isIncludedInGrandTotal: json['is_included_in_grand_total'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'is_applicable': isApplicable,
      'is_included_in_base_fare': isIncludedInBaseFare,
      'is_included_in_grand_total': isIncludedInGrandTotal,
    };
  }
}

class TollCharges {
  final num? amount;
  final bool? isApplicable;
  final bool? isIncludedInBaseFare;
  final bool? isIncludedInGrandTotal;

  TollCharges({
    this.amount,
    this.isApplicable,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
  });

  factory TollCharges.fromJson(Map<String, dynamic> json) {
    return TollCharges(
      amount: json['amount'] as num?,
      isApplicable: json['is_applicable'] as bool?,
      isIncludedInBaseFare: json['is_included_in_base_fare'] as bool?,
      isIncludedInGrandTotal: json['is_included_in_grand_total'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'is_applicable': isApplicable,
      'is_included_in_base_fare': isIncludedInBaseFare,
      'is_included_in_grand_total': isIncludedInGrandTotal,
    };
  }
}

class WaitingCharges {
  final num? amount;
  final num? applicableTime;
  final num? freeWaitingTime;
  final bool? isApplicable;
  final bool? isIncludedInBaseFare;
  final bool? isIncludedInGrandTotal;

  WaitingCharges({
    this.amount,
    this.applicableTime,
    this.freeWaitingTime,
    this.isApplicable,
    this.isIncludedInBaseFare,
    this.isIncludedInGrandTotal,
  });

  factory WaitingCharges.fromJson(Map<String, dynamic> json) {
    return WaitingCharges(
      amount: json['amount'] as num?,
      applicableTime: json['applicable_time'] as num?,
      freeWaitingTime: json['free_waiting_time'] as num?,
      isApplicable: json['is_applicable'] as bool?,
      isIncludedInBaseFare: json['is_included_in_base_fare'] as bool?,
      isIncludedInGrandTotal: json['is_included_in_grand_total'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'applicable_time': applicableTime,
      'free_waiting_time': freeWaitingTime,
      'is_applicable': isApplicable,
      'is_included_in_base_fare': isIncludedInBaseFare,
      'is_included_in_grand_total': isIncludedInGrandTotal,
    };
  }
}

class ExtraTimeFare {
  final num? applicableTime;
  final num? rate;

  ExtraTimeFare({this.applicableTime, this.rate});

  factory ExtraTimeFare.fromJson(Map<String, dynamic> json) {
    return ExtraTimeFare(
      applicableTime: json['applicable_time'] as num?,
      rate: json['rate'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicable_time': applicableTime,
      'rate': rate,
    };
  }
}

class Rating {
  final num? ratePoints;
  final String? tag;

  Rating({this.ratePoints, this.tag});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      ratePoints: json['ratePoints'] as num?,
      tag: json['tag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ratePoints': ratePoints,
      'tag': tag,
    };
  }
}

class Source {
  final String? address;
  final num? latitude;
  final num? longitude;
  final String? city;
  final String? state;
  final String? country;

  Source({
    this.address,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      address: json['address'] as String?,
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
    };
  }
}

class OfferObject {
  final bool? applicable;
  final String? message;

  OfferObject({this.applicable, this.message});

  factory OfferObject.fromJson(Map<String, dynamic> json) {
    return OfferObject(
      applicable: json['applicable'] as bool?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicable': applicable,
      'message': message,
    };
  }
}

class TripType {
  final bool? isGlobal;
  final String? country;
  final String? routeInventoryId;
  final String? vehicleId;
  final String? tripType;
  final DateTime? pickUpDateTime;
  final DateTime? dropDateTime;
  final num? totalKilometers;
  final TripTypeDetails? tripTypeDetails;
  final String? packageId;
  final Source? source;
  final Destination? destination;
  final String? tripCode;
  final String? comingFrom;
  final String? previousTripCode;
  final String? currentTripCode;

  TripType({
    this.isGlobal,
    this.country,
    this.routeInventoryId,
    this.vehicleId,
    this.tripType,
    this.pickUpDateTime,
    this.dropDateTime,
    this.totalKilometers,
    this.tripTypeDetails,
    this.packageId,
    this.source,
    this.destination,
    this.tripCode,
    this.comingFrom,
    this.previousTripCode,
    this.currentTripCode,
  });

  factory TripType.fromJson(Map<String, dynamic> json) {
    return TripType(
      isGlobal: json['isGlobal'] as bool?,
      country: json['country'] as String?,
      routeInventoryId: json['routeInventoryId'] as String?,
      vehicleId: json['vehicleId'] as String?,
      tripType: json['trip_type'] as String?,
      pickUpDateTime: json['pickUpDateTime'] != null ? DateTime.parse(json['pickUpDateTime']) : null,
      dropDateTime: json['dropDateTime'] != null ? DateTime.parse(json['dropDateTime']) : null,
      totalKilometers: json['totalKilometers'] as num?,
      tripTypeDetails: json['trip_type_details'] != null ? TripTypeDetails.fromJson(json['trip_type_details']) : null,
      packageId: json['package_id'] as String?,
      source: json['source'] != null ? Source.fromJson(json['source']) : null,
      destination: json['destination'] != null ? Destination.fromJson(json['destination']) : null,
      tripCode: json['tripCode'] as String?,
      comingFrom: json['comingFrom'] as String?,
      previousTripCode: json['previousTripCode'] as String?,
      currentTripCode: json['currentTripCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isGlobal': isGlobal,
      'country': country,
      'routeInventoryId': routeInventoryId,
      'vehicleId': vehicleId,
      'trip_type': tripType,
      'pickUpDateTime': pickUpDateTime?.toIso8601String(),
      'dropDateTime': dropDateTime?.toIso8601String(),
      'totalKilometers': totalKilometers,
      'trip_type_details': tripTypeDetails?.toJson(),
      'package_id': packageId,
      'source': source?.toJson(),
      'destination': destination?.toJson(),
      'tripCode': tripCode,
      'comingFrom': comingFrom,
      'previousTripCode': previousTripCode,
      'currentTripCode': currentTripCode,
    };
  }
}

class Destination {
  final String? address;
  final num? latitude;
  final num? longitude;
  final String? city;
  final String? state;
  final String? country;

  Destination({
    this.address,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      address: json['address'] as String?,
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
    };
  }
}

class TripTypeDetails {
  final String? airportType;
  final String? basicTripType;

  TripTypeDetails({this.airportType, this.basicTripType});

  factory TripTypeDetails.fromJson(Map<String, dynamic> json) {
    return TripTypeDetails(
      airportType: json['airport_type'] as String?,
      basicTripType: json['basic_trip_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'airport_type': airportType,
      'basic_trip_type': basicTripType,
    };
  }
}

class VehicleAmenity {
  final String? label;
  final String? icon;

  VehicleAmenity({this.label, this.icon});

  factory VehicleAmenity.fromJson(Map<String, dynamic> json) {
    return VehicleAmenity(
      label: json['label'] as String?,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'icon': icon,
    };
  }
}

class InclusionExclusionCharges {
  final List<ChargeItem>? includedCharges;
  final List<ChargeItem>? excludedCharges;

  InclusionExclusionCharges({this.includedCharges, this.excludedCharges});

  factory InclusionExclusionCharges.fromJson(Map<String, dynamic> json) {
    return InclusionExclusionCharges(
      includedCharges: json['includedCharges'] != null
          ? (json['includedCharges'] as List).map((e) => ChargeItem.fromJson(e)).toList()
          : null,
      excludedCharges: json['excludedCharges'] != null
          ? (json['excludedCharges'] as List).map((e) => ChargeItem.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includedCharges': includedCharges?.map((e) => e.toJson()).toList(),
      'excludedCharges': excludedCharges?.map((e) => e.toJson()).toList(),
    };
  }
}

class ChargeItem {
  final String? type;
  final String? value;
  final num? amount;
  final String? prefix;
  final String? suffix;

  ChargeItem({this.type, this.value, this.amount, this.prefix, this.suffix});

  factory ChargeItem.fromJson(Map<String, dynamic> json) {
    return ChargeItem(
      type: json['type'] as String?,
      value: json['value'] as String?,
      amount: json['amount'] as num?,
      prefix: json['prefix'] as String?,
      suffix: json['suffix'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'amount': amount,
      'prefix': prefix,
      'suffix': suffix,
    };
  }
}

class IndiaFareDetailsResponse {
  final bool? success;
  final FareDetailsResponse? fareDetails;
  final OfferObject? offerObject;

  IndiaFareDetailsResponse({
    this.success,
    this.fareDetails,
    this.offerObject,
  });

  factory IndiaFareDetailsResponse.fromJson(Map<String, dynamic> json) {
    return IndiaFareDetailsResponse(
      success: json['success'] as bool?,
      fareDetails: json['fare_details'] != null
          ? FareDetailsResponse.fromJson(json['fare_details'])
          : null,
      offerObject: json['offerObject'] != null
          ? OfferObject.fromJson(json['offerObject'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'fare_details': fareDetails?.toJson(),
      'offerObject': offerObject?.toJson(),
    };
  }
}

class FareDetailsResponse {
  final num? baseFare;
  final num? totalFare;
  final num? perKmCharge;
  final num? perKmExtraCharge;
  final List<ChargeMapping>? chargeMapping;
  final String? reqResIdFareDetails;

  FareDetailsResponse({
    this.baseFare,
    this.totalFare,
    this.perKmCharge,
    this.perKmExtraCharge,
    this.chargeMapping,
    this.reqResIdFareDetails,
  });

  factory FareDetailsResponse.fromJson(Map<String, dynamic> json) {
    return FareDetailsResponse(
      baseFare: json['base_fare'] as num?,
      totalFare: json['totalFare'] as num?,
      perKmCharge: json['per_km_charge'] as num?,
      perKmExtraCharge: json['per_km_extra_charge'] as num?,
      chargeMapping: json['chargeMapping'] != null
          ? (json['chargeMapping'] as List)
              .map((e) => ChargeMapping.fromJson(e))
              .toList()
          : null,
      reqResIdFareDetails: json['reqResId_fare_details'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_fare': baseFare,
      'totalFare': totalFare,
      'per_km_charge': perKmCharge,
      'per_km_extra_charge': perKmExtraCharge,
      'chargeMapping': chargeMapping?.map((e) => e.toJson()).toList(),
      'reqResId_fare_details': reqResIdFareDetails,
    };
  }
}

class ChargeMapping {
  final String? label;
  final num? amount;

  ChargeMapping({this.label, this.amount});

  factory ChargeMapping.fromJson(Map<String, dynamic> json) {
    return ChargeMapping(
      label: json['label'] as String?,
      amount: json['amount'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'amount': amount,
    };
  }
}