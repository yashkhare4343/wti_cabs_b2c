class TopRatedRidesResponse {
  final bool? success;
  final String? message;
  final int? statusCode;
  final List<VehicleResult>? result;

  TopRatedRidesResponse({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory TopRatedRidesResponse.fromJson(Map<String, dynamic> json) {
    return TopRatedRidesResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: (json['result'] as List<dynamic>?)
          ?.map((e) => VehicleResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'statusCode': statusCode,
      'result': result?.map((e) => e.toJson()).toList(),
    };
  }
}

class VehicleResult {
  final VehicleId? vehicleId;
  final String? searchedPlan;
  final int? rentalDays;
  final num? finalPrice;
  final Tariff? tariffDaily;
  final Tariff? tariffWeekly;
  final Tariff? tariffMonthly;
  final int? minimumRentalDays;
  final String? currency;
  final int? discountPercentage;
  final double? overrunCostPerKm;
  final int? insuranceCharge;
  final int? totalSecurityDeposit;

  VehicleResult({
    this.vehicleId,
    this.searchedPlan,
    this.rentalDays,
    this.finalPrice,
    this.tariffDaily,
    this.tariffWeekly,
    this.tariffMonthly,
    this.minimumRentalDays,
    this.currency,
    this.discountPercentage,
    this.overrunCostPerKm,
    this.insuranceCharge,
    this.totalSecurityDeposit,
  });

  factory VehicleResult.fromJson(Map<String, dynamic> json) {
    return VehicleResult(
      vehicleId: json['vehicle_id'] != null
          ? VehicleId.fromJson(json['vehicle_id'])
          : null,
      searchedPlan: json['searchedPlan'] as String?,
      rentalDays: json['rentalDays'] as int?,
      finalPrice: json['finalPrice'] as num?,
      tariffDaily: json['tariff_daily'] != null
          ? Tariff.fromJson(json['tariff_daily'])
          : null,
      tariffWeekly: json['tariff_weekly'] != null
          ? Tariff.fromJson(json['tariff_weekly'])
          : null,
      tariffMonthly: json['tariff_monthly'] != null
          ? Tariff.fromJson(json['tariff_monthly'])
          : null,
      minimumRentalDays: json['minimumRentalDays'] as int?,
      currency: json['currency'] as String?,
      discountPercentage: json['discount_percentage'] as int?,
      overrunCostPerKm: (json['overrun_cost_per_km'] as num?)?.toDouble(),
      insuranceCharge: json['insurance_charge'] as int?,
      totalSecurityDeposit: json['total_security_deposit'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId?.toJson(),
      'searchedPlan': searchedPlan,
      'rentalDays': rentalDays,
      'finalPrice': finalPrice,
      'tariff_daily': tariffDaily?.toJson(),
      'tariff_weekly': tariffWeekly?.toJson(),
      'tariff_monthly': tariffMonthly?.toJson(),
      'minimumRentalDays': minimumRentalDays,
      'currency': currency,
      'discount_percentage': discountPercentage,
      'overrun_cost_per_km': overrunCostPerKm,
      'insurance_charge': insuranceCharge,
      'total_security_deposit': totalSecurityDeposit,
    };
  }
}

class VehicleId {
  final String? id;
  final String? modelName;
  final Specs? specs;
  final int? vehicleRating;
  final String? vehiclePromotionTag;
  final bool? isActive;
  final List<String>? images;

  VehicleId({
    this.id,
    this.modelName,
    this.specs,
    this.vehicleRating,
    this.vehiclePromotionTag,
    this.isActive,
    this.images,
  });

  factory VehicleId.fromJson(Map<String, dynamic> json) {
    return VehicleId(
      id: json['_id'] as String?,
      modelName: json['model_name'] as String?,
      specs: json['specs'] != null ? Specs.fromJson(json['specs']) : null,
      vehicleRating: json['vehicle_rating'] as int?,
      vehiclePromotionTag: json['vehicle_promotion_tag'] as String?,
      isActive: json['isActive'] as bool?,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'model_name': modelName,
      'specs': specs?.toJson(),
      'vehicle_rating': vehicleRating,
      'vehicle_promotion_tag': vehiclePromotionTag,
      'isActive': isActive,
      'images': images,
    };
  }
}

class Specs {
  final String? carClass;
  final String? engineCapacity;
  final int? maxSpeed;
  final int? doors;
  final int? year;
  final String? powerHP;
  final String? transmission;
  final bool? isSimilarCarsTitle;
  final bool? isVerified;
  final bool? isSimilarCars;
  final String? model;
  final int? seats;
  final String? orderNumber;
  final String? driveType;
  final String? exteriorColor;
  final String? manufactory;
  final String? bodyType;
  final String? luggageCapacity;
  final int? mileageLimit;
  final String? id;

  Specs({
    this.carClass,
    this.engineCapacity,
    this.maxSpeed,
    this.doors,
    this.year,
    this.powerHP,
    this.transmission,
    this.isSimilarCarsTitle,
    this.isVerified,
    this.isSimilarCars,
    this.model,
    this.seats,
    this.orderNumber,
    this.driveType,
    this.exteriorColor,
    this.manufactory,
    this.bodyType,
    this.luggageCapacity,
    this.mileageLimit,
    this.id,
  });

  factory Specs.fromJson(Map<String, dynamic> json) {
    return Specs(
      carClass: json['Class'] as String?,
      engineCapacity: json['EngineCapacity'] as String?,
      maxSpeed: json['MaxSpeed'] as int?,
      doors: json['Doors'] as int?,
      year: json['Year'] as int?,
      powerHP: json['PowerHP'] as String?,
      transmission: json['Transmission'] as String?,
      isSimilarCarsTitle: json['IsSimilarCarsTitle'] as bool?,
      isVerified: json['IsVerified'] as bool?,
      isSimilarCars: json['IsSimilarCars'] as bool?,
      model: json['Model'] as String?,
      seats: json['Seats'] as int?,
      orderNumber: json['Order_number'] as String?,
      driveType: json['DriveType'] as String?,
      exteriorColor: json['ExteriorColor'] as String?,
      manufactory: json['Manufactory'] as String?,
      bodyType: json['BodyType'] as String?,
      luggageCapacity: json['LuggageCapacity'] as String?,
      mileageLimit: json['mileage_limit'] as int?,
      id: json['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Class': carClass,
      'EngineCapacity': engineCapacity,
      'MaxSpeed': maxSpeed,
      'Doors': doors,
      'Year': year,
      'PowerHP': powerHP,
      'Transmission': transmission,
      'IsSimilarCarsTitle': isSimilarCarsTitle,
      'IsVerified': isVerified,
      'IsSimilarCars': isSimilarCars,
      'Model': model,
      'Seats': seats,
      'Order_number': orderNumber,
      'DriveType': driveType,
      'ExteriorColor': exteriorColor,
      'Manufactory': manufactory,
      'BodyType': bodyType,
      'LuggageCapacity': luggageCapacity,
      'mileage_limit': mileageLimit,
      '_id': id,
    };
  }
}

class Tariff {
  final int? duration;
  final int? base;
  final int? mileageLimit;
  final bool? isMileageUnlimited;
  final int? partialSecurityDeposit;
  final int? hikePercentage;

  Tariff({
    this.duration,
    this.base,
    this.mileageLimit,
    this.isMileageUnlimited,
    this.partialSecurityDeposit,
    this.hikePercentage,
  });

  factory Tariff.fromJson(Map<String, dynamic> json) {
    return Tariff(
      duration: json['duration'] as int?,
      base: json['base'] as int?,
      mileageLimit: json['mileage_limit'] as int?,
      isMileageUnlimited: json['is_mileage_unlimited'] as bool?,
      partialSecurityDeposit: json['partial_security_deposit'] as int?,
      hikePercentage: json['hikePercentage'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'base': base,
      'mileage_limit': mileageLimit,
      'is_mileage_unlimited': isMileageUnlimited,
      'partial_security_deposit': partialSecurityDeposit,
      'hikePercentage': hikePercentage,
    };
  }
}
