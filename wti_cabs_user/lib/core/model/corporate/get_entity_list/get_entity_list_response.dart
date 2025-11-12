class EntityListResponse {
  final bool? bStatus;
  final String? sMessage;
  final List<Entity>? getEntityList;

  EntityListResponse({
    this.bStatus,
    this.sMessage,
    this.getEntityList,
  });

  factory EntityListResponse.fromJson(Map<String, dynamic> json) {
    return EntityListResponse(
      bStatus: json['bStatus'] as bool?,
      sMessage: json['sMessage'] as String?,
      getEntityList: (json['GetEntityList'] as List?)
          ?.map((item) => Entity.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bStatus': bStatus,
      'sMessage': sMessage,
      'GetEntityList': getEntityList?.map((e) => e.toJson()).toList(),
    };
  }
}

class Entity {
  final int? entityId;
  final String? entityName;
  final bool? isApprovalRequired;

  Entity({
    this.entityId,
    this.entityName,
    this.isApprovalRequired,
  });

  factory Entity.fromJson(Map<String, dynamic> json) {
    return Entity(
      entityId: json['entityid'] as int?,
      entityName: json['entityname'] as String?,
      isApprovalRequired: json['isapprovalrequired'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityid': entityId,
      'entityname': entityName,
      'isapprovalrequired': isApprovalRequired,
    };
  }
}
