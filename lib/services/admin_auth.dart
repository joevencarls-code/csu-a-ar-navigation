import 'package:supabase_flutter/supabase_flutter.dart';

enum AdminRole { imsSuperAdmin, hroAdmin, infraAdmin }

AdminRole? adminRoleFromString(String? value) {
  return switch (value) {
    'ims_super_admin' => AdminRole.imsSuperAdmin,
    'hro_admin' => AdminRole.hroAdmin,
    'infra_admin' => AdminRole.infraAdmin,
    _ => null,
  };
}

String adminRoleLabel(AdminRole role) {
  return switch (role) {
    AdminRole.imsSuperAdmin => 'IMS Super Admin',
    AdminRole.hroAdmin => 'HRO Admin',
    AdminRole.infraAdmin => 'Infra Admin',
  };
}

class AdminUser {
  final String email;
  final AdminRole role;

  const AdminUser({required this.email, required this.role});

  bool get isSuperAdmin => role == AdminRole.imsSuperAdmin;

  String get roleKey {
    return switch (role) {
      AdminRole.imsSuperAdmin => 'ims_super_admin',
      AdminRole.hroAdmin => 'hro_admin',
      AdminRole.infraAdmin => 'infra_admin',
    };
  }

  String get roleLabel => adminRoleLabel(role);

  String get initials {
    final parts = email.split('@').first
        .replaceAll('.', ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AD';
    final first = parts.first;
    if (parts.length == 1) {
      return first.length >= 2 ? first.substring(0, 2).toUpperCase() : first.toUpperCase();
    }
    return '${first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Returns true when the given role may use [module].
///
/// Modules:
/// - approvals -> IMS Super Admin only
/// - buildings -> IMS Super Admin + Infra Admin
/// - faculty, colleges, offices, leadership -> IMS Super Admin + HRO Admin
bool adminCanAccess(AdminRole role, String module) {
  return switch (module) {
    'approvals' =>
      role == AdminRole.imsSuperAdmin,
    'buildings' =>
      role == AdminRole.imsSuperAdmin || role == AdminRole.infraAdmin,
    'faculty' || 'colleges' || 'offices' || 'leadership' =>
      role == AdminRole.imsSuperAdmin || role == AdminRole.hroAdmin,
    _ => false,
  };
}

class AdminAuthService {
  /// Looks up the admin role assigned to [email] in the `admin_roles`
  /// table. Returns null when the account has no admin role.
  Future<AdminUser?> getAdminUser(String email) async {
    final row = await Supabase.instance.client
        .from('admin_roles')
        .select()
        .eq('email', email.toLowerCase().trim())
        .maybeSingle();
    if (row == null) return null;
    final role = adminRoleFromString(row['role'] as String?);
    if (role == null) return null;
    return AdminUser(email: email, role: role);
  }
}