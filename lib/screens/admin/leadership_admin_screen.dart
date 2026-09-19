import 'package:flutter/material.dart';
import '../../models/campus_models.dart';
import '../../services/admin_auth.dart';
import '../../services/campus_repository.dart';
import '../../services/pending_change_service.dart';
import 'admin_crud_screen.dart';

class LeadershipAdminScreen extends CrudScreen<LeadershipMember> {
  LeadershipAdminScreen({
    super.key,
    required AdminUser user,
    bool showBackButton = true,
  }) : super(
          showBackButton: showBackButton,
          title: 'Manage Leadership',
          icon: Icons.workspace_premium_rounded,
          fields: const [
            CrudField(key: 'name', label: 'Full Name', type: CrudFieldType.text, required: true),
            CrudField(key: 'position', label: 'Position (e.g. CEO)', type: CrudFieldType.text),
            CrudField(key: 'department', label: 'Department / Office', type: CrudFieldType.text),
            CrudField(key: 'image_path', label: 'Image Asset Path', type: CrudFieldType.text),
            CrudField(key: 'initials', label: 'Initials (avatar fallback)', type: CrudFieldType.text),
          ],
          fetchAll: CampusRepository().getLeadership,
          onCreate: user.isSuperAdmin
              ? CampusRepository().createLeadershipMember
              : ApprovalQueue(user, 'Leadership', 'leadership').create,
          onUpdate: user.isSuperAdmin
              ? CampusRepository().updateLeadershipMember
              : ApprovalQueue(user, 'Leadership', 'leadership').update,
          onDelete: user.isSuperAdmin
              ? CampusRepository().deleteLeadershipMember
              : ApprovalQueue(user, 'Leadership', 'leadership').delete,
          requiresApproval: !user.isSuperAdmin,
          idOf: (l) => l.id,
          titleOf: (l) => l.name,
          subtitleOf: (l) => l.position,
          valuesOf: (l) => {
            'name': l.name,
            'position': l.position,
            'department': l.department,
            'image_path': l.imagePath,
            'initials': l.initials,
          },
        );
}