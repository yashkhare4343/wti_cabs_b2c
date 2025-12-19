class CrpLoginResponse {
  final String key;
  final bool bStatus;
  final String sMessage;
  final int guestID;
  final String guestName;
  final String branchID;
  final int subbranchID;
  final bool lastRideBookingRatingFlag;
  final String corpID;
  final String payModeID;
  final String carProviders;
  final String logoPath;
  final int genderId;
  final int entityId;
  final int advancedHourToConfirm;


  CrpLoginResponse({
    required this.key,
    required this.bStatus,
    required this.sMessage,
    required this.guestID,
    required this.guestName,
    required this.branchID,
    required this.subbranchID,
    required this.lastRideBookingRatingFlag,
    required this.corpID,
    required this.payModeID,
    required this.carProviders,
    required this.logoPath,
    required this.genderId,
    required this.entityId,
    required this.advancedHourToConfirm,
  });

  factory CrpLoginResponse.fromJson(Map<String, dynamic> json) => CrpLoginResponse(
    key: json['key'] ?? '',
    bStatus: json['bStatus'] ?? false,
    sMessage: json['sMessage'] ?? '',
    guestID: json['GuestID'] ?? 0,
    guestName: json['GuestName'] ?? '',
    branchID: json['BranchID'] ?? '0',
    subbranchID: json['SubbranchID'] ?? 0,
    lastRideBookingRatingFlag: json['last_ride_booking_rating_flag'] ?? false,
    corpID: json['CorpID'] ?? '0',
    payModeID: json['PayModeID'] ?? '0',
    carProviders: json['CarProviders'] ?? '0',
    logoPath: json['LogoPath'] ?? '',
    genderId: json['GenderId'] ?? 1,
    entityId: json['EntityId'] ?? 1,
    advancedHourToConfirm: json['Advanced_Hour_To_Confirm'] ?? 4,
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'bStatus': bStatus,
    'sMessage': sMessage,
    'GuestID': guestID,
    'GuestName': guestName,
    'BranchID': branchID,
    'SubbranchID': subbranchID,
    'last_ride_booking_rating_flag': lastRideBookingRatingFlag,
    'CorpID': corpID,
    'PayModeID': payModeID,
    'CarProviders': carProviders,
    'LogoPath': logoPath,
    'GenderId': genderId,
    'EntityId': entityId,
    'Advanced_Hour_To_Confirm': advancedHourToConfirm,
  };
}
