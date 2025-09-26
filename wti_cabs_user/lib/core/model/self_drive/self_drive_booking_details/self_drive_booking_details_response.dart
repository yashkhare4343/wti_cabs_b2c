class SelfDriveBookingDetailsResponse {
  final bool? success;
  final String? message;
  final num? statusCode;
  final InventoryResult? result;

  SelfDriveBookingDetailsResponse({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory SelfDriveBookingDetailsResponse.fromJson(Map<String, dynamic> json) {
    return SelfDriveBookingDetailsResponse(
      success: json['success'],
      message: json['message'],
      statusCode: json['statusCode'],
      result: json['result'] != null
          ? InventoryResult.fromJson(json['result'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "statusCode": statusCode,
    "result": result?.toJson(),
  };
}

class InventoryResult {
  final Vehicle? vehicleId;
  final List<Tariff>? tarrifs;
  final num? minimumRentalDays;
  final String? currency;
  final num? discountPercentage;
  final num? overrunCostPerKm;
  final num? insuranceCharge;
  final num? totalSecurityDeposit;
  final List<Extra>? extras;
  final String? tarrifSelected;
  final String? reqResId;

  InventoryResult({
    this.vehicleId,
    this.tarrifs,
    this.minimumRentalDays,
    this.currency,
    this.discountPercentage,
    this.overrunCostPerKm,
    this.insuranceCharge,
    this.totalSecurityDeposit,
    this.extras,
    this.tarrifSelected,
    this.reqResId,
  });

  factory InventoryResult.fromJson(Map<String, dynamic> json) {
    return InventoryResult(
      vehicleId:
      json['vehicle_id'] != null ? Vehicle.fromJson(json['vehicle_id']) : null,
      tarrifs: (json['tarrifs'] as List?)
          ?.map((e) => Tariff.fromJson(e))
          .toList(),
      minimumRentalDays: json['minimumRentalDays'],
      currency: json['currency'],
      discountPercentage: json['discount_percentage'],
      overrunCostPerKm: json['overrun_cost_per_km'],
      insuranceCharge: json['insurance_charge'],
      totalSecurityDeposit: json['total_security_deposit'],
      extras:
      (json['extras'] as List?)?.map((e) => Extra.fromJson(e)).toList(),
      tarrifSelected: json['tarrif_selected'],
      reqResId: json['reqResId'],
    );
  }

  Map<String, dynamic> toJson() => {
    "vehicle_id": vehicleId?.toJson(),
    "tarrifs": tarrifs?.map((e) => e.toJson()).toList(),
    "minimumRentalDays": minimumRentalDays,
    "currency": currency,
    "discount_percentage": discountPercentage,
    "overrun_cost_per_km": overrunCostPerKm,
    "insurance_charge": insuranceCharge,
    "total_security_deposit": totalSecurityDeposit,
    "extras": extras?.map((e) => e.toJson()).toList(),
    "tarrif_selected": tarrifSelected,
    "reqResId": reqResId,
  };
}

class Vehicle {
  final String? id;
  final String? modelName;
  final List<Spec>? specs;
  final num? vehicleRating;
  final bool? isActive;
  final List<String>? images;

  Vehicle({
    this.id,
    this.modelName,
    this.specs,
    this.vehicleRating,
    this.isActive,
    this.images,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'],
      modelName: json['model_name'],
      specs: (json['specs'] as List?)?.map((e) => Spec.fromJson(e)).toList(),
      vehicleRating: json['vehicle_rating'],
      isActive: json['isActive'],
      images: (json['images'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "model_name": modelName,
    "specs": specs?.map((e) => e.toJson()).toList(),
    "vehicle_rating": vehicleRating,
    "isActive": isActive,
    "images": images,
  };
}

class Spec {
  final String? label;
  final dynamic value; // can be String, num, bool

  Spec({this.label, this.value});

  factory Spec.fromJson(Map<String, dynamic> json) {
    return Spec(
      label: json['label'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() => {
    "label": label,
    "value": value,
  };
}

class Tariff {
  final num? duration;
  final num? base;
  final num? mileageLimit;
  final bool? isMileageUnlimited;
  final num? partialSecurityDeposit;
  final num? hikePercentage;
  final PickupDrop? pickup;
  final PickupDrop? drop;
  final String? tariffType;
  final FareDetails? fareDetails;
  final num? collisionDamageWaiver;
  final num? parsonalAccidentalInsurance;
  final SecurityDeposit? securityDeposit;

  Tariff({
    this.duration,
    this.base,
    this.mileageLimit,
    this.isMileageUnlimited,
    this.partialSecurityDeposit,
    this.hikePercentage,
    this.pickup,
    this.drop,
    this.tariffType,
    this.fareDetails,
    this.collisionDamageWaiver,
    this.parsonalAccidentalInsurance,
    this.securityDeposit,
  });

  factory Tariff.fromJson(Map<String, dynamic> json) {
    return Tariff(
      duration: json['duration'],
      base: json['base'],
      mileageLimit: json['mileage_limit'],
      isMileageUnlimited: json['is_mileage_unlimited'],
      partialSecurityDeposit: json['partial_security_deposit'],
      hikePercentage: json['hikePercentage'],
      pickup: json['pickup'] != null ? PickupDrop.fromJson(json['pickup']) : null,
      drop: json['drop'] != null ? PickupDrop.fromJson(json['drop']) : null,
      tariffType: json['tariff_type'],
      fareDetails: json['fare_Details'] != null
          ? FareDetails.fromJson(json['fare_Details'])
          : null,
      collisionDamageWaiver: json['collision_damage_waiver'],
      parsonalAccidentalInsurance: json['parsonal_accidental_insurance'],
      securityDeposit: json['security_deposit'] != null
          ? SecurityDeposit.fromJson(json['security_deposit'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "duration": duration,
    "base": base,
    "mileage_limit": mileageLimit,
    "is_mileage_unlimited": isMileageUnlimited,
    "partial_security_deposit": partialSecurityDeposit,
    "hikePercentage": hikePercentage,
    "pickup": pickup?.toJson(),
    "drop": drop?.toJson(),
    "tariff_type": tariffType,
    "fare_Details": fareDetails?.toJson(),
    "collision_damage_waiver": collisionDamageWaiver,
    "parsonal_accidental_insurance": parsonalAccidentalInsurance,
    "security_deposit": securityDeposit?.toJson(),
  };
}

class PickupDrop {
  final String? date;
  final String? time;

  PickupDrop({this.date, this.time});

  factory PickupDrop.fromJson(Map<String, dynamic> json) {
    return PickupDrop(
      date: json['date'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() => {
    "date": date,
    "time": time,
  };
}

class FareDetails {
  final num? baseFare;
  final num? refundableDeposit;
  final num? total;
  final num? tax;
  final num? grandTotal;

  FareDetails({
    this.baseFare,
    this.refundableDeposit,
    this.total,
    this.tax,
    this.grandTotal,
  });

  factory FareDetails.fromJson(Map<String, dynamic> json) {
    return FareDetails(
      baseFare: json['base_fare'],
      refundableDeposit: json['Refundable_Deposit'],
      total: json['total'],
      tax: json['tax'],
      grandTotal: json['grand_total'],
    );
  }

  Map<String, dynamic> toJson() => {
    "base_fare": baseFare,
    "Refundable_Deposit": refundableDeposit,
    "total": total,
    "tax": tax,
    "grand_total": grandTotal,
  };
}

class SecurityDeposit {
  final String? name;
  final num? amount;

  SecurityDeposit({this.name, this.amount});

  factory SecurityDeposit.fromJson(Map<String, dynamic> json) {
    return SecurityDeposit(
      name: json['name'],
      amount: json['amount'],
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "amount": amount,
  };
}

class Extra {
  final String? id;
  final String? country;
  final num? extraId;
  final String? name;
  final String? title;
  final String? img;
  final String? description;
  final String? price;
  final String? baseCurrency;
  final bool? isActive;

  Extra({
    this.id,
    this.country,
    this.extraId,
    this.name,
    this.title,
    this.img,
    this.description,
    this.price,
    this.baseCurrency,
    this.isActive,
  });

  factory Extra.fromJson(Map<String, dynamic> json) {
    return Extra(
      id: json['_id'],
      country: json['country'],
      extraId: json['id'],
      name: json['name'],
      title: json['title'],
      img: json['img'],
      description: json['description'],
      price: json['price'],
      baseCurrency: json['baseCurrency'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "country": country,
    "id": extraId,
    "name": name,
    "title": title,
    "img": img,
    "description": description,
    "price": price,
    "baseCurrency": baseCurrency,
    "isActive": isActive,
  };
}
