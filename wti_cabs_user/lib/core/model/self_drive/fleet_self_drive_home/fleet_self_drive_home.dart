class FleetResponse {
  final bool? success;
  final String? message;
  final int? statusCode;
  final List<ClassResult>? result;

  FleetResponse({
    this.success,
    this.message,
    this.statusCode,
    this.result,
  });

  factory FleetResponse.fromJson(Map<String, dynamic> json) {
    return FleetResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
      result: (json['result'] as List<dynamic>?)
          ?.map((e) => ClassResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'statusCode': statusCode,
      'result': result?.map((e) => e.toJson()).toList(),
    };
  }
}

class ClassResult {
  final String? id;
  final String? className;
  final int? v;
  final DateTime? createdAt;
  final String? imageUrl;
  final DateTime? updatedAt;

  ClassResult({
    this.id,
    this.className,
    this.v,
    this.createdAt,
    this.imageUrl,
    this.updatedAt,
  });

  factory ClassResult.fromJson(Map<String, dynamic> json) {
    return ClassResult(
      id: json['_id'] as String?,
      className: json['className'] as String?,
      v: json['__v'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      imageUrl: json['imageUrl'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'className': className,
      '__v': v,
      'createdAt': createdAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
