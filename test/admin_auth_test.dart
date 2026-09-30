import 'package:csu_a_kiosk/services/admin_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('adminRoleFromString', () {
    test('maps valid role keys', () {
      expect(adminRoleFromString('ims_super_admin'), AdminRole.imsSuperAdmin);
      expect(adminRoleFromString('hro_admin'), AdminRole.hroAdmin);
      expect(adminRoleFromString('infra_admin'), AdminRole.infraAdmin);
    });

    test('returns null for invalid or empty keys', () {
      expect(adminRoleFromString(null), isNull);
      expect(adminRoleFromString(''), isNull);
      expect(adminRoleFromString('admin'), isNull);
      expect(adminRoleFromString('IMS_SUPER_ADMIN'), isNull);
    });
  });

  group('AdminUser', () {
    test('computes role key and label', () {
      final user = AdminUser(
        email: 'hro.admin@example.com',
        role: AdminRole.hroAdmin,
      );
      expect(user.roleKey, 'hro_admin');
      expect(user.roleLabel, 'HRO Admin');
      expect(user.isSuperAdmin, isFalse);
    });

    test('detects super admin', () {
      final user = AdminUser(
        email: 'ims.superadmin@example.com',
        role: AdminRole.imsSuperAdmin,
      );
      expect(user.isSuperAdmin, isTrue);
    });

    test('derives initials from email', () {
      const user = AdminUser(
        email: 'juan.delacruz.csua.edu.ph@example.com',
        role: AdminRole.imsSuperAdmin,
      );
      expect(user.initials, 'JP');
    });

    test('derives initials from single-part email', () {
      const user = AdminUser(
        email: 'alex@example.com',
        role: AdminRole.hroAdmin,
      );
      expect(user.initials, 'AL');
    });
  });

  group('adminCanAccess', () {
    const superAdmin = AdminUser(role: AdminRole.imsSuperAdmin, email: 'a@b.c');
    const hro = AdminUser(role: AdminRole.hroAdmin, email: 'a@b.c');
    const infra = AdminUser(role: AdminRole.infraAdmin, email: 'a@b.c');

    test('buildings: super admin and infra admin only', () {
      expect(adminCanAccess(superAdmin.role, 'buildings'), isTrue);
      expect(adminCanAccess(infra.role, 'buildings'), isTrue);
      expect(adminCanAccess(hro.role, 'buildings'), isFalse);
    });

    test('faculty/colleges/offices/leadership: super admin and hro only', () {
      for (final module in ['faculty', 'colleges', 'offices', 'leadership']) {
        expect(adminCanAccess(superAdmin.role, module), isTrue,
            reason: 'super admin should access $module');
        expect(adminCanAccess(hro.role, module), isTrue,
            reason: 'hro should access $module');
        expect(adminCanAccess(infra.role, module), isFalse,
            reason: 'infra should not access $module');
      }
    });

    test('approvals: super admin only', () {
      for (final module in ['approvals']) {
        expect(adminCanAccess(superAdmin.role, module), isTrue,
            reason: 'super admin should access $module');
        expect(adminCanAccess(hro.role, module), isFalse,
            reason: 'hro should not access $module');
        expect(adminCanAccess(infra.role, module), isFalse,
            reason: 'infra should not access $module');
      }
    });

    test('unknown module is inaccessible', () {
      expect(adminCanAccess(superAdmin.role, 'unknown'), isFalse);
    });
  });
}