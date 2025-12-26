import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../api/corporate/cpr_api_services.dart';
import '../../../model/corporate/crp_feedback_questions/crp_feedback_questions_response.dart';
import '../../../services/storage_services.dart';

class CrpFeedbackQuestionsController extends GetxController {
  final CprApiService apiService = CprApiService();

  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var feedbackQuestions = <FeedbackQuestion>[].obs;
  var feedbackQuestionsResponse = Rx<CrpFeedbackQuestionsResponse?>(null);
  var feedbackSubmissionResponse = Rx<CrpFeedbackSubmissionResponse?>(null);

  Future<void> fetchFeedbackQuestions(BuildContext context) async {
    try {
      isLoading.value = true;

      // Get required parameters from storage
      final corpId = await StorageServices.instance.read('crpId');
      final token = await StorageServices.instance.read('crpKey');
      final userEmail = await StorageServices.instance.read('email');

      if (corpId == null || corpId.isEmpty) {
        debugPrint('❌ CorpID not found in storage');
        return;
      }

      if (token == null || token.isEmpty) {
        debugPrint('❌ Token not found in storage');
        return;
      }

      if (userEmail == null || userEmail.isEmpty || userEmail == 'null') {
        debugPrint('❌ User email not found in storage');
        return;
      }

      final params = {
        'CorpID': corpId,
        'token': token,
        'user': userEmail,
      };

      debugPrint('📤 Fetching feedback questions with params: $params');

      final result = await apiService.getRequestCrp<CrpFeedbackQuestionsResponse>(
        'GetFeedBackQuestion',
        params,
        (json) => CrpFeedbackQuestionsResponse.fromJson(json),
        context,
      );

      feedbackQuestionsResponse.value = result;

      if (result.bStatus == true && result.ques != null && result.ques!.isNotEmpty) {
        feedbackQuestions.assignAll(result.ques!);
        debugPrint('✅ Fetched ${feedbackQuestions.length} feedback questions');
      } else {
        feedbackQuestions.clear();
        debugPrint('⚠️ No feedback questions found or bStatus is false');
      }
    } catch (e) {
      debugPrint('❌ Error fetching feedback questions: $e');
      feedbackQuestions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit feedback answers
  Future<CrpFeedbackSubmissionResponse?> submitFeedback({
    required BuildContext context,
    required int guestId,
    required int orderId,
    required int questionId,
    required Map<int, bool?> answers, // Map of Q_id to answer (true=Yes/1, false=No/0)
    required String remarks,
  }) async {
    try {
      isSubmitting.value = true;

      // Format answers string: "1.1,2.0,3.1,,4.0"
      // Format: Q_id.answer where answer is 1 for Yes (true) and 0 for No (false)
      // Empty string for unanswered questions
      // Format based on sequential question IDs from 1 to questionId
      final List<String> answerParts = [];
      
      for (int i = 1; i <= questionId; i++) {
        final answer = answers[i];
        if (answer != null) {
          answerParts.add('$i.${answer == true ? 1 : 0}');
        } else {
          answerParts.add(''); // Empty for unanswered
        }
      }
      final answersString = answerParts.join(',');

      // Get required parameters from storage
      final token = await StorageServices.instance.read('crpKey');
      final userEmail = await StorageServices.instance.read('email');

      if (token == null || token.isEmpty) {
        debugPrint('❌ Token not found in storage');
        return null;
      }

      if (userEmail == null || userEmail.isEmpty || userEmail == 'null') {
        debugPrint('❌ User email not found in storage');
        return null;
      }

      final params = {
        'GuestID': guestId.toString(),
        'OrderID': orderId.toString(),
        'QuestionID': questionId.toString(),
        'Answers': answersString,
        'Remarks': remarks,
        'token': token,
        'user': userEmail,
      };

      debugPrint('📤 Submitting feedback with params: $params');

      final result = await apiService.postRequestParamsNew<CrpFeedbackSubmissionResponse>(
        'PostFeedBackAnswer',
        params,
        (json) {
          // Handle string response that might be JSON-encoded
          dynamic parsedJson = json;
          if (json is String) {
            try {
              parsedJson = jsonDecode(json);
            } catch (e) {
              debugPrint('⚠️ Could not decode JSON string: $e');
            }
          }
          
          // Handle array response format: [{"bStatus":false,"sMessage":"review already done!"}]
          if (parsedJson is List && parsedJson.isNotEmpty) {
            return CrpFeedbackSubmissionResponse.fromJson(parsedJson);
          }
          return CrpFeedbackSubmissionResponse.fromJson(parsedJson);
        },
        context,
      );

      feedbackSubmissionResponse.value = result;

      debugPrint('✅ Feedback submission response - bStatus: ${result.bStatus}, sMessage: ${result.sMessage}');
      
      return result;
    } catch (e) {
      debugPrint('❌ Error submitting feedback: $e');
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }
}

