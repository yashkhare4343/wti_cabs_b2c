class ProvisionalBookingResponse {
  final bool? success;
  final String? message;
  final Order? order;
  final bool? orderCreated;
  final bool? receiptCreated;
  final bool? recieptUpdated;
  final String? orderReferenceNumber;

  ProvisionalBookingResponse({
    this.success,
    this.message,
    this.order,
    this.orderCreated,
    this.receiptCreated,
    this.recieptUpdated,
    this.orderReferenceNumber,
  });

  factory ProvisionalBookingResponse.fromJson(Map<String, dynamic> json) {
    return ProvisionalBookingResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      order: json['order'] != null ? Order.fromJson(json['order']) : null,
      orderCreated: json['orderCreated'] as bool?,
      receiptCreated: json['receiptCreated'] as bool?,
      recieptUpdated: json['recieptUpdated'] as bool?,
      orderReferenceNumber: json['order_reference_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'order': order?.toJson(),
      'orderCreated': orderCreated,
      'receiptCreated': receiptCreated,
      'recieptUpdated': recieptUpdated,
      'order_reference_number': orderReferenceNumber,
    };
  }
}

class Order {
  final num? amount;
  final num? amountDue;
  final num? amountPaid;
  final num? attempts;
  final num? createdAt;
  final String? currency;
  final String? entity;
  final String? id;
  final List<dynamic>? notes;
  final String? offerId;
  final String? receipt;
  final String? status;

  Order({
    this.amount,
    this.amountDue,
    this.amountPaid,
    this.attempts,
    this.createdAt,
    this.currency,
    this.entity,
    this.id,
    this.notes,
    this.offerId,
    this.receipt,
    this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      amount: json['amount'] as num?,
      amountDue: json['amount_due'] as num?,
      amountPaid: json['amount_paid'] as num?,
      attempts: json['attempts'] as num?,
      createdAt: json['created_at'] as num?,
      currency: json['currency'] as String?,
      entity: json['entity'] as String?,
      id: json['id'] as String?,
      notes: json['notes'] as List<dynamic>?,
      offerId: json['offer_id'] as String?,
      receipt: json['receipt'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'amount_due': amountDue,
      'amount_paid': amountPaid,
      'attempts': attempts,
      'created_at': createdAt,
      'currency': currency,
      'entity': entity,
      'id': id,
      'notes': notes,
      'offer_id': offerId,
      'receipt': receipt,
      'status': status,
    };
  }
}
