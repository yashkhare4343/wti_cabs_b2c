class CrpBookingHistoryResponse {
  final bool? bStatus;
  final String? sMessage;
  final List<CrpBookingHistoryItem>? history;

  CrpBookingHistoryResponse({
    this.bStatus,
    this.sMessage,
    this.history,
  });

  factory CrpBookingHistoryResponse.fromJson(dynamic json) {
    if (json is String) {
      return CrpBookingHistoryResponse(
        sMessage: json,
      );
    }

    if (json is Map<String, dynamic>) {
      final rawHistory = json['histry'];
      List<CrpBookingHistoryItem>? parsedHistory;

      if (rawHistory is List) {
        parsedHistory = rawHistory
            .map((e) => CrpBookingHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return CrpBookingHistoryResponse(
        bStatus: json['bStatus'] as bool?,
        sMessage: json['sMessage'] as String?,
        history: parsedHistory,
      );
    }

    return CrpBookingHistoryResponse();
  }
}

class CrpBookingHistoryItem {
  final int? bookingId;
  final int? uid;
  final int? id;
  final String? bookingNo;
  final String? passenger;
  final String? cabRequiredOn;
  final String? status;
  final String? model;
  final String? run;
  final int? isReviewed;
  final dynamic extraPaxCount;
  final dynamic multipax;

  CrpBookingHistoryItem({
    this.bookingId,
    this.uid,
    this.id,
    this.bookingNo,
    this.passenger,
    this.cabRequiredOn,
    this.status,
    this.model,
    this.run,
    this.isReviewed,
    this.extraPaxCount,
    this.multipax,
  });

  factory CrpBookingHistoryItem.fromJson(Map<String, dynamic> json) {
    return CrpBookingHistoryItem(
      bookingId: json['BookingID'] as int?,
      uid: json['UID'] as int?,
      id: json['ID'] as int?,
      bookingNo: json['BookingNo'] as String?,
      passenger: json['Passenger'] as String?,
      cabRequiredOn: json['CabRequiredOn'] as String?,
      status: json['Status'] as String?,
      model: json['Model'] as String?,
      run: json['Run'] as String?,
      isReviewed: json['IsReviewed'] as int?,
      extraPaxCount: json['ExtraPaxCount'],
      multipax: json['Multipax'],
    );
  }
}

