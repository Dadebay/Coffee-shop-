# Kassa Programma — Gemini Geliştirme Brifingi

## 1. Proje Genel Bakış

Flutter 3.27 tabanlı bir kahvehane POS (satış noktası) uygulaması. Şu an Windows masaüstü + Chrome web hedefli. Dokunmatik ekran bilgisayar (monoblock) üzerinde çalışacak.

**Mevcut mimari:**

- State management: **GetX** (`get: ^4.6.6`) — `GetxController`, `Obx`, `Get.find`, `Get.dialog`
- Veritabanı: **Drift/SQLite** (`drift: ^2.18.0`) — ORM, migrations, transactions
- UI: Özel dark/light tema, **Gilroy** font, **HugeIcons** (`hugeicons: ^1.1.7`)
- Paketler: `shared_preferences`, `flutter_image_compress`, `file_picker`, `path_provider`, `intl`

**Yeni özellikler için de aynı stack kullanılmalı:**

- State: GetX (değiştirme)
- DB: Drift (değiştirme)
- Icons: HugeIcons (`HugeIcon(icon: HugeIcons.strokeRounded..., size: 20, color: ...)`)
- Font: Gilroy (`fontFamily: 'Gilroy'`)

---

## 2. Mevcut Dosya Yapısı

```
lib/
├── main.dart                         # App entry, AppBindings
├── core/
│   ├── constants/color_constants.dart  # AppColors
│   ├── theme/app_theme.dart
│   ├── translations/app_translations.dart  # ru + tk dil anahtarları
│   └── utils/formatters.dart
├── data/
│   ├── database/
│   │   ├── app_database.dart         # Tüm tablo tanımları + DB metodları
│   │   └── app_database.g.dart       # Drift üretilen kod (build_runner)
│   └── models/
│       └── cart_item.dart
├── controllers/
│   ├── auth_controller.dart
│   ├── cart_controller.dart
│   ├── database_controller.dart
│   ├── ingredients_controller.dart
│   ├── locale_controller.dart
│   ├── pos_controller.dart
│   ├── products_controller.dart
│   ├── recipes_controller.dart
│   ├── reports_controller.dart
│   ├── shift_controller.dart         # YENİ — shift yönetimi
│   └── theme_controller.dart
└── features/
    ├── auth/login_screen.dart
    ├── ingredients/ingredients_screen.dart
    ├── pos/
    │   ├── pos_screen.dart
    │   └── widgets/
    │       ├── cart_panel.dart        # Per-item discount EKLENDI
    │       ├── payment_dialog.dart
    │       ├── product_grid.dart
    │       ├── return_panel.dart      # YENİ — iade UI
    │       └── shift_dialogs.dart     # YENİ — vardiya dialogları
    ├── products/products_screen.dart
    ├── recipes/recipes_screen.dart
    ├── reports/reports_screen.dart
    ├── settings/settings_screen.dart
    └── shell/app_shell.dart
```

---

## 3. Mevcut Veritabanı Şeması (app_database.dart)

```dart
// Mevcut tablolar (schema version = 3):
Categories, Units, Products, Ingredients, Recipes,
Users, Orders, OrderItems, InventoryTransactions, ActionLogs, Shifts

// Products tablosu önemli alanlar:
- imagePath: text nullable
- price, discount, discountType: fiyat sistemi
- purchasePrice: maliyet fiyatı
- quantity: stok
- expireDate: dateTime nullable  ← DB'de var ama UI YOK
- useRecipeCost, recipeCalculatedCost: tarif maliyeti

// Orders tablosu:
- userId, subTotal, discount, total, paid, due
- paymentMethod: 'cash' | 'card' | 'mixed'
- isReturned: bool
- status: 1=paid, 0=due

// InventoryTransactions tablosu:
- type: 'consume' | 'restore' | 'purchase' | 'manual_adjust'
- Stok hareketleri buraya kaydedilir

// ActionLogs tablosu:
- action: 'sale' | 'cancel' | 'price_change' | 'stock_adjust' | 'shift_close'
- DB'de var ama UI YOK

// Shifts tablosu (YENİ - v3):
- userId, openedAt, closedAt, openingCash, closingCash
- orderCount, totalRevenue, totalCash, totalCard, isOpen
```

