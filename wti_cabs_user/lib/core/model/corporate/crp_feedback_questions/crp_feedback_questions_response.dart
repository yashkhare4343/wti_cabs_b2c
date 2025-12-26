class CrpFeedbackQuestionsResponse {
  final bool? bStatus;
  final String? sMessage;
  final int? questionID;
  final int? noOfQuestions;
  final List<FeedbackQuestion>? ques;

  CrpFeedbackQuestionsResponse({
    this.bStatus,
    this.sMessage,
    this.questionID,
    this.noOfQuestions,
    this.ques,
  });

  factory CrpFeedbackQuestionsResponse.fromJson(dynamic json) {
    if (json is String) {
      return CrpFeedbackQuestionsResponse(
        sMessage: json,
      );
    }

    if (json is Map<String, dynamic>) {
      final rawQues = json['Ques'];
      List<FeedbackQuestion>? parsedQues;

      if (rawQues is List) {
        parsedQues = rawQues
            .map((e) => FeedbackQuestion.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return CrpFeedbackQuestionsResponse(
        bStatus: json['bStatus'] as bool?,
        sMessage: json['sMessage'] as String?,
        questionID: json['QuestionID'] as int?,
        noOfQuestions: json['NoOfQuestions'] as int?,
        ques: parsedQues,
      );
    }

    return CrpFeedbackQuestionsResponse();
  }

  Map<String, dynamic> toJson() {
    return {
      'bStatus': bStatus,
      'sMessage': sMessage,
      'QuestionID': questionID,
      'NoOfQuestions': noOfQuestions,
      'Ques': ques?.map((q) => q.toJson()).toList(),
    };
  }
}

class FeedbackQuestion {
  final int? qId;
  final String? question;

  FeedbackQuestion({
    this.qId,
    this.question,
  });

  factory FeedbackQuestion.fromJson(Map<String, dynamic> json) {
    return FeedbackQuestion(
      qId: json['Q_id'] as int?,
      question: json['Question'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Q_id': qId,
      'Question': question,
    };
  }
}

// Feedback Submission Response Model
class CrpFeedbackSubmissionResponse {
  final bool? bStatus;
  final String? sMessage;

  CrpFeedbackSubmissionResponse({
    this.bStatus,
    this.sMessage,
  });

  factory CrpFeedbackSubmissionResponse.fromJson(dynamic json) {
    if (json is String) {
      return CrpFeedbackSubmissionResponse(
        sMessage: json,
      );
    }

    if (json is Map<String, dynamic>) {
      return CrpFeedbackSubmissionResponse(
        bStatus: json['bStatus'] as bool?,
        sMessage: json['sMessage'] as String?,
      );
    }

    // Handle array response format: [{"bStatus":false,"sMessage":"review already done!"}]
    if (json is List && json.isNotEmpty) {
      final firstItem = json[0];
      if (firstItem is Map<String, dynamic>) {
        return CrpFeedbackSubmissionResponse(
          bStatus: firstItem['bStatus'] as bool?,
          sMessage: firstItem['sMessage'] as String?,
        );
      }
    }

    return CrpFeedbackSubmissionResponse();
  }

  Map<String, dynamic> toJson() {
    return {
      'bStatus': bStatus,
      'sMessage': sMessage,
    };
  }
}

