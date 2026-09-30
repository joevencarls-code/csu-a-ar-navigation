import 'package:flutter/material.dart';
import '../../models/campus_models.dart';
import '../../services/admin_auth.dart';
import '../../services/campus_repository.dart';
import '../../services/pending_change_service.dart';
import 'admin_crud_screen.dart';

class CollegesAdminScreen extends CrudScreen<College> {
  CollegesAdminScreen({
    super.key,
    required AdminUser user,
    bool showBackButton = true,
  }) : super(
          showBackButton: showBackButton,
          title: 'Manage Colleges',
          icon: Icons.school_rounded,
          fields: const [
            CrudField(key: 'name', label: 'College Name', type: CrudFieldType.text, required: true),
            CrudField(key: 'abbrev', label: 'Abbreviation', type: CrudFieldType.text),
            CrudField(key: 'dean', label: 'Dean', type: CrudFieldType.text),
            CrudField(key: 'programs', label: 'Programs (comma-separated)', type: CrudFieldType.text),
            CrudField(key: 'location', label: 'Location', type: CrudFieldType.text),
            CrudField(key: 'description', label: 'Description', type: CrudFieldType.multiline),
          ],
          fetchAll: CampusRepository().getColleges,
          onCreate: user.isSuperAdmin
              ? CampusRepository().createCollege
              : ApprovalQueue(user, 'Colleges', 'colleges').create,
          onUpdate: user.isSuperAdmin
              ? CampusRepository().updateCollege
              : ApprovalQueue(user, 'Colleges', 'colleges').update,
          onDelete: user.isSuperAdmin
              ? CampusRepository().deleteCollege
              : ApprovalQueue(user, 'Colleges', 'colleges').delete,
          requiresApproval: !user.isSuperAdmin,
          idOf: (c) => c.id,
          titleOf: (c) => c.name,
          subtitleOf: (c) => c.dean,
          valuesOf: (c) => {
            'name': c.name,
            'abbrev': c.abbrev,
            'dean': c.dean,
            'programs': c.programs,
            'location': c.location,
            'description': c.description,
          },
        );
}