class CarProviderModel {
  final int? providerID;
  final String? providerName;

  CarProviderModel({this.providerID, this.providerName});

  factory CarProviderModel.fromJson(Map<String, dynamic> json) {
    return CarProviderModel(
      providerID: json['ProviderID'] ?? json['providerID'] ?? json['id'],
      providerName: json['ProviderName'] ?? json['providerName'] ?? json['name'] ?? json['Provider'],
    );
  }

  static List<CarProviderModel> listFromJson(dynamic json) {
    if (json is List) {
      return json.map((e) => CarProviderModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarProviderModel &&
        other.providerID == providerID &&
        other.providerName == providerName;
  }

  @override
  int get hashCode => providerID.hashCode ^ providerName.hashCode;
}

