class RegisterResponse {
  final bool? userCreated;
  final bool? userExist;
  final String? userID;
  final String? role;
  final String? userObjId;
  final String? name;
  final int? number;
  final String? email;
  final String? gender;
  final String? contactCode;
  final String? country;

  RegisterResponse({
    this.userCreated,
    this.userExist,
    this.userID,
    this.role,
    this.userObjId,
    this.name,
    this.number,
    this.email,
    this.gender,
    this.contactCode,
    this.country,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      userCreated: json['userCreated'] as bool?,
      userExist: json['userExist'] as bool?,
      userID: json['userID'] as String?,
      role: json['role'] as String?,
      userObjId: json['user_obj_id'] as String?,
      name: json['name'] as String?,
      number: json['number'] as int?,
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      contactCode: json['contactCode'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCreated': userCreated,
      'userExist': userExist,
      'userID': userID,
      'role': role,
      'user_obj_id': userObjId,
      'name': name,
      'number': number,
      'email': email,
      'gender': gender,
      'contactCode': contactCode,
      'country': country,
    };
  }
}
