import 'package:wti_cabs_user/core/model/booking_engine/suggestions_places_response.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_payment_method/crp_payment_mode.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_gender_response/crp_gender_response.dart';
import 'package:wti_cabs_user/core/model/corporate/crp_car_provider_response/crp_car_provider_response.dart';

class CrpBookingData {
  final SuggestionPlacesResponse? pickupPlace;
  final SuggestionPlacesResponse? dropPlace;
  final DateTime? pickupDateTime;
  final DateTime? dropDateTime;
  final String? pickupType; // Selected pickup type/run type
  final String? bookingType; // Myself or Corporate
  final PaymentModeItem? paymentMode;
  final String? referenceNumber;
  final String? specialInstruction;
  final String? costCode;
  final String? flightDetails;
  final GenderModel? gender;
  final CarProviderModel? carProvider;
  final int? selectedTabIndex; // For tabs (when run types <= 3)
  final int? entityId; // Selected corporate entity ID

  CrpBookingData({
    this.pickupPlace,
    this.dropPlace,
    this.pickupDateTime,
    this.dropDateTime,
    this.pickupType,
    this.bookingType,
    this.paymentMode,
    this.referenceNumber,
    this.specialInstruction,
    this.costCode,
    this.flightDetails,
    this.gender,
    this.carProvider,
    this.selectedTabIndex,
    this.entityId,
  });

  Map<String, dynamic> toJson() {
    return {
      'pickupPlace': pickupPlace != null ? {
        'primary_text': pickupPlace!.primaryText,
        'secondary_text': pickupPlace!.secondaryText,
        'place_id': pickupPlace!.placeId,
        'types': pickupPlace!.types,
        'terms': pickupPlace!.terms.map((e) => e.toJson()).toList(),
        'city': pickupPlace!.city,
        'state': pickupPlace!.state,
        'country': pickupPlace!.country,
        'isAirport': pickupPlace!.isAirport,
        'latitude': pickupPlace!.latitude,
        'longitude': pickupPlace!.longitude,
        'place_name': pickupPlace!.placeName,
      } : null,
      'dropPlace': dropPlace != null ? {
        'primary_text': dropPlace!.primaryText,
        'secondary_text': dropPlace!.secondaryText,
        'place_id': dropPlace!.placeId,
        'types': dropPlace!.types,
        'terms': dropPlace!.terms.map((e) => e.toJson()).toList(),
        'city': dropPlace!.city,
        'state': dropPlace!.state,
        'country': dropPlace!.country,
        'isAirport': dropPlace!.isAirport,
        'latitude': dropPlace!.latitude,
        'longitude': dropPlace!.longitude,
        'place_name': dropPlace!.placeName,
      } : null,
      'pickupDateTime': pickupDateTime?.toIso8601String(),
      'dropDateTime': dropDateTime?.toIso8601String(),
      'pickupType': pickupType,
      'bookingType': bookingType,
      'paymentMode': paymentMode?.toJson(),
      'referenceNumber': referenceNumber,
      'specialInstruction': specialInstruction,
      'costCode': costCode,
      'flightDetails': flightDetails,
      'gender': gender != null ? {
        'genderID': gender!.genderID,
        'gender': gender!.gender,
      } : null,
      'carProvider': carProvider != null ? {
        'providerID': carProvider!.providerID,
        'providerName': carProvider!.providerName,
      } : null,
      'selectedTabIndex': selectedTabIndex,
      'entityId': entityId,
    };
  }

  factory CrpBookingData.fromJson(Map<String, dynamic> json) {
    return CrpBookingData(
      pickupPlace: json['pickupPlace'] != null
          ? SuggestionPlacesResponse.fromJson(json['pickupPlace'])
          : null,
      dropPlace: json['dropPlace'] != null
          ? SuggestionPlacesResponse.fromJson(json['dropPlace'])
          : null,
      pickupDateTime: json['pickupDateTime'] != null
          ? DateTime.parse(json['pickupDateTime'])
          : null,
      dropDateTime: json['dropDateTime'] != null
          ? DateTime.parse(json['dropDateTime'])
          : null,
      pickupType: json['pickupType'] as String?,
      bookingType: json['bookingType'] as String?,
      paymentMode: json['paymentMode'] != null
          ? PaymentModeItem.fromJson(json['paymentMode'])
          : null,
      referenceNumber: json['referenceNumber'] as String?,
      specialInstruction: json['specialInstruction'] as String?,
      costCode: json['costCode'] as String?,
      flightDetails: json['flightDetails'] as String?,
      gender: json['gender'] != null && json['gender'] is Map
          ? GenderModel.fromJson(json['gender'] as Map<String, dynamic>)
          : null,
      carProvider: json['carProvider'] != null && json['carProvider'] is Map
          ? CarProviderModel.fromJson(json['carProvider'] as Map<String, dynamic>)
          : null,
      selectedTabIndex: json['selectedTabIndex'] as int?,
      entityId: json['entityId'] as int?,
    );
  }
}

