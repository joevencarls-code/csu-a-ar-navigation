import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/campus_models.dart';
import '../theme/app_colors.dart';
import 'directory_cards.dart';
import 'faculty_id_card.dart';

/// A single labelled value shown inside the enlarged directory view.
class DirectoryDetailField {
  const DirectoryDetailField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

/// Enlarged, kiosk-friendly view of a directory entry. Shows the full
/// description and every stored field, which the grid cards have to
/// truncate.
class DirectoryDetailDialog extends StatelessWidget {
  const DirectoryDetailDialog({
    super.key,
    required this.title,
    this.accent = AppColors.royalBlue,
    this.subtitle,
    this.badge,
    this.imageUrl,
    this.fallbackIcon = Icons.info_outline_rounded,
    this.fields = const [],
    this.listTitle,
    this.listItems = const [],
    this.futureListTitle,
    this.futureListItems,
    this.facultyTitle,
    this.futureFaculty,
    this.squareHero = false,
    this.centerContent = false,
    this.showcase = false,
  });

  final String title;
  final Color accent;
  final String? subtitle;
  final String? badge;
  final String? imageUrl;
  final IconData fallbackIcon;
  final List<DirectoryDetailField> fields;
  final String? listTitle;
  final List<String> listItems;
  final String? futureListTitle;
  final Future<List<String>>? futureListItems;
  final String? facultyTitle;
  final Future<List<FacultyMember>>? futureFaculty;

  /// Renders the header photo as a square panel instead of a wide banner so
  /// portrait headshots keep the full face instead of being cropped.
  final bool squareHero;

  /// Centers every piece of the entry's info — badge, name, subtitle and
  /// field rows — instead of aligning them to the left edge.
  final bool centerContent;

