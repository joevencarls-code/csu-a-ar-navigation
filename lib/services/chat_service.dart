import 'package:functions_client/functions_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<String> sendMessage(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final response = await _client.functions.invoke(
        'chat',
        body: {'message': message, 'history': history},
      );

      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error']);
      }
      if (data is Map && data['reply'] is String) {
        return data['reply'] as String;
      }
      throw Exception('Unexpected response from chat function');
    } on FunctionException catch (e) {
      // Edge callback returned an error status. `details` carries the
      // JSON body so we can surface the real reason (missing key, provider
      // error, etc.) instead of a generic HTTP error.
      final details = e.details;
      String reason = 'status ${e.status}';
      if (details is Map && details['error'] != null) {
        reason = '${details['error']}';
      } else if (details != null) {
        reason = '$details';
      }
      throw Exception('AI assistant unavailable ($reason). Please try again.');
    }
  }
}