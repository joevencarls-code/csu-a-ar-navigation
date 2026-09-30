import 'package:flutter/material.dart';
import '../../models/campus_models.dart';
import '../../services/campus_repository.dart';
import 'admin_crud_screen.dart';

class FaqsAdminScreen extends CrudScreen<FaqEntry> {
  FaqsAdminScreen({super.key, bool showBackButton = true}) : super(
          showBackButton: showBackButton,
          title: 'Manage FAQs',
          icon: Icons.help_outline_rounded,
          fields: const [
            CrudField(key: 'question', label: 'Question', type: CrudFieldType.multiline, required: true),
            CrudField(key: 'answer', label: 'Answer', type: CrudFieldType.multiline),
          ],
          fetchAll: CampusRepository().getFaqEntries,
          onCreate: CampusRepository().createFaqEntry,
          onUpdate: CampusRepository().updateFaqEntry,
          onDelete: CampusRepository().deleteFaqEntry,
          idOf: (f) => f.id,
          titleOf: (f) => f.question,
          subtitleOf: (f) => f.answer,
          valuesOf: (f) => {
            'question': f.question,
            'answer': f.answer,
          },
        );
}
