import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

enum CrudFieldType { text, multiline, integer, decimal, reference }

class CrudReferenceOption {
  final int id;
  final String label;

  CrudReferenceOption(this.id, this.label);
}

class CrudField {
  final String key;
  final String label;
  final CrudFieldType type;
  final bool required;

  final Future<List<CrudReferenceOption>> Function()? loadOptions;

  const CrudField({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.loadOptions,
  });
}

class CrudScreen<T> extends StatefulWidget {
  final String title;
  final IconData? icon;
  final List<CrudField> fields;
  final Future<List<T>> Function() fetchAll;
  final Future<void> Function(Map<String, dynamic> values) onCreate;
  final Future<void> Function(int id, Map<String, dynamic> values) onUpdate;
  final Future<void> Function(int id) onDelete;
  final int Function(T item) idOf;
  final String Function(T item) titleOf;
  final String? Function(T item)? subtitleOf;
  final Map<String, dynamic> Function(T item) valuesOf;
  final Widget Function(T item)? cardBuilder;
  final bool showBackButton;
  final bool requiresApproval;

  const CrudScreen({
    super.key,
    required this.title,
    this.icon,
    required this.fields,
    required this.fetchAll,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
    required this.idOf,
    required this.titleOf,
    this.subtitleOf,
    required this.valuesOf,
    this.cardBuilder,
    this.showBackButton = true,
    this.requiresApproval = false,
  });

  @override
  State<CrudScreen<T>> createState() => _CrudScreenState<T>();
}

