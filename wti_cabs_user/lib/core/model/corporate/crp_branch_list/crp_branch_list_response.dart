class GetBranchListResponse {
  List<Branch>? branches;

  GetBranchListResponse({this.branches});

  factory GetBranchListResponse.fromJson(Map<String, dynamic> json) {
    return GetBranchListResponse(
      branches: (json['branches'] as List<dynamic>?)
          ?.map((e) => Branch.fromJson(e))
          .toList(),
    );
  }

  factory GetBranchListResponse.fromList(List<dynamic> list) {
    return GetBranchListResponse(
      branches: list.map((e) => Branch.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "branches": branches?.map((e) => e.toJson()).toList(),
  };
}

class Branch {
  int? branchID;
  String? branchName;
  int? tier;
  String? msg;

  Branch({this.branchID, this.branchName, this.tier, this.msg});

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
    branchID: json['BranchID'],
    branchName: json['BranchName'],
    tier: json['Tier'],
    msg: json['Msg'],
  );

  Map<String, dynamic> toJson() => {
    "BranchID": branchID,
    "BranchName": branchName,
    "Tier": tier,
    "Msg": msg,
  };
}
