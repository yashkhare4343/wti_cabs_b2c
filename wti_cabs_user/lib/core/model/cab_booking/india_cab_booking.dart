class IndiaCabBooking {
  final Inventory? inventory;
  final OfferObject? offerObject;
  final TripType? tripType;

  IndiaCabBooking({
    this.inventory,
    this.offerObject,
    this.tripType,
  });

  factory IndiaCabBooking.fromJson(Map<String, dynamic> json) {
    return IndiaCabBooking(
      inventory: json['inventory'] != null ? Inventory.fromJson(json['inventory']) : null,
      offerObject: json['offerObject'] != null ? OfferObject.fromJson(json['offerObject']) : null,
      tripType: json['tripType'] != null ? TripType.fromJson(json['tripType']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventory': inventory?.toJson(),
      'offerObject': offerObject?.toJson(),
      'tripType': tripType?.toJson(),
    };
  }
}

class Inventory {
  final CarTypes? carTypes;
  final String? communicationType;
  final num? distanceBooked;
  final bool? isInstantAvailable;
  final bool? isPartPaymentAllowed;
  final DateTime? startTime;
  final String? verificationType;

  Inventory({
    this.carTypes,
    this.communicationType,
    this.distanceBooked,
    this.isInstantAvailable,
    this.isPartPaymentAllowed,
    this.startTime,
    this.verificationType,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      carTypes: json['car_types'] != null ? CarTypes.fromJson(json['car_types']) : null,
      communicationType: json['communication_type'] as String?,
      distanceBooked: json['distance_booked'] as num?,
      isInstantAvailable: json['is_instant_available'] as bool?,
      isPartPaymentAllowed: json['is_part_payment_allowed'] as bool?,
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      verificationType: json['verification_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'car_types': carTypes?.toJson(),
      'communication_type': communicationType,
      'distance_booked': distanceBooked,
      'is_instant_available': isInstantAvailable,
      'is_part_payment_allowed': isPartPaymentAllowed,
      'start_time': startTime?.toIso8601String(),
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
  final num? v;
  final String? id;
  final String? baseCurrency;
  final String? countryName;
  final DateTime? createdAt;
  final String? description;
  final String? driveType;
  final num? idNumber;
  final String? img;
  final bool? isActive;
  final String? name;
  final Price? price;
  final String? title;
  final DateTime? updatedAt;

  ExtrasIdArray({
    this.v,
    this.id,
    this.baseCurrency,
    this.countryName,
    this.createdAt,
    this.description,
    this.driveType,
    this.idNumber,
    this.img,
    this.isActive,
    this.name,
    this.price,
    this.title,
    this.updatedAt,
  });

  factory ExtrasIdArray.fromJson(Map<String, dynamic> json) {
    return ExtrasIdArray(
      v: json['__v'] as num?,
      id: json['_id'] as String?,
      baseCurrency: json['baseCurrency'] as String?,
      countryName: json['countryName'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      description: json['description'] as String?,
      driveType: json['driveType'] as String?,
      idNumber: json['id'] as num?,
      img: json['img'] as String?,
      isActive: json['isActive'] as bool?,
      name: json['name'] as String?,
      price: json['price'] != null ? Price.fromJson(json['price']) : null,
      title: json['title'] as String?,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '__v': v,
      '_id': id,
      'baseCurrency': baseCurrency,
      'countryName': countryName,
      'createdAt': createdAt?.toIso8601String(),
      'description': description,
      'driveType': driveType,
      'id': idNumber,
      'img': img,
      'isActive': isActive,
      'name': name,
      'price': price?.toJson(),
      'title': title,
      'updatedAt': updatedAt?.toIso8601String(),
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
  final String? city;
  final num? latitude;
  final num? longitude;

  Source({
    this.address,
    this.city,
    this.latitude,
    this.longitude,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      address: json['address'] as String?,
      city: json['city'] as String?,
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
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
  final String? country;
  final String? currentTripCode;
  final Destination? destination;
  final DateTime? dropDateTime;
  final bool? isGlobal;
  final String? packageId;
  final DateTime? pickUpDateTime;
  final String? previousTripCode;
  final String? routeInventoryId;
  final Source? source;
  final num? totalKilometers;
  final String? tripType;
  final TripTypeDetails? tripTypeDetails;
  final String? tripCode;
  final String? vehicleId;

  TripType({
    this.country,
    this.currentTripCode,
    this.destination,
    this.dropDateTime,
    this.isGlobal,
    this.packageId,
    this.pickUpDateTime,
    this.previousTripCode,
    this.routeInventoryId,
    this.source,
    this.totalKilometers,
    this.tripType,
    this.tripTypeDetails,
    this.tripCode,
    this.vehicleId,
  });

  factory TripType.fromJson(Map<String, dynamic> json) {
    return TripType(
      country: json['country'] as String?,
      currentTripCode: json['currentTripCode'] as String?,
      destination: json['destination'] != null ? Destination.fromJson(json['destination']) : null,
      dropDateTime: json['dropDateTime'] != null ? DateTime.parse(json['dropDateTime']) : null,
      isGlobal: json['isGlobal'] as bool?,
      packageId: json['package_id'] as String?,
      pickUpDateTime: json['pickUpDateTime'] != null ? DateTime.parse(json['pickUpDateTime']) : null,
      previousTripCode: json['previousTripCode'] as String?,
      routeInventoryId: json['routeInventoryId'] as String?,
      source: json['source'] != null ? Source.fromJson(json['source']) : null,
      totalKilometers: json['totalKilometers'] as num?,
      tripType: json['trip_type'] as String?,
      tripTypeDetails: json['trip_type_details'] != null ? TripTypeDetails.fromJson(json['trip_type_details']) : null,
      tripCode: json['tripCode'] as String?,
      vehicleId: json['vehicleId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'currentTripCode': currentTripCode,
      'destination': destination?.toJson(),
      'dropDateTime': dropDateTime?.toIso8601String(),
      'isGlobal': isGlobal,
      'package_id': packageId,
      'pickUpDateTime': pickUpDateTime?.toIso8601String(),
      'previousTripCode': previousTripCode,
      'routeInventoryId': routeInventoryId,
      'source': source?.toJson(),
      'totalKilometers': totalKilometers,
      'trip_type': tripType,
      'trip_type_details': tripTypeDetails?.toJson(),
      'tripCode': tripCode,
      'vehicleId': vehicleId,
    };
  }
}

class Destination {
  final String? address;
  final String? city;
  final num? latitude;
  final num? longitude;

  Destination({
    this.address,
    this.city,
    this.latitude,
    this.longitude,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      address: json['address'] as String?,
      city: json['city'] as String?,
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
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