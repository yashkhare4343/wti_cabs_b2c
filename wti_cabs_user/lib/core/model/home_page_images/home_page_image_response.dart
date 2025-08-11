class HomePageImageResponse {
  final String? message;
  final bool? success;
  final BannerResult? result;

  HomePageImageResponse({this.message, this.success, this.result});

  factory HomePageImageResponse.fromJson(Map<String, dynamic> json) {
    return HomePageImageResponse(
      message: json['message'] as String?,
      success: json['success'] as bool?,
      result: json['result'] != null
          ? BannerResult.fromJson(json['result'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'success': success,
      'result': result?.toJson(),
    };
  }
}

class BannerResult {
  final BannerSection? topBanner;
  final BannerSection? bottomBanner;
  final String? id;
  final String? countryName;
  final String? baseUrl;

  BannerResult({this.topBanner, this.bottomBanner, this.id, this.countryName, this.baseUrl});

  factory BannerResult.fromJson(Map<String, dynamic> json) {
    return BannerResult(
      topBanner: json['topBanner'] != null
          ? BannerSection.fromJson(json['topBanner'])
          : null,
      bottomBanner: json['bottomBanner'] != null
          ? BannerSection.fromJson(json['bottomBanner'])
          : null,
      id: json['_id'] as String?,
      countryName: json['countryName'] as String?,
      baseUrl: json['baseUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topBanner': topBanner?.toJson(),
      'bottomBanner': bottomBanner?.toJson(),
      '_id': id,
      'countryName': countryName,
      'baseUrl': baseUrl,
    };
  }
}

class BannerSection {
  final bool? isActive;
  final List<BannerImage>? images;

  BannerSection({this.isActive, this.images});

  factory BannerSection.fromJson(Map<String, dynamic> json) {
    return BannerSection(
      isActive: json['isActive'] as bool?,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => BannerImage.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'images': images?.map((e) => e.toJson()).toList(),
    };
  }
}

class BannerImage {
  final String? id;
  final String? title;
  final String? url;

  BannerImage({this.id, this.title, this.url});

  factory BannerImage.fromJson(Map<String, dynamic> json) {
    return BannerImage(
      id: json['_id'] as String?,
      title: json['title'] as String?,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'url': url,
    };
  }
}
