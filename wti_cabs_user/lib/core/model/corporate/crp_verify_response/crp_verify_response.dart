class CprVerifyResponse {
  final bool? bStatus;
  final String? sMessage;
  final int? code;
  final String? msg;
  final String? corporateName;

  CprVerifyResponse({
    this.bStatus,
    this.sMessage,
    this.code,
    this.msg,
    this.corporateName,
  });

  factory CprVerifyResponse.fromJson(Map<String, dynamic> json) {
    return CprVerifyResponse(
      bStatus: json['bStatus'] as bool?,
      sMessage: json['sMessage'] as String?,
      code: json['Code'] as int?,
      msg: json['Msg'] as String?,
      corporateName: json['CorporateName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bStatus': bStatus,
      'sMessage': sMessage,
      'Code': code,
      'Msg': msg,
      'CorporateName': corporateName,
    };
  }
}
