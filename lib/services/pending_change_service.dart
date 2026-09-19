import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_auth.dart';
import 'notification_service.dart';

/// A single pending change submitted by an HRO or Infra admin that is
/// waiting for the IMS Super Admin to approve before it goes live.
class PendingChange {
  final String id;
  final String submittedBy;
  final String role;
  final String module;
  final String tableName;
  final String operation;
  final int? recordId;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? beforeData;
  final String status;
  final DateTime? submittedAt;

  PendingChange({
    required this.id,
    required this.submittedBy,
    required this.role,
    required this.module,
    required this.tableName,
    required this.operation,
    this.recordId,
    this.data,
    this.beforeData,
    required this.status,
    this.submittedAt,
  });

  factory PendingChange.fromJson(Map<String, dynamic> json) {
    return PendingChange(
      id: json['id'] as String,
      submittedBy: json['submitted_by'] as String? ?? '',
      role: json['role'] as String? ?? '',
      module: json['module'] as String? ?? '',
      tableName: json['table_name'] as String? ?? '',
      operation: json['operation'] as String? ?? 'create',
      recordId: _parseInt(json['record_id']),
      data: _decodeToMap(json['data']),
      beforeData: _decodeToMap(json['before_data']),
      status: json['status'] as String? ?? 'pending',
      submittedAt: json['submitted_at'] is String
          ? DateTime.tryParse(json['submitted_at'] as String)
          : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Map<String, dynamic>? _decodeToMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        return null;
      }
    }
    return null;
  }
}

/// Wraps the live write functions of a CRUD screen so that, for non-super
/// admins, the change is queued for approval instead of written directly.
class ApprovalQueue {
  final AdminUser user;
  final String module;
  final String tableName;

  const ApprovalQueue(this.user, this.module, this.tableName);

  Future<void> create(Map<String, dynamic> values) {
    return PendingChangeService().submitCreate(
      user: user,
      module: module,
      tableName: tableName,
      values: values,
    );
  }

  Future<void> update(int id, Map<String, dynamic> values) {
    return PendingChangeService().submitUpdate(
      user: user,
      module: module,
      tableName: tableName,
      id: id,
      values: values,
    );
  }

  Future<void> delete(int id) {
    return PendingChangeService().submitDelete(
      user: user,
      module: module,
      tableName: tableName,
      id: id,
    );
  }
}

class PendingChangeService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> submitCreate({
    required AdminUser user,
    required String module,
    required String tableName,
    required Map<String, dynamic> values,
  }) async {
    await _client.from('pending_changes').insert({
      'submitted_by': user.email,
      'role': user.roleKey,
      'module': module,
      'table_name': tableName,
      'operation': 'create',
      'record_id': null,
      'data': jsonEncode(values),
      'before_data': null,
      'status': 'pending',
    });
  }

  Future<void> submitUpdate({
    required AdminUser user,
    required String module,
    required String tableName,
    required int id,
    required Map<String, dynamic> values,
  }) async {
    final before = await _fetchRow(tableName, id);
    await _client.from('pending_changes').insert({
      'submitted_by': user.email,
      'role': user.roleKey,
      'module': module,
      'table_name': tableName,
      'operation': 'update',
      'record_id': id,
      'data': jsonEncode(values),
      'before_data': before == null ? null : jsonEncode(before),
      'status': 'pending',
    });
  }

  Future<void> submitDelete({
    required AdminUser user,
    required String module,
    required String tableName,
    required int id,
  }) async {
    final before = await _fetchRow(tableName, id);
    await _client.from('pending_changes').insert({
      'submitted_by': user.email,
      'role': user.roleKey,
      'module': module,
      'table_name': tableName,
      'operation': 'delete',
      'record_id': id,
      'data': null,
      'before_data': before == null ? null : jsonEncode(before),
      'status': 'pending',
    });
  }

  Future<Map<String, dynamic>?> _fetchRow(String tableName, int id) async {
    try {
      final row = await _client
          .from(tableName)
          .select()
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<PendingChange>> getPending() async {
    final rows = await _client
        .from('pending_changes')
        .select()
        .eq('status', 'pending')
        .order('submitted_at', ascending: false);
    return [for (final row in rows) PendingChange.fromJson(row)];
  }

  /// Counts changes currently waiting for approval.
  Future<int> countPending() async {
    final rows = await _client
        .from('pending_changes')
        .select('id')
        .eq('status', 'pending');
    return rows.length;
  }

  /// Applies the queued change to its live table, then marks it approved.
  Future<void> approve(
    PendingChange pending,
    AdminUser reviewer,
  ) async {
    final table = pending.tableName;
    switch (pending.operation) {
      case 'create':
        if (pending.data == null) {
          throw StateError('Pending create is missing its data');
        }
        final inserted = await _client
            .from(table)
            .insert(pending.data!)
            .select()
            .single();
        final newId = inserted['id'];
        await _client
            .from('pending_changes')
            .update({'record_id': newId}).eq('id', pending.id);
      case 'update':
        if (pending.data == null) {
          throw StateError('Pending update is missing its data');
        }
        final recordId = pending.recordId;
        if (recordId == null) {
          throw StateError('Pending update is missing the record id');
        }
        await _client
            .from(table)
            .update(pending.data!)
            .eq('id', recordId);
      case 'delete':
        final recordId = pending.recordId;
        if (recordId == null) {
          throw StateError('Pending delete is missing the record id');
        }
        await _client.from(table).delete().eq('id', recordId);
    }
    await _client.from('pending_changes').update({
      'status': 'approved',
      'reviewed_by': reviewer.email,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', pending.id);
    try {
      await NotificationService().notifyApproved(
        userEmail: pending.submittedBy,
        module: pending.module,
        operation: pending.operation,
        recordName: _recordName(pending),
      );
    } catch (_) {
      // A failed notification must not fail the approval itself.
    }
  }

  /// Marks a queued change as rejected without applying it.
  Future<void> reject(PendingChange pending, AdminUser reviewer) async {
    await _client.from('pending_changes').update({
      'status': 'rejected',
      'reviewed_by': reviewer.email,
      'reviewed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', pending.id);
    try {
      await NotificationService().notifyRejected(
        userEmail: pending.submittedBy,
        module: pending.module,
        operation: pending.operation,
        recordName: _recordName(pending),
      );
    } catch (_) {
      // A failed notification must not fail the rejection itself.
    }
  }

  /// Best-effort human-readable name for the affected record so the
  /// notification tells the submitting admin exactly which record was
  /// approved or rejected. Tables differ in their name column.
  String? _recordName(PendingChange pending) {
    final maps = [
      if (pending.operation == 'create') pending.data,
      pending.data,
      pending.beforeData,
    ];
    String firstValue(List<String> keys) {
      for (final map in maps) {
        if (map == null) continue;
        for (final key in keys) {
          final v = map[key];
          if (v != null) {
            final s = v.toString().trim();
            if (s.isNotEmpty) return s;
          }
        }
      }
      return '';
    }

    final name = firstValue(['name', 'fullname', 'room_name', 'question']);
    if (name.isNotEmpty) return name;
    final abbrev = firstValue(['abbreviation', 'abbrev']);
    if (abbrev.isNotEmpty) return abbrev;
    return null;
  }
}