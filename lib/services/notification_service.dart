import 'package:supabase_flutter/supabase_flutter.dart';

/// A single notification telling an admin that one of their submitted
/// changes was approved or rejected by the IMS Super Admin.
class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final String module;
  final bool read;
  final DateTime? createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.module,
    required this.read,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'approved',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      module: json['module'] as String? ?? '',
      read: json['read'] is bool ? json['read'] as bool : json['read'] == true,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class NotificationService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Builds a clear, human-friendly notification for a decision on a
  /// pending change. Includes the operation (create/update/delete) and
  /// the specific record so HRO/Infra admins know exactly what happened.
  Future<void> notifyApproved({
    required String userEmail,
    required String module,
    required String operation,
    String? recordName,
  }) async {
    await _client.from('notifications').insert({
      'user_email': userEmail.toLowerCase().trim(),
      'type': 'approved',
      'title': _approvedTitle(module, operation),
      'message': _approvedMessage(operation, recordName),
      'module': module,
      'read': false,
    });
  }

  Future<void> notifyRejected({
    required String userEmail,
    required String module,
    required String operation,
    String? recordName,
  }) async {
    await _client.from('notifications').insert({
      'user_email': userEmail.toLowerCase().trim(),
      'type': 'rejected',
      'title': _rejectedTitle(module, operation),
      'message': _rejectedMessage(operation, recordName),
      'module': module,
      'read': false,
    });
  }

  String _approvedTitle(String module, String operation) {
    final op = _operationPresent(operation);
    return switch (op) {
      'create' => '$module — Create approved',
      'update' => '$module — Update approved',
      'delete' => '$module — Delete approved',
      _ => '$module change approved',
    };
  }

  String _rejectedTitle(String module, String operation) {
    final op = _operationPresent(operation);
    return switch (op) {
      'create' => '$module — Create rejected',
      'update' => '$module — Update rejected',
      'delete' => '$module — Delete rejected',
      _ => '$module change rejected',
    };
  }

  String _approvedMessage(String operation, String? name) {
    final op = _operationPresent(operation);
    final quoted = name == null || name.isEmpty ? null : '"$name"';
    return switch (op) {
      'create' => quoted == null
          ? 'Your new record was added to the kiosk and is now live.'
          : '$quoted was added to the kiosk and is now live.',
      'update' => quoted == null
          ? 'Your changes were applied to the kiosk and are now live.'
          : '$quoted was updated and is now live on the kiosk.',
      'delete' => quoted == null
          ? 'Your record was removed from the kiosk.'
          : '$quoted was removed from the kiosk.',
      _ => 'Your change was approved and is now live on the kiosk.',
    };
  }

  String _rejectedMessage(String operation, String? name) {
    final op = _operationPresent(operation);
    final quoted = name == null || name.isEmpty ? null : '"$name"';
    return switch (op) {
      'create' => quoted == null
          ? 'Your request to add a new record was not approved.'
          : 'Your request to add $quoted was not approved.',
      'update' => quoted == null
          ? 'Your changes were not approved and were not applied.'
          : 'Your changes to $quoted were not approved and were not applied.',
      'delete' => quoted == null
          ? 'Your request to delete a record was not approved.'
          : 'Your request to delete $quoted was not approved.',
      _ => 'Your change was rejected by the IMS Super Admin and was not applied.',
    };
  }

  String _operationPresent(String? operation) {
    if (operation == 'create') return 'create';
    if (operation == 'update') return 'update';
    if (operation == 'delete') return 'delete';
    return 'unknown';
  }

  Future<List<NotificationItem>> getForUser(String email) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_email', email.toLowerCase().trim())
        .order('created_at', ascending: false)
        .limit(50);
    return [for (final row in rows) NotificationItem.fromJson(row)];
  }

  Future<int> unreadCount(String email) async {
    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('user_email', email.toLowerCase().trim())
        .eq('read', false);
    return rows.length;
  }

  Future<void> markAllRead(String email) async {
    await _client
        .from('notifications')
        .update({'read': true}).eq('user_email', email.toLowerCase().trim());
  }

  Future<void> delete(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  Future<void> clearAll(String email) async {
    await _client
        .from('notifications')
        .delete()
        .eq('user_email', email.toLowerCase().trim());
  }
}