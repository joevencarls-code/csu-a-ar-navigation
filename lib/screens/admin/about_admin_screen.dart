import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/campus_models.dart';
import '../../services/campus_repository.dart';
import '../../theme/app_colors.dart';

class AdminAboutScreen extends StatefulWidget {
  final bool showBackButton;

  const AdminAboutScreen({super.key, this.showBackButton = true});

  @override
  State<AdminAboutScreen> createState() => _AdminAboutScreenState();
}

class _AdminAboutScreenState extends State<AdminAboutScreen> {
  final CampusRepository _repository = CampusRepository();
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _campusNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _executiveOfficerCtrl = TextEditingController();
  final _totalProgramsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _campusNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _executiveOfficerCtrl.dispose();
    _totalProgramsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final settings = await _repository.getCampusSettings();
      if (settings != null) {
        _campusNameCtrl.text = settings.campusName;
        _addressCtrl.text = settings.address ?? '';
        _phoneCtrl.text = settings.phone ?? '';
        _emailCtrl.text = settings.email ?? '';
        _websiteCtrl.text = settings.website ?? '';
        _executiveOfficerCtrl.text = settings.executiveOfficer ?? '';
        _totalProgramsCtrl.text = settings.totalPrograms?.toString() ?? '';
      }
    } catch (e) {
      _error = 'Failed to load campus information: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repository.upsertCampusSettings({
        'campus_name': _campusNameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'executive_officer': _executiveOfficerCtrl.text.trim(),
        'total_programs': int.tryParse(_totalProgramsCtrl.text.trim()),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Campus information saved! Changes appear on the kiosk About screen.'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.red.shade600)),
              const SizedBox(height: 16),
              TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_rounded, color: AppColors.royalBlue, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Campus Information',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.royalBlueDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Edit the information shown on the kiosk About screen.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            _buildField(_campusNameCtrl, 'Campus Name', Icons.account_balance_rounded, required: true),
            const SizedBox(height: 16),
            _buildField(_addressCtrl, 'Address', Icons.location_on_rounded),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField(_phoneCtrl, 'Phone', Icons.phone_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _buildField(_emailCtrl, 'Email', Icons.email_rounded)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField(_websiteCtrl, 'Website', Icons.language_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _buildField(_totalProgramsCtrl, 'Total Programs', Icons.menu_book_rounded, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(_executiveOfficerCtrl, 'Campus Executive Officer', Icons.admin_panel_settings_rounded),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null : null,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppColors.royalBlue.withValues(alpha: 0.6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