---

## 4. AppColors Referansı

```dart
class AppColors {
  static const Color primary    = Color(0xff1946bb);
  static const Color primary2   = Color(0xff187bff);   // Ana mavi
  static const Color bgDark     = Color(0xff0D0D0D);
  static const Color bgCard     = Color(0xff161616);
  static const Color bgSurface  = Color(0xff1C1C1C);
  static const Color bgBorder   = Color(0xff2A2A2A);
  static const Color textWhite  = Color(0xffFFFFFF);
  static const Color textGrey   = Color(0xff8A8A8A);
  static const Color textDim    = Color(0xff555555);
  static const Color green      = Color(0xff3ead2c);
  static const Color red        = Color(0xffFF3B30);
  static const Color orange     = Color(0xfffedb00);
  static const Color purple     = Color(0xffbf7ef3);
  static const Color blue       = Color(0xffcde7fc);  // çok açık
}
```

**Tema-aware renk paterni** (her widget'ta):

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final cardColor   = isDark ? AppColors.bgCard   : Colors.white;
final borderColor = isDark ? AppColors.bgBorder  : const Color(0xFFE2E8F0);
final textColor   = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
final surfaceColor = isDark ? AppColors.bgSurface : const Color(0xFFF8FAFF);
```

---

## 5. Audit Sonucu — Mevcut ve Eksik Özellikler

### ✅ MEVCUT (değiştirme)

- Ürün satışı (POS akışı)
- Arama (isim/SKU)
- Kategoriler (renkli chip)
- Ürün başına indirim (dialog ile)
- İade/geri ödeme (stok restore ile)
- Satır iptali (cart'tan silme)
- Vardiya açma/kapama (shift_dialogs.dart)
- Rol bazlı nav (admin/cashier sıralaması farklı)
- Gerçek zamanlı stok (satışta otomatik düşme)
- Min stok uyarısı (malzeme için)
- Tarifler (recipe editor tam)
- Maliyet hesabı (recipe cost)
- Kâr takibi (ürün başına)
- Malzeme otomatik düşme (satışta)
- PIN girişi (özel numpad)
- ActionLogs (DB'de, UI yok)
- Çevrimdışı çalışma (SQLite)
- Dokunmatik numpad (login'de)
- Ürün yönetimi (tam CRUD)
- Kullanıcı yönetimi (temel)

### ❌ EKSİK — Yapılacaklar

-----------------============================###########################################################

## 6. Yapılacak Özellikler (Öncelik Sırası)

### FEATURE 1: Stok Hareketi (Prikhod/Stok Girişi)

**Dosya:** `lib/features/stock/stock_movements_screen.dart`  
**Controller:** `lib/controllers/stock_controller.dart`

**Ne yapacak:**

- Malzeme (Ingredient) bazında stok girişi ekranı
- "Prikhod" (giriş): malzeme + miktar + birim fiyat + tarih
- "Spisanie" (silme/zarar): malzeme + miktar + sebep
- Hareket listesi (günlük/haftalık filtrelenebilir)
- Her hareket `InventoryTransactions` tablosuna kaydedilir (`type: 'purchase'` veya `'manual_adjust'`)
- `ActionLogs`'a da loglanır

**DB değişiklik gerekmez** — `InventoryTransactions` tablosu hazır.

**Gerekli DB metodları (app_database.dart'a eklenecek):**

```dart
Future<void> addStockReceipt(int ingredientId, double qty, double unitCost, int userId);
Future<void> addStockWriteOff(int ingredientId, double qty, String reason, int userId);
Future<List<InventoryTransaction>> getTransactionsForIngredient(int ingredientId, {DateTime? from, DateTime? to});
Future<List<InventoryTransaction>> getRecentTransactions({int limit = 50});
```

**UI gereksinimleri:**

- Sol panel: malzeme listesi (stok miktarı göstergeli)
- Sağ panel: seçilen malzemenin hareket geçmişi
- Üstte 2 büyük buton: "Giriş Ekle" (yeşil) + "Silme/Zarar" (kırmızı)
- Dialog: malzeme seç (dropdown), miktar (numpad), birim fiyat, not
- Dokunmatik uyumlu — büyük butonlar (min 48px yükseklik)

---

### FEATURE 2: Stok Raporu Sayfası (Ürün Bazında)

**Dosya:** `lib/features/stock/stock_report_screen.dart`

**Ne yapacak:**

- Tüm ürünlerin güncel stok durumu
- Sona ermek üzere olanlar (expireDate yaklaşanlar — ürünler tablosunda alan var)
- Kritik düşük stok uyarıları (malzeme bazında)
- Excel/PDF export butonu (placeholder — gerçek export Feature 7'de)

**DB metodları:**

```dart
Future<List<Product>> getExpiringProducts({int daysAhead = 7});
Future<List<Ingredient>> getCriticalStockIngredients();
Future<Map<String, dynamic>> getStockSummary();
```

---

### FEATURE 3: Raporlar Sayfası Genişletme

**Dosya:** `lib/features/reports/reports_screen.dart` (mevcut — genişletilecek)

**Eksik rapor bölümleri:**
a) **Saatlik satış grafiği** — bar chart, saat 0-23 arası
b) **Zayıf ürünler** — en az satılan 10 ürün
c) **Gider raporu** — InventoryTransactions'tan maliyet toplamı
d) **Stok özeti** — malzeme stok durumu
e) **Çalışan bazında satış** — user_id gruplu sipariş toplamı

**DB metodları:**

```dart
Future<List<Map<String, dynamic>>> getHourlySales(DateTime day);
Future<List<Map<String, dynamic>>> getEmployeeSalesSummary(DateTime from, DateTime to);
Future<List<Map<String, dynamic>>> getTopWeakProducts(DateTime from, DateTime to, {bool weak = false});
Future<double> getTotalExpenses(DateTime from, DateTime to);
```

**UI gereksinimleri:**

- Tab bar: Genel / Ürünler / Çalışanlar / Stok
- Saatlik satış için basit bar chart (fl_chart paketi eklenecek)
- Çalışan tablosu: isim, sipariş sayısı, toplam ciro, ortalama sepet
- Filtre: tarih aralığı (bugün/hafta/ay/özel)

**Eklenecek paket:** `fl_chart: ^0.69.0`

---

### FEATURE 4: Aksiyon Geçmişi (Action Log) UI

**Dosya:** `lib/features/settings/action_log_screen.dart`

**Ne yapacak:**

- Tüm kullanıcı eylemlerini listele (ActionLogs tablosundan)
- Filtre: kullanıcı / eylem tipi / tarih aralığı
- Her satır: tarih-saat, kullanıcı adı, eylem tipi (badge), açıklama
- Eylem tipleri ve renkleri:
  - `sale` → yeşil
  - `cancel` / `return` → kırmızı
  - `price_change` → turuncu
  - `stock_adjust` → mavi
  - `shift_close` → mor

**DB metodları:**

```dart
Future<List<ActionLog>> getActionLogs({
  int? userId,
  String? actionType,
  DateTime? from,
  DateTime? to,
  int limit = 100,
});
// UserName join için:
Future<List<Map<String, dynamic>>> getActionLogsWithUserName({...});
```

**Settings sayfasına link butonu eklenmeli** (mevcut settings_screen.dart'a)

---

### FEATURE 5: Ürün Son Kullanma Tarihi UI

**Dosya:** `lib/features/products/products_screen.dart` (mevcut — genişletilecek)

**Ne yapacak:**

- Ürün form dialog'ına `expireDate` alanı ekle (DatePicker)
- Ürün listesinde son kullanma tarihi göster
- Sona ermek üzere (7 gün içinde) → turuncu badge
- Süresi geçmiş → kırmızı badge
- Filtreleme: "Sona ermek üzere" checkbox

**DB değişiklik gerekmez** — `Products.expireDate` zaten var.

---

### FEATURE 6: Yetki Sistemi Genişletme (Role Permissions)

**Dosya:** `lib/controllers/auth_controller.dart` (genişletilecek)  
**Yeni Dosya:** `lib/core/permissions.dart`

**Ne yapacak:**

- Kasiyerler şunları yapamaz (admin onayı gerekir):
  - İndirim uygulamak (% 10 üzeri)
  - İade yapmak
  - Fiyat değiştirmek
  - Ürün silmek
- Admin PIN doğrulama dialog'u: kısıtlı eylem deneyince açılır
- `can(Permission.applyDiscount)` helper fonksiyonu

**Enum:**

```dart
enum Permission {
  applyDiscount,
  processReturn,
  changePrice,
  deleteProduct,
  viewReports,
  manageUsers,
  viewActionLog,
}
```

**Not:** Basit tutulacak — cashier role'ü bazı eylemleri doğrudan yapamaz, admin PIN ister.

---

### FEATURE 7: Excel Export

**Dosya:** `lib/features/reports/export_service.dart`

**Ne yapacak:**

- Rapor verilerini Excel (.xlsx) olarak kaydet/indir
- Sipariş geçmişi export
- Stok durumu export
- Çalışan satışları export

**Eklenecek paket:** `excel: ^4.0.6`

**Fonksiyon:**

```dart
class ExportService {
  Future<void> exportOrders(List<Order> orders, List<OrderItem> items);
  Future<void> exportStock(List<Product> products, List<Ingredient> ingredients);
  Future<void> exportEmployeeSales(List<Map<String, dynamic>> data);
}
// Web: html download
// Windows: getApplicationDocumentsDirectory() + File.writeAsBytes()
```

---

### FEATURE 8: Dokunmatik Numpad Paneli (POS)

**Dosya:** `lib/features/pos/widgets/numpad_widget.dart`

**Ne yapacak:**

- POS'ta ürün miktarı girmek için büyük dokunmatik numpad
- Seçilen ürünün miktarını doğrudan numpad ile değiştir
- Satış tutarını numpad ile gir (ödeme dialogunda)
- Büyük tuşlar (min 72×72 px), rahat basılabilir

**Not:** Login'de numpad zaten var (login_screen.dart). Aynı stili kullan.

---

## 7. DB Schema Değişiklikleri (build_runner gerekir)

### 7a. InventoryTransactions tablosuna alanlar ekle (opsiyonel)

```dart
// Prikhod için birim fiyat kaydı:
RealColumn get unitCost => real().withDefault(const Constant(0.0))();
// Schema version 4'e güncelle, migration ekle:
if (from < 4) {
  await m.addColumn(inventoryTransactions, inventoryTransactions.unitCost);
}
```

### 7b. Yeni tablo: Expenses (Giderler) — opsiyonel

```dart
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();     // 'salary' | 'rent' | 'utility' | 'other'
  TextColumn get description => text()();
  RealColumn get amount => real()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
}
```

---

## 8. Navigation Güncelleme (app_shell.dart)

Mevcut navigation sırası:

- Admin: Reports, POS, Products, Stock/Ingredients, Recipes, Settings
- Cashier: POS, Products, Stock/Ingredients, Recipes, Reports, Settings

Stok Hareketleri eklenince yeni sayfa indices güncellenmeli.

---

## 9. Çeviri Anahtarları (her yeni özellik için eklenecek)

```dart
// app_translations.dart — ru ve tk'ya eklenecek:
'stock_receipt': 'Приход товара',          // 'Haryt girişi'
'stock_writeoff': 'Списание',              // 'Hasapdan çykarmak'
'stock_movements': 'Движения товара',       // 'Haryt hereketleri'
'stock_qty': 'Количество',                 // 'Mukdar'
'stock_reason': 'Причина',                 // 'Sebäp'
'report_hourly': 'Продажи по часам',       // 'Sagatly satuw'
'report_employees': 'По сотрудникам',      // 'Işgärler boýunça'
'report_expenses': 'Расходы',              // 'Çykdaýjylar'
'report_stock': 'Остатки',                 // 'Galyndy'
'report_weak': 'Слабые товары',            // 'Gowşak harytlar'
'log_title': 'Журнал действий',            // 'Hereketler žurnaly'
'log_sale': 'Продажа',                     // 'Satuw'
'log_cancel': 'Возврат',                   // 'Gaýtarmak'
'log_price_change': 'Изменение цены',      // 'Baha üýtgemesi'
'log_stock_adjust': 'Корректировка склада', // 'Ammar düzeltmesi'
'exp_title': 'Срок годности',              // 'Ýaramlylyk möhleti'
'exp_warning': 'Истекает через {days} дней', // '{days} günde gutarýar'
'exp_expired': 'Срок истёк',              // 'Möhleti geçdi'
'perm_need_admin': 'Требуется подтверждение администратора', // 'Admin tassyklamasy gerek'
'perm_enter_pin': 'Введите PIN администратора', // 'Admin PIN giriziň'
'export_excel': 'Экспорт Excel',          // 'Excel eksporty'
'export_pdf': 'Экспорт PDF',              // 'PDF eksporty'
```

---

## 10. Paket Bağımlılıkları (pubspec.yaml'a eklenecek)

```yaml
# Mevcut paketler (değiştirilmeyecek):
get: ^4.6.6
drift: ^2.18.0
drift_flutter: ^0.2.0
shared_preferences: ^2.3.2
file_picker: ^8.1.4
flutter_image_compress: ^2.3.0
hugeicons: ^1.1.7
intl: ^0.19.0
path_provider: ^2.1.3
path: ^1.9.0

