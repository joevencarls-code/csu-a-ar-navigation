import 'package:flutter/material.dart';
import '../../models/campus_models.dart';
import '../../services/campus_repository.dart';
import 'admin_crud_screen.dart';

class ServicesAdminScreen extends CrudScreen<ServiceEntry> {
  ServicesAdminScreen({super.key, bool showBackButton = true}) : super(
          showBackButton: showBackButton,
          title: 'Manage Services',
          icon: Icons.miscellaneous_services_rounded,
          fields: const [
            CrudField(key: 'name', label: 'Service Name', type: CrudFieldType.text, required: true),
            CrudField(key: 'description', label: 'Description', type: CrudFieldType.multiline),
          ],
          fetchAll: CampusRepository().getServiceEntries,
          onCreate: CampusRepository().createServiceEntry,
          onUpdate: CampusRepository().updateServiceEntry,
          onDelete: CampusRepository().deleteServiceEntry,
          idOf: (s) => s.id,
          titleOf: (s) => s.name,
          subtitleOf: (s) => s.description,
          valuesOf: (s) => {
            'name': s.name,
            'description': s.description,
          },
        );
}
