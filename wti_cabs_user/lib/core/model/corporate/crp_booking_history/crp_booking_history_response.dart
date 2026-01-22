import 'package:intl/intl.dart';

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
  /// Primary timestamp fields for sorting (if provided by API)
  /// - pickupDateTime: for Upcoming tab sorting
  /// - completedDateTime: for Completed tab sorting
  /// - cancelledDateTime: for Cancelled tab sorting
  final String? pickupDateTime;
  final String? completedDateTime;
  final String? cancelledDateTime;
  final String? status;
  final String? model;
  final String? run;
  final int? isReviewed;
  final String? pickupAddress;
  final String? dropAddress;
  final int? currentDispatchStatusId;
  final dynamic extraPaxCount;
  final dynamic multipax;

  // Cached parsed DateTimes (local timezone) for fast, stable sorting.
  DateTime? _pickupDateTimeLocalCache;
  DateTime? _completedDateTimeLocalCache;
  DateTime? _cancelledDateTimeLocalCache;

  CrpBookingHistoryItem({
    this.bookingId,
    this.uid,
    this.id,
    this.bookingNo,
    this.passenger,
    this.cabRequiredOn,
    this.pickupDateTime,
    this.completedDateTime,
    this.cancelledDateTime,
    this.status,
    this.model,
    this.run,
    this.isReviewed,
    this.pickupAddress,
    this.dropAddress,
    this.currentDispatchStatusId,
    this.extraPaxCount,
    this.multipax,
  });

  /// Parse date/time string into local DateTime.
  /// Supports formats like: "Jan 24 2026  3:42PM" (note double spaces).
  static DateTime? _parseToLocalDateTime(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'null') return null;

    // Normalize whitespace (handles double spaces)
    final s = normalized.replaceAll(RegExp(r'\s+'), ' ');

    // 1) ISO / standard formats (may include timezone)
    try {
      final parsed = DateTime.parse(s);
      return parsed.isUtc ? parsed.toLocal() : parsed;
    } catch (_) {
      // continue
    }

    // 2) Custom formats (local time)
    const locale = 'en_US';
    final formats = <String>[
      // "Jan 24 2026  3:42PM"
      'MMM d yyyy h:mma',
      'MMM dd yyyy h:mma',

      // Existing known formats
      'dd/MM/yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm',
      'dd/MM/yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-dd',
      'MM/dd/yyyy HH:mm:ss',
      'MM/dd/yyyy HH:mm',
      'MM/dd/yyyy',
      'dd-MM-yyyy HH:mm:ss',
      'dd-MM-yyyy HH:mm',
      'dd-MM-yyyy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format, locale).parse(s);
      } catch (_) {
        // continue
      }
    }

    return null;
  }

  /// Cached local DateTime for Upcoming sorting (ASC).
  DateTime? get pickupDateTimeLocal =>
      _pickupDateTimeLocalCache ??= _parseToLocalDateTime(pickupDateTime ?? cabRequiredOn);

  /// Cached local DateTime for Completed sorting (DESC).
  DateTime? get completedDateTimeLocal =>
      _completedDateTimeLocalCache ??= _parseToLocalDateTime(completedDateTime);

  /// Cached local DateTime for Cancelled sorting (DESC).
  DateTime? get cancelledDateTimeLocal =>
      _cancelledDateTimeLocalCache ??= _parseToLocalDateTime(cancelledDateTime);

  static String? _asString(dynamic v) => v == null ? null : v.toString();

  factory CrpBookingHistoryItem.fromJson(Map<String, dynamic> json) {
    return CrpBookingHistoryItem(
      bookingId: json['BookingID'] as int?,
      uid: json['UID'] as int?,
      id: json['ID'] as int?,
      bookingNo: json['BookingNo'] as String?,
      passenger: json['Passenger'] as String?,
      cabRequiredOn: json['CabRequiredOn'] as String?,
      // These keys are handled defensively since backend naming can vary.
      pickupDateTime: _asString(json['PickupDateTime']) ??
          _asString(json['PickupOn']) ??
          _asString(json['PickupDate']) ??
          _asString(json['CabRequiredOn']),
      completedDateTime: _asString(json['CompletedDateTime']) ??
          _asString(json['CompletedOn']) ??
          _asString(json['CloseDateTime']) ??
          _asString(json['CloseDate']) ??
          _asString(json['TripEndDateTime']),
      cancelledDateTime: _asString(json['CancelledDateTime']) ??
          _asString(json['CanceledDateTime']) ??
          _asString(json['CancelDateTime']) ??
          _asString(json['CancelledOn']) ??
          _asString(json['CanceledOn']) ??
          _asString(json['CancelDate']),
      status: json['Status'] as String?,
      model: json['Model'] as String?,
      run: json['Run'] as String?,
      isReviewed: json['IsReviewed'] as int?,
      pickupAddress: json['PickupAddress'] as String?,
      dropAddress: json['DropAddress'] as String?,
      currentDispatchStatusId: json['CurrentDispatchStatusId'] as int? ?? 0,
      extraPaxCount: json['ExtraPaxCount'],
      multipax: json['Multipax'],
    );
  }
}



