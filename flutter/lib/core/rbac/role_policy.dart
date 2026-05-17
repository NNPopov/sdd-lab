import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/role.dart';

const Map<UserRole, Set<Permission>> kRolePolicy = {
  UserRole.guest: {Permission.viewCatalog},
  UserRole.user: {Permission.viewCatalog, Permission.viewReports},
  UserRole.manager: {
    Permission.viewCatalog,
    Permission.editCatalog,
    Permission.viewReports,
    Permission.moderatePosts,
  },
  UserRole.admin: {...Permission.values},
};
