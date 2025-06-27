class PackageResponse {
  final bool packageFetched;
  final List<PackageData> data;

  PackageResponse({
    required this.packageFetched,
    required this.data,
  });

  factory PackageResponse.fromJson(Map<String, dynamic> json) {
    return PackageResponse(
      packageFetched: json['packageFetched'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => PackageData.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class PackageData {
  final String? id;
  final String? countryName;
  final int? hours;
  final int? kilometers;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  PackageData({
    this.id,
    this.countryName,
    this.hours,
    this.kilometers,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory PackageData.fromJson(Map<String, dynamic> json) {
    return PackageData(
      id: json['_id'] as String?,
      countryName: json['countryName'] as String?,
      hours: json['hours'] as int?,
      kilometers: json['kilometers'] as int?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      v: json['__v'] as int?,
    );
  }
}
