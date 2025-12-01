class GenderModel {
  final int? genderID;
  final String? gender;

  GenderModel({this.genderID, this.gender});

  factory GenderModel.fromJson(Map<String, dynamic> json) {
    return GenderModel(
      genderID: json['GenderID'] ?? json['genderID'],
      gender: json['Gender'] ?? json['gender'],
    );
  }

  static List<GenderModel> listFromJson(dynamic json) {
    if (json is List) {
      return json.map((e) => GenderModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenderModel &&
        other.genderID == genderID &&
        other.gender == gender;
  }

  @override
  int get hashCode => genderID.hashCode ^ gender.hashCode;
}