# Yeni eklenecekler:
fl_chart: ^0.69.0 # Saatlik satış grafiği için (Feature 3)
excel: ^4.0.6 # Excel export için (Feature 7)
# PDF için (opsiyonel):
# pdf: ^3.11.0
# printing: ^5.13.0
```

---

## 11. Kod Yazma Kuralları (Gemini için)

### Widget pattern:

```dart
// HER widget'ta isDark kontrolü:
final isDark = Theme.of(context).brightness == Brightness.dark;
final cardColor = isDark ? AppColors.bgCard : Colors.white;
final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);

// Dialog container:
Dialog(
  backgroundColor: isDark ? AppColors.bgSurface : Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ...
)

// Input field:
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: isDark ? AppColors.bgCard : const Color(0xFFF8FAFF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0),
      ),
    ),
    labelStyle: const TextStyle(fontFamily: 'Gilroy', fontSize: 13),
  ),
  style: const TextStyle(fontFamily: 'Gilroy'),
)
```

### GetX Controller pattern:

```dart
class XController extends GetxController {
  static XController get to => Get.find();
  final _db = Get.find<DatabaseController>().db;

  final RxList<SomeModel> items = <SomeModel>[].obs;
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    loading.value = true;
    items.value = await _db.getSomeData();
    loading.value = false;
  }
}
```

### Dialog açma:

```dart
Get.dialog(const SomeDialog(), barrierDismissible: true);
```

### Snackbar:

```dart
Get.snackbar('gen_success'.tr, 'mesaj',
    backgroundColor: AppColors.green,
    colorText: Colors.white,
    duration: const Duration(seconds: 2));
