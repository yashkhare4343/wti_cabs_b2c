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
  final num? eta;

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
    this.eta,
  });

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) {
      if (value == 1) return true;
      if (value == 0) return false;
      return null;
    }
    if (value is String) {
      final v = value.toLowerCase().trim();
      if (v == 'true' || v == '1' || v == 'yes' || v == 'y') return true;
      if (v == 'false' || v == '0' || v == 'no' || v == 'n') return false;
      return null;
    }
    return null;
  }

  /// Factory: Convert JSON → Model
  factory CrpCabTrackingResponse.fromJson(Map<String, dynamic> json) {
    return CrpCabTrackingResponse(
      bStatus: _parseBool(json['bStatus']),
      sMessage: json['sMessage'] as String?,
      bookingID: json['BookingID'] as int?,
      bookingStatus: json['BookingStatus'] as String?,
      cabLat: json['CabLat'] as String?,
      cabLng: json['CabLng'] as String?,
      frmLat: json['FrmLat'] as String?,
      frmLng: json['FrmLng'] as String?,
      toLat: json['ToLat'] as String?,
      toLng: json['ToLng'] as String?,
      eta: _parseNum(json['ETA']),
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
      'ETA': eta,
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
    if (bStatus != true) return false;
    final status = bookingStatus?.toLowerCase().trim();
    if (status == null || status.isEmpty) return true;
    // Treat everything except "close" as active for polling/tracking updates
    return status != 'close';
  }

  /// Check if ride is completed
  bool get isRideCompleted {
    return bStatus == false || 
           (bookingStatus != null && bookingStatus!.toLowerCase() == 'close');
  }
}

