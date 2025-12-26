class CrpDriverDetailsResponse {
  final bool? bStatus;
  final String? sMessage;
  final String? carNo;
  final String? chauffeur;
  final String? mobile;

  CrpDriverDetailsResponse({
    this.bStatus,
    this.sMessage,
    this.carNo,
    this.chauffeur,
    this.mobile,
  });

  /// Factory: Convert JSON → Model
  factory CrpDriverDetailsResponse.fromJson(Map<String, dynamic> json) {
    return CrpDriverDetailsResponse(
      bStatus: json['bStatus'] as bool?,
      sMessage: json['sMessage'] as String?,
      carNo: json['CarNo'] as String?,
      chauffeur: json['Chauffeur'] as String?,
      mobile: json['Mobile'] as String?,
    );
  }

  /// Convert Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'bStatus': bStatus,
      'sMessage': sMessage,
      'CarNo': carNo,
      'Chauffeur': chauffeur,
      'Mobile': mobile,
    };
  }
}

