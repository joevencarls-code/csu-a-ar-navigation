import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_auth.dart';
import '../../services/pending_change_service.dart';
import '../../theme/app_colors.dart';

class ApprovalsAdminScreen extends StatefulWidget {
  final AdminUser user;
  final bool showBackButton;

  const ApprovalsAdminScreen({
    super.key,
    required this.user,
    this.showBackButton = true,
  });

  @override
  State<ApprovalsAdminScreen> createState() => _ApprovalsAdminScreenState();
}

class _ApprovalsAdminScreenState extends State<ApprovalsAdminScreen> {
  final PendingChangeService _service = PendingChangeService();
  late Future<List<PendingChange>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PendingChange>> _load() {
    return _service.getPending();
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  void _showSnack(String message, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? Colors.green.shade700 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  Future<void> _approve(PendingChange pending) async {
    final confirmed = await _confirm(
      title: 'Approve change',
      message:
          'This applies the change to the live data and the kiosk will show it immediately.',
      confirmLabel: 'Approve',
      isApproval: true,
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _service.approve(pending, widget.user);
      _showSnack('Change approved and is now live', success: true);
    } catch (e) {
      _showSnack('Could not approve: $e', success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
      _refresh();
    }
  }

  Future<void> _reject(PendingChange pending) async {
    final confirmed = await _confirm(
      title: 'Reject change',
      message: 'The change will be discarded and not applied to the kiosk.',
      confirmLabel: 'Reject',
      isApproval: false,
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _service.reject(pending, widget.user);
      _showSnack('Change rejected', success: true);
    } catch (e) {
      _showSnack('Could not reject: $e', success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
      _refresh();
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required bool isApproval,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.royalBlueDark,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  isApproval ? Colors.green.shade700 : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
                  _buildContent(),
                ],
              ),
            ),
          ),
        ],
      ),
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
            child: const Icon(
              Icons.verified_user_rounded,
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
                  'Approvals',
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
            'IMS SUPERVISION',
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
          'Pending Approvals',
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
          'Review changes submitted by HRO and Infra admins',
          style: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return FutureBuilder<List<PendingChange>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _buildMessage(
            Icons.error_outline_rounded,
            'Could not load pending changes',
            Colors.red,
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _buildMessage(
            Icons.task_alt_rounded,
            'No pending changes to review',
            AppColors.royalBlue,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.royalBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${items.length} pending change${items.length == 1 ? '' : 's'}',
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
            for (final pending in items) ...[
              _buildChangeCard(pending),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMessage(IconData icon, String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeCard(PendingChange pending) {
    final isCreate = pending.operation == 'create';
    final isDelete = pending.operation == 'delete';
    final Color opColor = isDelete
        ? Colors.red
        : isCreate
            ? Colors.green.shade700
            : Colors.blue.shade700;
    final IconData opIcon = isDelete
        ? Icons.delete_outline_rounded
        : isCreate
            ? Icons.add_rounded
            : Icons.edit_rounded;

    return Container(
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: opColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(opIcon, size: 20, color: opColor),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  pending.operation.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: opColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pending.module,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submitted by ${pending.submittedBy} · ${_roleLabel(pending.role)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(pending.submittedAt),
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pending.data != null) ...[
                    Text(
                      isCreate ? 'Record to create' : 'New values',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.royalBlueDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildValuesList(pending.data, highlightOld: false),
                  ],
                  if (pending.beforeData != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Current values',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildValuesList(pending.beforeData, highlightOld: true),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _reject(pending),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: Text(
                            'Reject',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy ? null : () => _approve(pending),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            'Approve',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValuesList(Map<String, dynamic>? values,
      {required bool highlightOld}) {
    if (values == null || values.isEmpty) {
      return Text(
        'No values recorded',
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
      );
    }
    final rows = values.entries.toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlightOld
            ? Colors.grey.shade50
            : AppColors.royalBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (highlightOld ? Colors.grey : AppColors.royalBlue)
              .withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    rows[i].key,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _displayValue(rows[i].value),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.royalBlueDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _displayValue(dynamic value) {
    if (value == null) return '—';
    final s = value.toString();
    return s.isEmpty ? '—' : s;
  }

  String _roleLabel(String role) {
    final parsed = adminRoleFromString(role);
    return parsed == null ? role : adminRoleLabel(parsed);
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final h = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final date =
        '${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}/${local.year}';
    return '$date at $h:$m $ampm';
  }
}