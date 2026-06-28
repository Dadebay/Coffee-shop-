enum Permission {
  applyDiscount,
  processReturn,
  changePrice,
  deleteProduct,
  viewReports,
  manageUsers,
  viewActionLog,
  manageStock,
  manageSettings,
}

extension RolePermissions on String {
  List<Permission> get permissions {
    switch (this) {
      case 'admin':
        return Permission.values;
      case 'manager':
        return [
          Permission.applyDiscount,
          Permission.processReturn,
          Permission.changePrice,
          Permission.viewReports,
          Permission.manageStock,
          Permission.viewActionLog,
        ];
      case 'cashier':
      default:
        // Cashiers have very limited permissions
        return [];
    }
  }

  bool hasPermission(Permission p) => permissions.contains(p);
}
