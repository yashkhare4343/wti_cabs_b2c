class CrpCabTrackingResponse {
  final bool? bStatus;
  final String? sMessage;
  final int? bookingID;
  final String? bookingStatus;
  final String? cabLat;
  final String? cabLng;
  final String? frmLat;
  final String? frmLng;
  final String? toLat;
  final String? toLng;

  CrpCabTrackingResponse({
    this.bStatus,
    this.sMessage,
    this.bookingID,
    this.bookingStatus,
    this.cabLat,
    this.cabLng,
    this.frmLat,
    this.frmLng,
    this.toLat,
    this.toLng,
  });

  /// Factory: Convert JSON → Model
  factory CrpCabTrackingResponse.fromJson(Map<String, dynamic> json) {
    return CrpCabTrackingResponse(
      bStatus: json['bStatus'] as bool?,
      sMessage: json['sMessage'] as String?,
      bookingID: json['BookingID'] as int?,
      bookingStatus: json['BookingStatus'] as String?,
      cabLat: json['CabLat'] as String?,
      cabLng: json['CabLng'] as String?,
      frmLat: json['FrmLat'] as String?,
      frmLng: json['FrmLng'] as String?,
      toLat: json['ToLat'] as String?,
      toLng: json['ToLng'] as String?,
    );
  }

  /// Convert Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'bStatus': bStatus,
      'sMessage': sMessage,
      'BookingID': bookingID,
      'BookingStatus': bookingStatus,
      'CabLat': cabLat,
      'CabLng': cabLng,
      'FrmLat': frmLat,
      'FrmLng': frmLng,
      'ToLat': toLat,
      'ToLng': toLng,
    };
  }

  /// Helper methods to safely parse coordinates
  double? get cabLatitude {
    if (cabLat == null || cabLat!.isEmpty) return null;
    return double.tryParse(cabLat!);
  }

  double? get cabLongitude {
    if (cabLng == null || cabLng!.isEmpty) return null;
    return double.tryParse(cabLng!);
  }

  double? get pickupLatitude {
    if (frmLat == null || frmLat!.isEmpty) return null;
    return double.tryParse(frmLat!);
  }

  double? get pickupLongitude {
    if (frmLng == null || frmLng!.isEmpty) return null;
    return double.tryParse(frmLng!);
  }

  double? get dropLatitude {
    if (toLat == null || toLat!.isEmpty) return null;
    return double.tryParse(toLat!);
  }

  double? get dropLongitude {
    if (toLng == null || toLng!.isEmpty) return null;
    return double.tryParse(toLng!);
  }

  /// Check if ride is active (should show tracking)
  bool get isRideActive {
    return bStatus == true && 
           bookingStatus != null && 
           bookingStatus!.toLowerCase() == 'start';
  }

  /// Check if ride is completed
  bool get isRideCompleted {
    return bStatus == false || 
           (bookingStatus != null && bookingStatus!.toLowerCase() == 'close');
  }
}

