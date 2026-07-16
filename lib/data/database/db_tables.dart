part of 'app_database.dart';

// ─── Tables ───

// ─── Tables ───────────────────────────────────────────────────────────────────

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get color => text().withDefault(const Constant('#E8724A'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Units extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get shortName => text().withLength(min: 1, max: 10)();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get sku => text().withLength(min: 1, max: 50).unique()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get unitId => integer().nullable().references(Units, #id)();
  RealColumn get price => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  TextColumn get discountType => text().withDefault(const Constant('fixed'))(); // fixed | percentage
  RealColumn get purchasePrice => real().withDefault(const Constant(0.0))();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  DateTimeColumn get expireDate => dateTime().nullable()();
  BoolColumn get status => boolean().withDefault(const Constant(true))();
  BoolColumn get useRecipeCost => boolean().withDefault(const Constant(false))();
  RealColumn get recipeCalculatedCost => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Ingredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200).unique()();
  TextColumn get unit => text().withDefault(const Constant('g'))(); // g | ml | pcs
  RealColumn get stock => real().withDefault(const Constant(0.0))();
  RealColumn get cost => real().withDefault(const Constant(0.0))(); // cost per unit
  RealColumn get minStock => real().withDefault(const Constant(0.0))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get quantity => real()(); // quantity per 1 unit of product
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get pin => text().withLength(min: 4, max: 6)();
  TextColumn get role => text().withDefault(const Constant('cashier'))(); // admin | cashier
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  RealColumn get subTotal => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  RealColumn get paid => real().withDefault(const Constant(0.0))();
  RealColumn get due => real().withDefault(const Constant(0.0))();
  TextColumn get note => text().nullable()();
  BoolColumn get isReturned => boolean().withDefault(const Constant(false))();
  IntColumn get status => integer().withDefault(const Constant(1))(); // 1=paid, 0=due
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()(); // snapshot at time of sale
  RealColumn get price => real()();
  RealColumn get purchasePrice => real().withDefault(const Constant(0.0))();
  IntColumn get quantity => integer()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get subTotal => real()();
  RealColumn get total => real()();
  RealColumn get netProfit => real().withDefault(const Constant(0.0))();
}

class InventoryTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  TextColumn get type => text()(); // consume | restore | purchase | manual_adjust
  RealColumn get quantity => real()();
  RealColumn get unitCost => real().withDefault(const Constant(0.0))(); // birim fiyat (prikhod için)
  TextColumn get referenceType => text().nullable()(); // order | purchase | manual
  IntColumn get referenceId => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ActionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get action => text()(); // sale | cancel | price_change | stock_adjust
  TextColumn get description => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get openedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get closedAt => dateTime().nullable()();
  RealColumn get openingCash => real().withDefault(const Constant(0.0))();
  RealColumn get closingCash => real().nullable()();
  IntColumn get orderCount => integer().withDefault(const Constant(0))();
  RealColumn get totalRevenue => real().withDefault(const Constant(0.0))();
  RealColumn get totalCash => real().withDefault(const Constant(0.0))();
  RealColumn get totalCard => real().withDefault(const Constant(0.0))();
  BoolColumn get isOpen => boolean().withDefault(const Constant(true))();
}
