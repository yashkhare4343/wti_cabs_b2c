class CprProfileResponse {
  final bool? bStatus;
  final String? sMessage;
  final int? guestID;
  final String? emailID;
  final String? guestName;
  final String? corporateID;
  final String? corporateName;
  final String? employeeID;
  final int? cardID;
  final String? cardNo;
  final String? ccExpiry;
  final String? mobile;
  final String? designation;
  final String? costCode;
  final String? branchName;
  final String? branchID;
  final int? isCardValidated;
  final int? isActive;
  final int? gender;

  CprProfileResponse({
    this.bStatus,
    this.sMessage,
    this.guestID,
    this.emailID,
    this.guestName,
    this.corporateID,
    this.corporateName,
    this.employeeID,
    this.cardID,
    this.cardNo,
    this.ccExpiry,
    this.mobile,
    this.designation,
    this.costCode,
    this.branchName,
    this.branchID,
    this.isCardValidated,
    this.isActive,
    this.gender,
  });

  factory CprProfileResponse.fromJson(Map<String, dynamic> json) {
    return CprProfileResponse(
      bStatus: json['bStatus'],
      sMessage: json['sMessage'],
      guestID: json['GuestID'],
      emailID: json['EmailID'],
      guestName: json['GuestName'],
      corporateID: json['CorporateID']?.toString(),
      corporateName: json['Corporate_Name'],
      employeeID: json['EmployeeID'],
      cardID: json['CardID'],
      cardNo: json['CardNo'],
      ccExpiry: json['CCExpiry'],
      mobile: json['Mobile'],
      designation: json['Designation'],
      costCode: json['CostCode'],
      branchName: json['BranchName'],
      branchID: json['BranchID']?.toString(),
      isCardValidated: json['IsCardValidated'],
      isActive: json['IsActive'],
      gender: json['Gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "bStatus": bStatus,
      "sMessage": sMessage,
      "GuestID": guestID,
      "EmailID": emailID,
      "GuestName": guestName,
      "CorporateID": corporateID,
      "Corporate_Name": corporateName,
      "EmployeeID": employeeID,
      "CardID": cardID,
      "CardNo": cardNo,
      "CCExpiry": ccExpiry,
      "Mobile": mobile,
      "Designation": designation,
      "CostCode": costCode,
      "BranchName": branchName,
      "BranchID": branchID,
      "IsCardValidated": isCardValidated,
      "IsActive": isActive,
      "Gender": gender,
    };
  }
}
