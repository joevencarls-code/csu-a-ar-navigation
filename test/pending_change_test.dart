import 'dart:convert';
import 'package:csu_a_kiosk/services/pending_change_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingChange.fromJson', () {
    test('parses data / before_data when stored as JSON strings', () {
      final change = PendingChange.fromJson({
        'id': 'abc-123',
        'submitted_by': 'hro.admin@example.com',
        'role': 'hro_admin',
        'module': 'Colleges',
        'table_name': 'colleges',
        'operation': 'update',
        'record_id': 7,
        'data': jsonEncode({'name': 'New Name', 'dean': 'Dr. X'}),
        'before_data': jsonEncode({'name': 'Old Name', 'dean': 'Dr. Y'}),
        'status': 'pending',
        'submitted_at': '2026-09-06T10:00:00.000Z',
      });

      expect(change.data, {'name': 'New Name', 'dean': 'Dr. X'});
      expect(change.beforeData, {'name': 'Old Name', 'dean': 'Dr. Y'});
      expect(change.recordId, 7);
      expect(change.operation, 'update');
      expect(change.submittedAt, DateTime.utc(2026, 9, 6, 10));
    });

    test('parses data when stored as an object (jsonb)', () {
      final change = PendingChange.fromJson({
        'id': 'abc-124',
        'submitted_by': 'infra.admin@example.com',
        'role': 'infra_admin',
        'module': 'Buildings',
        'table_name': 'buildings',
        'operation': 'create',
        'record_id': null,
        'data': {'name': 'New Building', 'location': 'Main'},
        'before_data': null,
        'status': 'pending',
      });

      expect(change.data, {'name': 'New Building', 'location': 'Main'});
      expect(change.beforeData, isNull);
      expect(change.recordId, isNull);
    });

    test('missing or invalid data decodes to null without throwing', () {
      final change = PendingChange.fromJson({
        'id': 'abc-125',
        'submitted_by': 'x@example.com',
        'role': 'ims_super_admin',
        'module': 'Buildings',
        'table_name': 'buildings',
        'operation': 'delete',
        'record_id': '42',
        'data': null,
        'before_data': 'not-json{',
        'status': 'pending',
      });

      expect(change.data, isNull);
      expect(change.beforeData, isNull);
      expect(change.recordId, 42);
    });
  });
}