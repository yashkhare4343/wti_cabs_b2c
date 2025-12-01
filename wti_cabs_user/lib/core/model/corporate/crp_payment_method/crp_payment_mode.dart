import 'dart:convert';

class PaymentModeResponse {
  final bool? status;
  final String? message;
  final List<PaymentModeItem>? modes;

  PaymentModeResponse({
    this.status,
    this.message,
    this.modes,
  });

  factory PaymentModeResponse.fromJson(dynamic json) {
    if (json is String) json = jsonDecode(json);

    return PaymentModeResponse(
      status: json["bStatus"] as bool?,
      message: json["sMessage"] as String?,
      modes: (json["mode"] as List?)
          ?.map((e) => PaymentModeItem.fromJson(e))
          .toList(),
    );
  }
}

class PaymentModeItem {
  final int? id;
  final String? mode;

  PaymentModeItem({this.id, this.mode});

  factory PaymentModeItem.fromJson(Map<String, dynamic> json) =>
      PaymentModeItem(
        id: json["PaymodeId"] as int?,
        mode: json["PMode"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "PaymodeId": id,
        "PMode": mode,
      };
}