```

### HugeIcon kullanımı:

```dart
HugeIcon(
  icon: HugeIcons.strokeRoundedSomeIcon,  // List<List<dynamic>> tipi
  size: 20,
  color: AppColors.primary2,
)
```

### Dokunmatik uyum için minimum boyutlar:

- Buton yüksekliği: min 48px (SizedBox height: 48 veya 52)
- İkon buton: min 44×44
- Liste tile padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)
- Ana aksiyon butonları: FilledButton, tam genişlik

---

## 12. Uygulama Başlatma (main.dart) — Mevcut

```dart
class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(LocaleController(), permanent: true);
    Get.put(DatabaseController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(CartController(), permanent: true);
    Get.put(ShiftController(), permanent: true);       // YENİ eklendi
    Get.lazyPut(() => PosController());
    Get.lazyPut(() => ProductsController());
    Get.lazyPut(() => IngredientsController());
    Get.lazyPut(() => RecipesController());
    Get.lazyPut(() => ReportsController());
  }
}
```

**Yeni controller'lar için:**

```dart
Get.lazyPut(() => StockController());    // Feature 1
Get.lazyPut(() => ExportService());      // Feature 7
```

---

## 13. Mevcut app_database.dart'a Eklenecek Metodlar (özet)

Aşağıdaki metodlar mevcut `AppDatabase` class'ına eklenecek (dosyanın sonuna):

```dart
// FEATURE 1 — Stok Hareketi
Future<void> addStockReceipt(int ingredientId, double qty, double unitCost, int userId, {String? note});
Future<void> addStockWriteOff(int ingredientId, double qty, String reason, int userId);
Future<List<InventoryTransaction>> getIngredientTransactions(int ingredientId, {DateTime? from, DateTime? to});
Future<List<InventoryTransaction>> getAllTransactions({int limit = 100, DateTime? from, DateTime? to});

