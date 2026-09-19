   import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campus_models.dart';
import 'pathfinder.dart';

class CampusRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Building>> getBuildings() async {
    final rows = await _client.from('buildings').select();
    return rows.map((row) => Building.fromJson(row)).toList();
  }

  Future<List<Room>> getRoomsForBuilding(int buildingId) async {
    final rows =
        await _client.from('rooms').select().eq('building_id', buildingId);
    return rows.map((row) => Room.fromJson(row)).toList();
  }

  Future<List<Room>> getAllRooms() async {
    final rows = await _client.from('rooms').select();
    return rows.map((row) => Room.fromJson(row)).toList();
  }

  Future<List<QrCodeEntry>> getAllQrCodes() async {
    final rows = await _client.from('qr_codes').select();
    return rows.map((row) => QrCodeEntry.fromJson(row)).toList();
  }

  Future<List<FacultyMember>> getFaculty() async {
    final rows = await _client.from('faculty').select();
    return rows.map((row) => FacultyMember.fromJson(row)).toList();
  }

  Future<void> createBuilding(Map<String, dynamic> values) =>
      _client.from('buildings').insert(values);

  Future<void> updateBuilding(int id, Map<String, dynamic> values) =>
      _client.from('buildings').update(values).eq('id', id);

  Future<void> deleteBuilding(int id) =>
      _client.from('buildings').delete().eq('id', id);

  Future<void> createRoom(Map<String, dynamic> values) =>
      _client.from('rooms').insert(values);

  Future<void> updateRoom(int id, Map<String, dynamic> values) =>
      _client.from('rooms').update(values).eq('id', id);

  Future<void> deleteRoom(int id) =>
      _client.from('rooms').delete().eq('id', id);

  Future<void> createQrCode(Map<String, dynamic> values) =>
      _client.from('qr_codes').insert(values);

  Future<void> updateQrCode(int id, Map<String, dynamic> values) =>
      _client.from('qr_codes').update(values).eq('id', id);

  Future<void> deleteQrCode(int id) =>
      _client.from('qr_codes').delete().eq('id', id);

  Future<void> createFacultyMember(Map<String, dynamic> values) =>
      _client.from('faculty').insert(values);

  Future<void> updateFacultyMember(int id, Map<String, dynamic> values) =>
      _client.from('faculty').update(values).eq('id', id);

  Future<void> deleteFacultyMember(int id) =>
      _client.from('faculty').delete().eq('id', id);

  /// Faculty paired with the name of the room they're assigned to, if any.
  Future<List<(FacultyMember, String?)>> getFacultyWithRoomNames() async {
    final faculty = await getFaculty();
    final rooms = await _client.from('rooms').select('id, room_name');
    final roomNameById = <int, String>{
      for (final row in rooms) row['id'] as int: row['room_name'] as String,
    };
    return faculty
        .map((f) => (f, f.roomId == null ? null : roomNameById[f.roomId]))
        .toList();
  }

  /// Faculty grouped under their college so same-department members
  /// appear together. A null college name means "no college assigned".
  Future<List<(String?, List<(FacultyMember, String?)>)>>
      getFacultyGroupedByCollege() async {
    final facultyWithRooms = await getFacultyWithRoomNames();
    final colleges = await getColleges();
    final collegeNameById = {for (final c in colleges) c.id: c.name};
    final grouped = <int, List<(FacultyMember, String?)>>{};
    final unassigned = <(FacultyMember, String?)>[];
    for (final entry in facultyWithRooms) {
      final cid = entry.$1.collegeId;
      if (cid != null && collegeNameById.containsKey(cid)) {
        grouped.putIfAbsent(cid, () => []).add(entry);
      } else {
        unassigned.add(entry);
      }
    }
    return [
      for (final c in colleges)
        if (grouped.containsKey(c.id)) (c.name, grouped[c.id]!),
      if (unassigned.isNotEmpty) (null, unassigned),
    ];
  }

  Future<QrCodeEntry?> getQrCodeForRoom(int roomId) async {
    final row = await _client
        .from('qr_codes')
        .select()
        .eq('room_id', roomId)
        .maybeSingle();
    return row == null ? null : QrCodeEntry.fromJson(row);
  }

  Future<List<Waypoint>> getWaypoints({int? floor}) async {
    final query = _client.from('waypoints').select();
    final rows = floor == null ? await query : await query.eq('floor', floor);
    return rows.map((row) => Waypoint.fromJson(row)).toList();
  }

  Future<List<PathEdge>> getPaths() async {
    final rows = await _client.from('paths').select();
    return rows.map((row) => PathEdge.fromJson(row)).toList();
  }

  Future<CampusSettings?> getCampusSettings() async {
    final row = await _client.from('campus_info').select().maybeSingle();
    return row == null ? null : CampusSettings.fromJson(row);
  }

  Future<List<College>> getColleges() async {
    final rows = await _client.from('colleges').select();
    return rows.map((row) => College.fromJson(row)).toList();
  }

  Future<void> createCollege(Map<String, dynamic> values) =>
      _client.from('colleges').insert(values);

  Future<void> updateCollege(int id, Map<String, dynamic> values) =>
      _client.from('colleges').update(values).eq('id', id);

  Future<void> deleteCollege(int id) =>
      _client.from('colleges').delete().eq('id', id);

  Future<List<OfficeEntry>> getOfficeEntries() async {
    final rows = await _client.from('offices').select();
    return rows.map((row) => OfficeEntry.fromJson(row)).toList();
  }

  Future<void> createOfficeEntry(Map<String, dynamic> values) =>
      _client.from('offices').insert(values);

  Future<void> updateOfficeEntry(int id, Map<String, dynamic> values) =>
      _client.from('offices').update(values).eq('id', id);

  Future<void> deleteOfficeEntry(int id) =>
      _client.from('offices').delete().eq('id', id);

  Future<List<ServiceEntry>> getServiceEntries() async {
    final rows = await _client.from('services').select();
    return rows.map((row) => ServiceEntry.fromJson(row)).toList();
  }

  Future<void> createServiceEntry(Map<String, dynamic> values) =>
      _client.from('services').insert(values);

  Future<void> updateServiceEntry(int id, Map<String, dynamic> values) =>
      _client.from('services').update(values).eq('id', id);

  Future<void> deleteServiceEntry(int id) =>
      _client.from('services').delete().eq('id', id);

  Future<List<FaqEntry>> getFaqEntries() async {
    final rows = await _client.from('faqs').select();
    return rows.map((row) => FaqEntry.fromJson(row)).toList();
  }

  Future<void> createFaqEntry(Map<String, dynamic> values) =>
      _client.from('faqs').insert(values);

  Future<void> updateFaqEntry(int id, Map<String, dynamic> values) =>
      _client.from('faqs').update(values).eq('id', id);

  Future<void> deleteFaqEntry(int id) =>
      _client.from('faqs').delete().eq('id', id);

  Future<List<LeadershipMember>> getLeadership() async {
    final rows = await _client.from('leadership').select();
    return rows.map((row) => LeadershipMember.fromJson(row)).toList();
  }

  Future<void> createLeadershipMember(Map<String, dynamic> values) =>
      _client.from('leadership').insert(values);

  Future<void> updateLeadershipMember(int id, Map<String, dynamic> values) =>
      _client.from('leadership').update(values).eq('id', id);

  Future<void> deleteLeadershipMember(int id) =>
      _client.from('leadership').delete().eq('id', id);

  /// Campus Info "Heads & Faculty" groups, built live from the [faculty]
  /// table so records managed in the admin appear on the kiosk automatically.
  Future<List<CollegeFacultyGroup>> getCollegeFacultyGroups() async {
    final faculty = await getFaculty();
    final collegeRows = await _client.from('colleges').select('id, name');
    final collegeNameById = <int, String>{
      for (final row in collegeRows) row['id'] as int: row['name'] as String,
    };

    String memberLabel(FacultyMember f) {
      final position = f.position?.trim();
      return (position == null || position.isEmpty)
          ? f.fullname
          : '${f.fullname} — $position';
    }

    final grouped = <int, List<FacultyMember>>{};
    final unassigned = <FacultyMember>[];
    for (final f in faculty) {
      final cid = f.collegeId;
      if (cid != null && collegeNameById.containsKey(cid)) {
        grouped.putIfAbsent(cid, () => []).add(f);
      } else {
        unassigned.add(f);
      }
    }

    final groups = <CollegeFacultyGroup>[];
    for (final row in collegeRows) {
      final id = row['id'] as int;
      final members = grouped[id];
      if (members == null || members.isEmpty) continue;
      groups.add(CollegeFacultyGroup(
        id: id,
        college: collegeNameById[id]!,
        faculty: members.map(memberLabel).join(', '),
        members: members,
      ));
    }
    if (unassigned.isNotEmpty) {
      groups.add(CollegeFacultyGroup(
        id: -1,
        college: 'Other Faculty',
        faculty: unassigned.map(memberLabel).join(', '),
        members: unassigned,
      ));
    }
    return groups;
  }

  Future<void> upsertCampusSettings(Map<String, dynamic> values) async {
    final existing = await _client.from('campus_info').select('id').maybeSingle();
    if (existing != null) {
      await _client.from('campus_info').update(values).eq('id', existing['id']);
    } else {
      await _client.from('campus_info').insert(values);
    }
  }

  bool _isTableMissing(Object e) {
    final m = e.toString().toLowerCase();
    return m.contains('does not exist') ||
        m.contains('schema cache') ||
        m.contains('could not find');
  }

  Future<Map<String, dynamic>?> getKioskSettings() async {
    try {
      final row = await _client.from('kiosk_settings').select().maybeSingle();
      return row;
    } catch (e) {
      if (_isTableMissing(e)) {
        throw Exception(
          'The kiosk_settings table is missing from your database. '
          'Run supabase\\fix_admin_errors.sql in the Supabase SQL Editor, '
          'then tap Retry.',
        );
      }
      rethrow;
    }
  }

  Future<void> upsertKioskSettings(Map<String, dynamic> values) async {
    try {
      final existing =
          await _client.from('kiosk_settings').select('id').maybeSingle();
      if (existing != null) {
        await _client
            .from('kiosk_settings')
            .update(values)
            .eq('id', existing['id']);
      } else {
        await _client.from('kiosk_settings').insert(values);
      }
    } catch (e) {
      if (_isTableMissing(e)) {
        throw Exception(
          'Cannot save: the kiosk_settings table is missing from your '
          'database. Run supabase\\fix_admin_errors.sql in the Supabase '
          'SQL Editor first.',
        );
      }
      rethrow;
    }
  }

  Future<PathfindingResult?> findRoute({
    required int fromWaypointId,
    required int toWaypointId,
  }) async {
    final waypoints = await getWaypoints();
    final paths = await getPaths();
    return Pathfinder.shortestPath(
      waypoints: waypoints,
      edges: paths,
      startId: fromWaypointId,
      endId: toWaypointId,
    );
  }
}
