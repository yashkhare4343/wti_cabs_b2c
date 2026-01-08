class CrpBookingDetailsResponse {
  final int? bookingID;
  final String? accountingDate;
  final int? fiscal;
  final int? branchID;
  final int? subBranchID;
  final String? bookingNo;
  final int? corporateID;
  final String? corporateName;
  final String? passenger;
  final String? email;
  final String? mobile;
  final String? alternateMobile;
  final int? gender;
  final String? cabRequiredOn;
  final int? makeID;
  final String? arrivalDetails;
  final String? pickupAddress;
  final String? dropAddress;
  final String? specialInstructions;
  final int? payMode;
  final int? providerID;
  final int? source;
  final String? transNo;
  final String? costCode;
  final int? runTypeID;
  final String? employeeID;
  final String? remarks;
  final String? cancelReason;
  final int? uid;
  final int? bookingStatus;
  final int? bookingBy;
  final int? cardID;
  final String? pickupOtp;
  final String? dropOtp;

  CrpBookingDetailsResponse({
    this.bookingID,
    this.accountingDate,
    this.fiscal,
    this.branchID,
    this.subBranchID,
    this.bookingNo,
    this.corporateID,
    this.corporateName,
    this.passenger,
    this.email,
    this.mobile,
    this.alternateMobile,
    this.gender,
    this.cabRequiredOn,
    this.makeID,
    this.arrivalDetails,
    this.pickupAddress,
    this.dropAddress,
    this.specialInstructions,
    this.payMode,
    this.providerID,
    this.source,
    this.transNo,
    this.costCode,
    this.runTypeID,
    this.employeeID,
    this.remarks,
    this.cancelReason,
    this.uid,
    this.bookingStatus,
    this.bookingBy,
    this.cardID,
    this.pickupOtp,
    this.dropOtp,
  });

  /// Factory: Convert JSON → Model
  factory CrpBookingDetailsResponse.fromJson(Map<String, dynamic> json) {
    return CrpBookingDetailsResponse(
      bookingID: json['BookingID'],
      accountingDate: json['AccountingDate'],
      fiscal: json['Fiscal'],
      branchID: json['BranchID'],
      subBranchID: json['SubBranchID'],
      bookingNo: json['BookingNo'],
      corporateID: json['CorporateID'],
      corporateName: json['CorporateName'],
      passenger: json['Passenger'],
      email: json['Email'],
      mobile: json['Mobile'],
      alternateMobile: json['AlternateMobile'],
      gender: json['Gender'],
      cabRequiredOn: json['CabRequiredOn'],
      makeID: json['MakeID'],
      arrivalDetails: json['ArrivalDetails'],
      pickupAddress: json['PickupAddress'],
      dropAddress: json['DropAddress'],
      specialInstructions: json['SpecialInstructions'],
      payMode: json['PayMode'],
      providerID: json['ProviderID'],
      source: json['Source'],
      transNo: json['TransNo'],
      costCode: json['CostCode'],
      runTypeID: json['RunTypeID'],
      employeeID: json['EmployeeID'],
      remarks: json['Remarks'],
      cancelReason: json['CancelReason'],
      uid: json['UID'],
      bookingStatus: json['BookingStatus'],
      bookingBy: json['BookingBy'],
      cardID: json['CardID'],
      pickupOtp: json['PickupOtp'] ?? "0",
      dropOtp: json['DropOtp'] ?? "0",
    );
  }

  /// Convert Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'BookingID': bookingID,
      'AccountingDate': accountingDate,
      'Fiscal': fiscal,
      'BranchID': branchID,
      'SubBranchID': subBranchID,
      'BookingNo': bookingNo,
      'CorporateID': corporateID,
      'CorporateName': corporateName,
      'Passenger': passenger,
      'Email': email,
      'Mobile': mobile,
      'AlternateMobile': alternateMobile,
      'Gender': gender,
      'CabRequiredOn': cabRequiredOn,
      'MakeID': makeID,
      'ArrivalDetails': arrivalDetails,
      'PickupAddress': pickupAddress,
      'DropAddress': dropAddress,
      'SpecialInstructions': specialInstructions,
      'PayMode': payMode,
      'ProviderID': providerID,
      'Source': source,
      'TransNo': transNo,
      'CostCode': costCode,
      'RunTypeID': runTypeID,
      'EmployeeID': employeeID,
      'Remarks': remarks,
      'CancelReason': cancelReason,
      'UID': uid,
      'BookingStatus': bookingStatus,
      'BookingBy': bookingBy,
      'CardID': cardID,
      'PickupOtp': pickupOtp ?? "0",
      'DropOtp': dropOtp ?? "0",
    };
  }
}
