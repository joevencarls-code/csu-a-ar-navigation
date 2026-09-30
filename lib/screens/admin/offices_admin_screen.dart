import 'package:flutter/material.dart';
import '../../models/campus_models.dart';
import '../../services/admin_auth.dart';
import '../../services/campus_repository.dart';
import '../../services/pending_change_service.dart';
import '../../widgets/directory_cards.dart';
import 'admin_crud_screen.dart';

class OfficesAdminScreen extends CrudScreen<OfficeEntry> {
  OfficesAdminScreen({
    super.key,
    required AdminUser user,
    bool showBackButton = true,
  }) : super(
          showBackButton: showBackButton,
          title: 'Manage Offices',
          icon: Icons.apartment_rounded,
          fields: const [
            CrudField(key: 'name', label: 'Office Name', type: CrudFieldType.text, required: true),
            CrudField(key: 'abbreviation', label: 'Abbreviation', type: CrudFieldType.text),
            CrudField(key: 'location', label: 'Location', type: CrudFieldType.text),
            CrudField(key: 'head', label: 'Head', type: CrudFieldType.text),
            CrudField(key: 'purpose', label: 'Purpose', type: CrudFieldType.multiline),
            CrudField(key: 'contact', label: 'Contact', type: CrudFieldType.text),
            CrudField(key: 'image_url', label: 'Image URL', type: CrudFieldType.text),
          ],
          fetchAll: CampusRepository().getOfficeEntries,
          onCreate: user.isSuperAdmin
              ? CampusRepository().createOfficeEntry
              : ApprovalQueue(user, 'Offices', 'offices').create,
          onUpdate: user.isSuperAdmin
              ? CampusRepository().updateOfficeEntry
              : ApprovalQueue(user, 'Offices', 'offices').update,
          onDelete: user.isSuperAdmin
              ? CampusRepository().deleteOfficeEntry
              : ApprovalQueue(user, 'Offices', 'offices').delete,
          requiresApproval: !user.isSuperAdmin,
          idOf: (o) => o.id,
          titleOf: (o) => o.name,
          subtitleOf: (o) => o.location,
          valuesOf: (o) => {
            'name': o.name,
            'abbreviation': o.abbreviation,
            'location': o.location,
            'head': o.head,
            'purpose': o.purpose,
            'contact': o.contact,
            'image_url': o.imageUrl,
          },
          cardBuilder: (o) => OfficeDirectoryCard(office: o),
        );
}