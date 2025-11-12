class CrpRegisterResponse {
  final String? msg;

  CrpRegisterResponse({this.msg});

  factory CrpRegisterResponse.fromString(String message) {
    return CrpRegisterResponse(msg: message);
  }

  Map<String, dynamic> toJson() => {
    'msg': msg,
  };
}
