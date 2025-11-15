import 'dart:convert';

RunTypeResponse runTypeResponseFromJson(String str) =>
    RunTypeResponse.fromJson(jsonDecode(str));

String runTypeResponseToJson(RunTypeResponse data) =>
    jsonEncode(data.toJson());

class RunTypeResponse {
  final List<RunTypeItem>? runTypes;

  RunTypeResponse({this.runTypes});

  factory RunTypeResponse.fromJson(dynamic json) {
    // Handle list-only API response
    if (json is List) {
      return RunTypeResponse(
        runTypes: json.map((x) => RunTypeItem.fromJson(x)).toList(),
      );
    }

    // Handle wrapped JSON (rare)
    if (json is Map && json['data'] is List) {
      return RunTypeResponse(
        runTypes:
        (json['data'] as List).map((x) => RunTypeItem.fromJson(x)).toList(),
      );
    }

    return RunTypeResponse(runTypes: []);
  }

  Map<String, dynamic> toJson() => {
    "runTypes": runTypes?.map((x) => x.toJson()).toList(),
  };
}

class RunTypeItem {
  final int? runTypeID;
  final String? run;

  RunTypeItem({
    this.runTypeID,
    this.run,
  });

  factory RunTypeItem.fromJson(Map<String, dynamic> json) => RunTypeItem(
    runTypeID: json["RunTypeID"] as int?,
    run: json["Run"] as String?,
  );

  Map<String, dynamic> toJson() => {
    "RunTypeID": runTypeID,
    "Run": run,
  };
}
