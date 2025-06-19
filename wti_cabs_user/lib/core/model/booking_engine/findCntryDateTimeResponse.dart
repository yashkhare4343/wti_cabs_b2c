class FindCntryDateTimeResponse {
  final bool serviceAvailable;
  final bool countryMapped;
  final bool goToNextPage;
  final bool sameCountry;
  final bool isActualTimeUpdated;
  final bool isUserTimeUpdated;
  final ActualDateTimeObject? actualDateTimeObject;
  final UserDateTimeObject? userDateTimeObject;
  final String? timeZone;
  final String? message;
  final bool sourceInput;
  final bool destinationInputFalse;

  FindCntryDateTimeResponse({
    required this.serviceAvailable,
    required this.countryMapped,
    required this.goToNextPage,
    required this.sameCountry,
    required this.isActualTimeUpdated,
    required this.isUserTimeUpdated,
    this.actualDateTimeObject,
    this.userDateTimeObject,
    this.timeZone,
    this.message,
    required this.sourceInput,
    required this.destinationInputFalse,
  });

  factory FindCntryDateTimeResponse.fromJson(Map<String, dynamic> json) {
    return FindCntryDateTimeResponse(
      serviceAvailable: json['serviceAvailable'] ?? false,
      countryMapped: json['countryMapped'] ?? false,
      goToNextPage: json['goToNextPage'] ?? false,
      sameCountry: json['sameCountry'] ?? false,
      isActualTimeUpdated: json['isActualTimeUpdated'] ?? false,
      isUserTimeUpdated: json['isUserTimeUpdated'] ?? false,
      actualDateTimeObject: json['actualDateTimeObject'] != null
          ? ActualDateTimeObject.fromJson(json['actualDateTimeObject'])
          : null,
      userDateTimeObject: json['userDateTimeObject'] != null
          ? UserDateTimeObject.fromJson(json['userDateTimeObject'])
          : null,
      timeZone: json['timeZone'],
      message: json['message'],
      sourceInput: json['sourceInput'] ?? false,
      destinationInputFalse: json['destinationInput'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceAvailable': serviceAvailable,
      'countryMapped': countryMapped,
      'goToNextPage': goToNextPage,
      'sameCountry': sameCountry,
      'isActualTimeUpdated': isActualTimeUpdated,
      'isUserTimeUpdated': isUserTimeUpdated,
      'actualDateTimeObject': actualDateTimeObject?.toJson(),
      'userDateTimeObject': userDateTimeObject?.toJson(),
      'timeZone': timeZone,
      'message': message,
      'sourceInput': sourceInput,
      'destinationInputFalse': destinationInputFalse,
    };
  }
}

class ActualDateTimeObject {
  final String? actualDateTime;
  final int? actualOffSet;

  ActualDateTimeObject({this.actualDateTime, this.actualOffSet});

  factory ActualDateTimeObject.fromJson(Map<String, dynamic> json) {
    return ActualDateTimeObject(
      actualDateTime: json['actualDateTime'],
      actualOffSet: json['actualOffset'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actualDateTime': actualDateTime,
      'actualOffSet': actualOffSet,
    };
  }
}

class UserDateTimeObject {
  final String? userDateTime;
  final int? userOffSet;

  UserDateTimeObject({this.userDateTime, this.userOffSet});

  factory UserDateTimeObject.fromJson(Map<String, dynamic> json) {
    return UserDateTimeObject(
      userDateTime: json['userDateTime'],
      userOffSet: json['userOffSet'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userDateTime': userDateTime,
      'userOffSet': userOffSet,
    };
  }
}