  /// Branded, portrait-style layout used by the faculty popup: a gradient
  /// header holding the photo, position pill, name and college, followed by
  /// tappable info cards and a large footer action. Only title, badge,
  /// subtitle, imageUrl and fields are rendered in this mode.
  final bool showcase;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: showcase
            ? _ShowcaseShell(dialog: this)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(child: _buildBody(context)),
                  ),
                  _buildFooter(context),
                ],
              ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: centerContent
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        _buildHero(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
          child: Column(
            crossAxisAlignment: centerContent
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if ((badge ?? '').isNotEmpty) ...[
                _centered(_buildBadge()),
                const SizedBox(height: 10),
              ],
              Text(
                title,
                textAlign: centerContent ? TextAlign.center : TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.royalBlueDark,
                  height: 1.2,
                ),
              ),
              if ((subtitle ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildSubtitle(),
              ],
              if (fields.isNotEmpty || listItems.isNotEmpty) ...[
                const SizedBox(height: 22),
                for (final field in fields) _buildField(field),
              ],
              if (listItems.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildListSection(
                  listTitle ?? 'Details',
                  listItems,
                  Icons.checklist_rounded,
                ),
              ],
              if (futureListItems != null) ...[
                const SizedBox(height: 18),
                _buildFutureListSection(),
              ],
              if (futureFaculty != null) ...[
                const SizedBox(height: 22),
                _buildFacultySection(context),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    if (squareHero) return _buildSquareHero(context, url);

    const height = 210.0;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url.isEmpty)
            _buildHeroFallback()
          else
            Image(
              image: url.startsWith('assets/')
                  ? AssetImage(url)
                  : NetworkImage(url),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildHeroFallback(),
            ),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  /// Square, face-framing header photo used by the faculty popup. The image
  /// is letterboxed rather than cropped, so the whole face stays visible no
  /// matter the source aspect ratio.
  Widget _buildSquareHero(BuildContext context, String url) {
    final shortest = MediaQuery.of(context).size.shortestSide;
    final frame = (shortest * 0.3).clamp(150.0, 250.0);
    return SizedBox(
      height: frame + 56,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Container(
              width: frame,
              height: frame,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: url.isEmpty
                  ? _buildHeroFallback()
                  : Image(
                      image: url.startsWith('assets/')
                          ? AssetImage(url)
                          : NetworkImage(url),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildHeroFallback(),
                    ),
            ),
          ),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      top: 14,
      right: 14,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.all(9),
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.royalBlueDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: 72,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// Wraps [child] in a [Center] when the popup uses the centered layout.
  Widget _centered(Widget child) =>
      centerContent ? Center(child: child) : child;

  /// Location / department line under the title. In the centered layout the
  /// icon and text stay grouped together and the whole group is centered.
  Widget _buildSubtitle() {
    const pin = Icon(
      Icons.location_on_rounded,
      size: 16,
      color: AppColors.gold,
    );
    final label = Text(
      subtitle!,
      textAlign: centerContent ? TextAlign.center : TextAlign.left,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      ),
    );
    if (centerContent) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pin,
          const SizedBox(width: 6),
          Flexible(child: label),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pin,
        const SizedBox(width: 6),
        Expanded(child: label),
      ],
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        badge!.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF9C7A00),
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildField(DirectoryDetailField field) {
    if (centerContent) return _buildCenteredField(field);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(field.icon, size: 18, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  field.value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.royalBlueDark,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Stacked, centered version of a field: icon above the label and value,
  /// all aligned to the middle of the popup.
  Widget _buildCenteredField(DirectoryDetailField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(field.icon, size: 18, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            field.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            field.value,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.royalBlueDark,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.royalBlueDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.14)),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                      height: 1.35,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFutureListSection() {
    final sectionTitle = futureListTitle ?? 'Details';
    return FutureBuilder<List<String>>(
      future: futureListItems,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(sectionTitle, Icons.door_front_door_rounded),
              const SizedBox(height: 14),
              const LinearProgressIndicator(minHeight: 3),
            ],
          );
        }
        if (snapshot.hasError) {
          return _buildSectionTitle(
            sectionTitle,
            Icons.door_front_door_rounded,
          );
        }
        final items = snapshot.data ?? const <String>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return _buildListSection(
          sectionTitle,
          items,
          Icons.door_front_door_rounded,
        );
      },
    );
  }

  Widget _buildFacultySection(BuildContext context) {
    final sectionTitle = (facultyTitle ?? 'Faculty').trim();
    return FutureBuilder<List<FacultyMember>>(
      future: futureFaculty,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(sectionTitle, Icons.groups_rounded),
              const SizedBox(height: 14),
              const LinearProgressIndicator(minHeight: 3),
            ],
          );
        }
        if (snapshot.hasError) {
          return _buildSectionTitle(sectionTitle, Icons.groups_rounded);
        }
        final members = orderCollegeFaculty(
          snapshot.data ?? const <FacultyMember>[],
        );
        if (members.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(sectionTitle, Icons.groups_rounded),
              const SizedBox(height: 10),
              Text(
                'No faculty listed for this college yet.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              '$sectionTitle (${members.length})',
              Icons.groups_rounded,
            ),
            const SizedBox(height: 12),
            _buildFacultyScrollList(context, members),
          ],
        );
      },
    );
  }

  /// Keeps a long roster inside its own scroll area so the rest of the
  /// detail view stays reachable on a kiosk screen.
  Widget _buildFacultyScrollList(
    BuildContext context,
    List<FacultyMember> members,
  ) {
    final maxHeight = MediaQuery.of(context).size.height * 0.4;
    return _FacultyScrollList(
      members: members,
      collegeName: title,
      maxHeight: maxHeight.clamp(240.0, 460.0),
      onSelect: (member) =>
          showFacultyDetailDialog(context, member, collegeName: title),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.royalBlueDark,
            ),
          ),
        ),
      ],
    );
  }

  /// Gradient banner holding the photo, position pill, name and college —
  /// the "ID card" header of the showcase layout.
  Widget _buildShowcaseHeader(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    final shortest = MediaQuery.of(context).size.shortestSide;
    final frame = (shortest * 0.26).clamp(132.0, 210.0);
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 54, 24, 26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.royalBlueLight,
                AppColors.royalBlue,
                AppColors.royalBlueDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: const Border(
              bottom: BorderSide(color: AppColors.gold, width: 4),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlueDark.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildShowcasePhoto(url, frame),
              if ((badge ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                _buildShowcasePill(),
              ],
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              if ((subtitle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildShowcaseCollegeChip(),
              ],
            ],
          ),
        ),
        _buildCloseButton(context),
      ],
    );
  }

  Widget _buildShowcasePhoto(String url, double frame) {
    return Container(
      width: frame,
      height: frame,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: url.isEmpty
            ? _buildShowcaseInitials(frame)
            : Image(
                image: url.startsWith('assets/')
                    ? AssetImage(url)
                    : NetworkImage(url),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildShowcaseInitials(frame),
              ),
      ),
    );
  }

  Widget _buildShowcaseInitials(double frame) {
    return ColoredBox(
      color: const Color(0xFFF5F7FA),
      child: Center(
        child: Text(
          directoryInitialsOf(title),
          style: GoogleFonts.poppins(
            fontSize: frame * 0.26,
            fontWeight: FontWeight.w800,
            color: AppColors.royalBlue.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  Widget _buildShowcasePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.45),
            blurRadius: 14,
          ),
        ],
      ),
      child: Text(
        badge!.trim().toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppColors.royalBlueDark,
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  Widget _buildShowcaseCollegeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.school_rounded, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowcaseSectionTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.contact_mail_rounded,
          size: 17,
          color: Color(0xFF9C7A00),
        ),
        const SizedBox(width: 8),
        Text(
          'CONTACT',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey[600],
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }

  /// Footer of the showcase layout: a big centered Copy + Close pair so the
  /// kiosk user always has an obvious touch target.
  Widget _buildShowcaseFooter(
    BuildContext context, {
    required VoidCallback? onCopy,
    required bool copied,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.12))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (onCopy != null) ...[
            OutlinedButton.icon(
              onPressed: onCopy,
              icon: Icon(
                copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 18,
              ),
              label: Text(copied ? 'Copied' : 'Copy ${fields.first.label}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.royalBlue,
                side: BorderSide(
                  color: AppColors.royalBlue.withValues(alpha: 0.45),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Close'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.royalBlueDark,
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(top: BorderSide(color: accent.withValues(alpha: 0.12))),
      ),
      child: Row(
        mainAxisAlignment: centerContent
            ? MainAxisAlignment.center
            : MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Close'),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns the clipboard feedback state for the showcase layout so the info
/// cards and the footer Copy button stay in sync.
class _ShowcaseShell extends StatefulWidget {
  const _ShowcaseShell({required this.dialog});

  final DirectoryDetailDialog dialog;

  @override
  State<_ShowcaseShell> createState() => _ShowcaseShellState();
}

class _ShowcaseShellState extends State<_ShowcaseShell> {
  Timer? _timer;
  int? _copiedIndex;

  DirectoryDetailDialog get _d => widget.dialog;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy(int index) async {
    await Clipboard.setData(ClipboardData(text: _d.fields[index].value));
    if (!mounted) return;
    setState(() => _copiedIndex = index);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fields = _d.fields;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: _d.centerContent
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                _d._buildShowcaseHeader(context),
                if (fields.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _d._buildShowcaseSectionTitle(),
                        const SizedBox(height: 14),
                        for (var i = 0; i < fields.length; i++) ...[
                          _ShowcaseFieldCard(
                            field: fields[i],
                            accent: _d.accent,
                            copied: _copiedIndex == i,
                            onTap: () => _copy(i),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'Tap a card to copy it',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        _d._buildShowcaseFooter(
          context,
          onCopy: fields.isEmpty ? null : () => _copy(0),
          copied: _copiedIndex != null,
        ),
      ],
    );
  }
}

/// Centered, tappable card for one piece of a showcase entry. Copies its
/// value on tap and swaps the hint for a green confirmation for two seconds.
class _ShowcaseFieldCard extends StatelessWidget {
  const _ShowcaseFieldCard({
    required this.field,
    required this.accent,
    required this.copied,
    required this.onTap,
  });

  final DirectoryDetailField field;
  final Color accent;
  final bool copied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: copied
              ? const Color(0xFF1B8E3C).withValues(alpha: 0.55)
              : accent.withValues(alpha: 0.6),
          width: copied ? 1.6 : 1.2,
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C7A00).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(field.icon, size: 20, color: Color(0xFF9C7A00)),
              ),
              const SizedBox(height: 10),
              Text(
                field.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                field.value,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.royalBlueDark,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: copied
                    ? Row(
                        key: const ValueKey('copied'),
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Color(0xFF1B8E3C),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Copied to clipboard',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B8E3C),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Tap to copy',
                        key: const ValueKey('hint'),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fixed-height, internally scrollable roster of a college's faculty,
/// rendered with the same [FacultyIdCard] the Directory uses. Owns its own
/// [ScrollController] so the scrollbar tracks the list rather than the
/// dialog body it is nested in.
class _FacultyScrollList extends StatefulWidget {
  const _FacultyScrollList({
    required this.members,
    required this.collegeName,
    required this.maxHeight,
    this.onSelect,
  });

  final List<FacultyMember> members;
  final String? collegeName;
  final double maxHeight;
  final ValueChanged<FacultyMember>? onSelect;

  @override
  State<_FacultyScrollList> createState() => _FacultyScrollListState();
}

class _FacultyScrollListState extends State<_FacultyScrollList> {
  late final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: Scrollbar(
        controller: _controller,
        child: ListView.separated(
          controller: _controller,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: widget.members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final member = widget.members[index];
            return FacultyIdCard(
              fullname: member.fullname,
              position: member.position,
              imageUrl: member.imageUrl,
              department: widget.collegeName,
              email: member.email,
              photoSize: 100,
              showTapHint: widget.onSelect != null,
              onTap: widget.onSelect == null
                  ? null
                  : () => widget.onSelect!(member),
            );
          },
        ),
      ),
    );
  }
}

Future<void> showBuildingDetailDialog(
  BuildContext context,
  Building building, {
  Future<List<String>> Function()? loadRooms,
}) {
  final offices = _splitListValue(building.offices);
  return showDialog<void>(
    context: context,
    builder: (_) => DirectoryDetailDialog(
      title: building.name,
      subtitle: _clean(building.location),
      imageUrl: building.imageUrl,
      fallbackIcon: Icons.account_balance_rounded,
      fields: [
        if (_clean(building.dean).isNotEmpty)
          DirectoryDetailField(
            icon: Icons.school_rounded,
            label: 'Dean / Head',
            value: building.dean!,
          ),
        if (_clean(building.description).isNotEmpty)
          DirectoryDetailField(
            icon: Icons.info_rounded,
            label: 'About',
            value: building.description!,
          ),
      ],
      listTitle: 'Offices',
      listItems: offices,
      futureListTitle: 'Rooms',
      futureListItems: loadRooms?.call(),
    ),
  );
}

Future<void> showOfficeDetailDialog(BuildContext context, OfficeEntry office) {
  return showDialog<void>(
    context: context,
    builder: (_) => DirectoryDetailDialog(
      title: office.name,
      accent: const Color(0xFFB8860B),
      subtitle: _clean(office.purpose),
      badge: _clean(office.abbreviation),
      imageUrl: office.imageUrl,
      fallbackIcon: Icons.apartment_rounded,
      fields: [
        if (_clean(office.location).isNotEmpty)
          DirectoryDetailField(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: office.location!,
          ),
        if (_clean(office.head).isNotEmpty)
          DirectoryDetailField(
            icon: Icons.person_rounded,
            label: 'Head / Person in Charge',
            value: office.head!,
          ),
        if (_clean(office.contact).isNotEmpty)
          DirectoryDetailField(
            icon: Icons.phone_rounded,
            label: 'Contact',
            value: office.contact!,
          ),
      ],
    ),
  );
}

/// Enlarged view of a single faculty member, reached by tapping their card
/// inside a college's popup.
Future<void> showFacultyDetailDialog(
  BuildContext context,
  FacultyMember member, {
  String? collegeName,
}) {
  final position = _clean(member.position);
  final email = _clean(member.email);
  final college = _clean(collegeName);
  return showDialog<void>(
    context: context,
    builder: (_) => DirectoryDetailDialog(
      title: member.fullname,
      accent: AppColors.gold,
      subtitle: college.isEmpty ? null : college,
      badge: position.isEmpty ? null : position,
      imageUrl: member.imageUrl,
      fallbackIcon: Icons.person_rounded,
      squareHero: true,
      centerContent: true,
      showcase: true,
      fields: [
        if (email.isNotEmpty)
          DirectoryDetailField(
            icon: Icons.email_rounded,
            label: 'Email',
            value: email,
          ),
      ],
    ),
  );
}

Future<void> showCollegeDetailDialog(
  BuildContext context,
  College college, {
  Future<List<FacultyMember>> Function()? loadFaculty,
}) {
  final abbrev = _clean(college.abbrev);
  return showDialog<void>(
    context: context,
    builder: (_) => DirectoryDetailDialog(
      title: college.name,
      subtitle: _clean(college.location),
      badge: abbrev.isNotEmpty ? abbrev : directoryInitialsOf(college.name),
      fallbackIcon: Icons.school_rounded,
      fields: [
        if (_clean(college.dean).isNotEmpty)
          DirectoryDetailField(
            icon: Icons.school_rounded,
            label: 'Dean',
            value: college.dean!,
          ),
        if (_clean(college.description).isNotEmpty)
          DirectoryDetailField(
            icon: Icons.info_rounded,
            label: 'About',
            value: college.description!,
          ),
      ],
      listTitle: 'Programs',
      listItems: _splitListValue(college.programs),
      facultyTitle: 'Faculty',
      futureFaculty: loadFaculty?.call(),
    ),
  );
}

/// Human-readable one-liner for a room, used by the building detail view.
String formatRoomLabel(Room room) {
  final parts = <String>[room.roomName.trim()];
  final type = _clean(room.roomType);
  if (type.isNotEmpty) parts.add(type);
  if (room.floor != null) parts.add('Floor ${room.floor}');
  return parts.join(' • ');
}

List<String> _splitListValue(String? value) {
  final raw = _clean(value);
  if (raw.isEmpty) return const [];
  return raw
      .split(RegExp(r'[,;\n]'))
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}

String _clean(String? value) => (value ?? '').trim();