class _CrudScreenState<T> extends State<CrudScreen<T>> {
  late Future<List<T>> _future;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = widget.fetchAll();
    });
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openForm({T? item}) async {
    final initialValues = item == null ? <String, dynamic>{} : widget.valuesOf(item);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _CrudFormDialog(
        title: widget.title,
        fields: widget.fields,
        initialValues: initialValues,
        isEditing: item != null,
      ),
    );
    if (result == null) return;
    try {
      if (item == null) {
        await widget.onCreate(result);
      } else {
        await widget.onUpdate(widget.idOf(item), result);
      }
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.requiresApproval
                  ? (item == null
                      ? 'Change submitted for the IMS Super Admin to approve'
                      : 'Changes submitted for the IMS Super Admin to approve')
                  : (item == null
                      ? 'Record created successfully'
                      : 'Record updated successfully'),
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmDelete(T item) async {
    final name = widget.titleOf(item);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Delete Record'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name"?\nThis action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.onDelete(widget.idOf(item));
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.requiresApproval
                  ? 'Deletion submitted for the IMS Super Admin to approve'
                  : 'Record deleted successfully',
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  List<T> _filterItems(List<T> items) {
    if (_searchQuery.isEmpty) return items;
    return items.where((item) {
      final title = widget.titleOf(item).toLowerCase();
      final subtitle = widget.subtitleOf?.call(item)?.toLowerCase() ?? '';
      return title.contains(_searchQuery.toLowerCase()) ||
          subtitle.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 24,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 24),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  _buildContent(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.royalBlueDark, Color(0xFF001A3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          if (widget.showBackButton) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon ?? Icons.table_rows_rounded,
              size: 24,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'CSU-A Kiosk Management',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'DATA MANAGEMENT',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.title.replaceFirst('Manage ', ''),
          style: GoogleFonts.poppins(
            color: AppColors.royalBlue,
            fontWeight: FontWeight.w800,
            fontSize: 32,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Add, edit, or remove records',
          style: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search records...',
          hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        final items = _filterItems(snapshot.data ?? []);
        if (items.isEmpty) {
          return _buildEmptyState();
        }
        return _buildItemsList(items);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.royalBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading data...',
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 40, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.royalBlueDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon ?? Icons.table_rows_rounded,
                size: 48,
                color: AppColors.royalBlue.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty ? 'No matching records' : 'No Records Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.royalBlueDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Tap the + button to add your first record',
              style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(List<T> items) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.royalBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.royalBlue),
              const SizedBox(width: 8),
              Text(
                '${items.length} record${items.length == 1 ? '' : 's'} found',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.royalBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (widget.cardBuilder != null)
          _buildCardGrid(items)
        else
          ...items.map((item) => _buildItemCard(item)),
      ],
    );
  }

  Widget _buildCardGrid(List<T> items) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = _gridColumnCount(constraints.maxWidth);
      final spacing = 16.0;
      final itemWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: 14,
        children: [
          for (final item in items)
            SizedBox(
              width: itemWidth,
              child: _buildItemCard(item),
            ),
        ],
      );
    });
  }

  int _gridColumnCount(double width) {
    if (width >= 1300) return 4;
    if (width >= 950) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  Widget _buildItemCard(T item) {
    final custom = widget.cardBuilder;
    if (custom != null) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => _openForm(item: item),
            child: custom(item),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOverlayActionButton(
                  icon: Icons.edit_rounded,
                  color: AppColors.royalBlue,
                  onTap: () => _openForm(item: item),
                ),
                const SizedBox(width: 6),
                _buildOverlayActionButton(
                  icon: Icons.delete_rounded,
                  color: Colors.red,
                  onTap: () => _confirmDelete(item),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final subtitle = widget.subtitleOf?.call(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _openForm(item: item),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon ?? Icons.table_rows_rounded,
                    size: 22,
                    color: AppColors.royalBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titleOf(item),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.royalBlueDark,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      color: AppColors.royalBlue,
                      onTap: () => _openForm(item: item),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      color: Colors.red,
                      onTap: () => _confirmDelete(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildOverlayActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => _openForm(),
      backgroundColor: AppColors.royalBlue,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      label: Text(
        'Add Record',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CrudFormDialog extends StatefulWidget {
  final String title;
  final List<CrudField> fields;
  final Map<String, dynamic> initialValues;
  final bool isEditing;

  const _CrudFormDialog({
    required this.title,
    required this.fields,
    required this.initialValues,
    required this.isEditing,
  });

  @override
  State<_CrudFormDialog> createState() => _CrudFormDialogState();
}

class _CrudFormDialogState extends State<_CrudFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, int?> _referenceValues = {};
  final Map<String, List<CrudReferenceOption>> _referenceOptions = {};
  bool _loadingOptions = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      if (field.type == CrudFieldType.reference) {
        _referenceValues[field.key] = widget.initialValues[field.key] as int?;
      } else {
        _controllers[field.key] = TextEditingController(
          text: widget.initialValues[field.key]?.toString() ?? '',
        );
      }
    }
    _loadReferenceOptions();
  }

  Future<void> _loadReferenceOptions() async {
    for (final field in widget.fields) {
      if (field.type == CrudFieldType.reference && field.loadOptions != null) {
        _referenceOptions[field.key] = await field.loadOptions!();
      }
    }
    if (mounted) setState(() => _loadingOptions = false);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final values = <String, dynamic>{};
    for (final field in widget.fields) {
      switch (field.type) {
        case CrudFieldType.text:
        case CrudFieldType.multiline:
          final text = _controllers[field.key]!.text.trim();
          values[field.key] = text.isEmpty ? null : text;
        case CrudFieldType.integer:
          final text = _controllers[field.key]!.text.trim();
          values[field.key] = text.isEmpty ? null : int.tryParse(text);
        case CrudFieldType.decimal:
          final text = _controllers[field.key]!.text.trim();
          values[field.key] = text.isEmpty ? null : double.tryParse(text);
        case CrudFieldType.reference:
          values[field.key] = _referenceValues[field.key];
      }
    }
    Navigator.of(context).pop(values);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTitle(),
            Flexible(
              child: _loadingOptions
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.fields.map(_buildField).toList(),
                        ),
                      ),
                    ),
            ),
            if (!_loadingOptions) _buildFormActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.royalBlueDark, AppColors.royalBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.isEditing ? Icons.edit_rounded : Icons.add_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing ? 'Edit Record' : 'Add New Record',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.royalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.isEditing ? 'Save Changes' : 'Create Record',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(CrudField field) {
    if (field.type == CrudFieldType.reference) {
      final options = _referenceOptions[field.key] ?? [];
      final storedValue = _referenceValues[field.key];
      final optionIds = options.map((o) => o.id).toSet();
      final value =
          storedValue != null && optionIds.contains(storedValue)
              ? storedValue
              : null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<int?>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 320,
          decoration: InputDecoration(
            labelText: field.label,
            labelStyle: GoogleFonts.inter(fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: [
            if (!field.required)
              const DropdownMenuItem<int?>(value: null, child: Text('None')),
            ...options.map(
              (o) => DropdownMenuItem<int?>(
                value: o.id,
                child: Text(
                  o.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (value) =>
              setState(() => _referenceValues[field.key] = value),
          validator: field.required
              ? (value) => value == null ? '${field.label} is required' : null
              : null,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[field.key],
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          labelText: field.label,
          labelStyle: GoogleFonts.inter(fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.royalBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: switch (field.type) {
          CrudFieldType.integer => TextInputType.number,
          CrudFieldType.decimal =>
            const TextInputType.numberWithOptions(decimal: true),
          _ => TextInputType.text,
        },
        maxLines: field.type == CrudFieldType.multiline ? 3 : 1,
        validator: field.required
            ? (value) => (value == null || value.trim().isEmpty)
                ? '${field.label} is required'
                : null
            : null,
      ),
    );
  }
}