import 'package:flutter/material.dart';
import '../../models/campus_models.dart';
import '../../services/admin_auth.dart';
import '../../services/campus_repository.dart';
import '../../services/pending_change_service.dart';
import '../../widgets/directory_cards.dart';
import 'admin_crud_screen.dart';

class BuildingsAdminScreen extends CrudScreen<Building> {
  BuildingsAdminScreen({
    super.key,
    required AdminUser user,
    bool showBackButton = true,
  }) : super(
          showBackButton: showBackButton,
          title: 'Manage Buildings',
          icon: Icons.business_rounded,
          fields: const [
            CrudField(key: 'name', label: 'Name', type: CrudFieldType.text, required: true),
            CrudField(key: 'description', label: 'Description', type: CrudFieldType.multiline),
            CrudField(key: 'location', label: 'Location', type: CrudFieldType.text),
            CrudField(key: 'dean', label: 'Dean / Head', type: CrudFieldType.text),
            CrudField(key: 'offices', label: 'Offices (comma-separated)', type: CrudFieldType.text),
            CrudField(key: 'image_url', label: 'Image URL', type: CrudFieldType.text),
          ],
          fetchAll: CampusRepository().getBuildings,
          onCreate: user.isSuperAdmin
              ? CampusRepository().createBuilding
              : ApprovalQueue(user, 'Buildings', 'buildings').create,
          onUpdate: user.isSuperAdmin
              ? CampusRepository().updateBuilding
              : ApprovalQueue(user, 'Buildings', 'buildings').update,
          onDelete: user.isSuperAdmin
              ? CampusRepository().deleteBuilding
              : ApprovalQueue(user, 'Buildings', 'buildings').delete,
          requiresApproval: !user.isSuperAdmin,
          idOf: (b) => b.id,
          titleOf: (b) => b.name,
          subtitleOf: (b) => b.location,
          valuesOf: (b) => {
            'name': b.name,
            'description': b.description,
            'location': b.location,
            'dean': b.dean,
            'offices': b.offices,
            'image_url': b.imageUrl,
          },
          cardBuilder: (b) => BuildingDirectoryCard(building: b),
        );
}