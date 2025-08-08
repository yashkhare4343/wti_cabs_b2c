class UspResponse {
  final List<AmenityData>? data;

  UspResponse({this.data});

  factory UspResponse.fromJson(Map<String, dynamic> json) {
    return UspResponse(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => AmenityData.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

class AmenityData {
  final String? id;
  final String? title;
  final String? desc;
  final String? imgUrl;
  final bool? isActive;
  final String? slug;
  final int? v;

  AmenityData({
    this.id,
    this.title,
    this.desc,
    this.imgUrl,
    this.isActive,
    this.slug,
    this.v,
  });

  factory AmenityData.fromJson(Map<String, dynamic> json) {
    return AmenityData(
      id: json['_id'] as String?,
      title: json['title'] as String?,
      desc: json['desc'] as String?,
      imgUrl: json['imgUrl'] as String?,
      isActive: json['isActive'] as bool?,
      slug: json['slug'] as String?,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'desc': desc,
      'imgUrl': imgUrl,
      'isActive': isActive,
      'slug': slug,
      '__v': v,
    };
  }
}
