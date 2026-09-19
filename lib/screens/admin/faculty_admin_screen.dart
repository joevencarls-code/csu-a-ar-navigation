import 'package:flutter/material.dart';
import '../../models/campus_models.dart';
import '../../services/admin_auth.dart';
import '../../services/campus_repository.dart';
import '../../services/pending_change_service.dart';
import '../../widgets/directory_cards.dart';
import 'admin_crud_screen.dart';

class FacultyAdminScreen extends CrudScreen<FacultyMember> {
  FacultyAdminScreen({
    super.key,
    required AdminUser user,
    bool showBackButton = true,
  }) : super(
          showBackButton: showBackButton,
          title: 'Manage Faculty',
          icon: Icons.school_rounded,
          fields: [
            const CrudField(key: 'fullname', label: 'Full Name', type: CrudFieldType.text, required: true),
            const CrudField(key: 'position', label: 'Position', type: CrudFieldType.text),
            const CrudField(key: 'email', label: 'Email', type: CrudFieldType.text),
            const CrudField(key: 'image_url', label: 'Image URL', type: CrudFieldType.text),
            CrudField(
              key: 'college_id',
              label: 'College',
              type: CrudFieldType.reference,
              loadOptions: () async {
                final colleges = await CampusRepository().getColleges();
                return colleges
                    .map((c) => CrudReferenceOption(c.id, c.name))
                    .toList();
              },
            ),
            CrudField(
              key: 'room_id',
              label: 'Room',
              type: CrudFieldType.reference,
              loadOptions: () async {
                final rooms = await CampusRepository().getAllRooms();
                return rooms
                    .map((r) => CrudReferenceOption(r.id, r.roomName))
                    .toList();
              },
            ),
          ],
          fetchAll: CampusRepository().getFaculty,
          onCreate: user.isSuperAdmin
              ? CampusRepository().createFacultyMember
              : ApprovalQueue(user, 'Faculty', 'faculty').create,
          onUpdate: user.isSuperAdmin
              ? CampusRepository().updateFacultyMember
              : ApprovalQueue(user, 'Faculty', 'faculty').update,
          onDelete: user.isSuperAdmin
              ? CampusRepository().deleteFacultyMember
              : ApprovalQueue(user, 'Faculty', 'faculty').delete,
          requiresApproval: !user.isSuperAdmin,
          idOf: (f) => f.id,
          titleOf: (f) => f.fullname,
          subtitleOf: (f) => f.position,
          valuesOf: (f) => {
            'fullname': f.fullname,
            'position': f.position,
            'email': f.email,
            'image_url': f.imageUrl,
            'room_id': f.roomId,
            'college_id': f.collegeId,
          },
          cardBuilder: (f) => FacultyDirectoryCard(member: f),
        );
}