// FEATURE 3 — Raporlar
Future<List<Map<String, dynamic>>> getHourlySales(DateTime day);
Future<List<Map<String, dynamic>>> getEmployeeSalesSummary(DateTime from, DateTime to);
Future<List<Map<String, dynamic>>> getProductSalesRanking(DateTime from, DateTime to);
Future<double> getTotalPurchaseCost(DateTime from, DateTime to);

// FEATURE 4 — Action Log
Future<List<Map<String, dynamic>>> getActionLogsWithUser({
  int? userId, String? actionType, DateTime? from, DateTime? to, int limit = 100});

// FEATURE 5 — Expiry
Future<List<Product>> getExpiringProducts({int daysAhead = 7});
Future<List<Product>> getExpiredProducts();
```

---

## 14. Öncelik Sırası (Gemini için tavsiye)

1. **Feature 1** (Stok girişi/çıkışı) — En kritik, günlük kullanım
2. **Feature 3** (Raporlar genişletme) — Yönetim kararları için
3. **Feature 4** (Action Log UI) — Kontrol ve denetim
4. **Feature 5** (Son kullanma tarihi) — Gıda işletmesi için zorunlu
5. **Feature 6** (Yetki sistemi) — Güvenlik
6. **Feature 7** (Excel export) — Muhasebe için
7. **Feature 2** (Stok raporu) — Feature 1 tamamlandıktan sonra
8. **Feature 8** (Numpad widget) — UX iyileştirme

---

## 15. Önemli Notlar

1. **`build_runner` çalıştırma:** DB şeması değiştiğinde mutlaka çalıştırılmalı:

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Schema version artırma:** Her yeni tablo/kolon için `schemaVersion` değeri artırılmalı ve `onUpgrade` migration eklenmeli.

3. **Mevcut kod dokunulmayacak:** Sadece yeni dosyalar + mevcut dosyalara ekleme yapılacak. `app_database.dart`'a yeni metodlar eklenecek ama mevcut metodlar değiştirilmeyecek.

4. **Web uyumluluğu:** `kIsWeb` kontrolü: `if (kIsWeb) { /* web yolu */ } else { /* windows yolu */ }`

5. **Çeviri:** Her yeni string için `app_translations.dart`'a hem `'ru'` hem `'tk'` anahtarı eklenmeli. Tüm UI string'leri `'key'.tr` ile çekilmeli.

6. **Dokunmatik öncelik:** Tüm butonlar parmakla rahat basılabilir büyüklükte. Font size minimum 13px. Liste item'ları 56px+ yüksekliğinde.
