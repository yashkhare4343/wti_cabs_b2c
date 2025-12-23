import 'dart:convert';

CrpCarModelsResponse crpCarModelsResponseFromJson(String str) =>
    CrpCarModelsResponse.fromJson(jsonDecode(str));

String crpCarModelsResponseToJson(CrpCarModelsResponse data) =>
    jsonEncode(data.toJson());

class CrpCarModelsResponse {
  final bool? bStatus;
  final String? sMessage;
  final List<CrpCarModel>? models;

  CrpCarModelsResponse({
    this.bStatus,
    this.sMessage,
    this.models,
  });

  factory CrpCarModelsResponse.fromJson(Map<String, dynamic> json) =>
      CrpCarModelsResponse(
        bStatus: json['bStatus'] as bool?,
        sMessage: json['sMessage'] as String?,
        models: (json['models'] as List<dynamic>?)
            ?.map((e) => CrpCarModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'bStatus': bStatus,
        'sMessage': sMessage,
        'models': models?.map((e) => e.toJson()).toList(),
      };
}

class CrpCarModel {
  final int? makeId;
  final String? carType;
  final String? carImageUrl;
  final int? seats;

  CrpCarModel({
    this.makeId,
    this.carType,
    this.carImageUrl,
    this.seats
  });

  factory CrpCarModel.fromJson(Map<String, dynamic> json) => CrpCarModel(
        makeId: json['MakeID'] as int?,
        carType: json['CarType'] as String?,
        carImageUrl: json['carImageUrl'] as String?,
        seats: json['seats'] as int?
      );

  Map<String, dynamic> toJson() => {
        'MakeID': makeId,
        'CarType': carType,
        'carImageUrl':carImageUrl,
        'seats': seats
      };
}


