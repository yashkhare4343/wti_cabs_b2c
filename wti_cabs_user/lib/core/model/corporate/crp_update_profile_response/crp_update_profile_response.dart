class CrpUpdateProfileResponse {
  final bool? bStatus;
  final String? sMessage;

  CrpUpdateProfileResponse({
    this.bStatus,
    this.sMessage,
  });

  factory CrpUpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    // Handle both Map and String responses
    Map<String, dynamic> data;
    if (json is String) {
      data = {'sMessage': json};
    } else {
      data = json;
    }

    return CrpUpdateProfileResponse(
      bStatus: data['bStatus'],
      sMessage: data['sMessage'],
    );
  }

  Map<String, dynamic> toJson() => {
    'bStatus': bStatus,
    'sMessage': sMessage,
  };
}
