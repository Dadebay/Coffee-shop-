import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database/app_database.dart';
import 'database_controller.dart';

class ProductsController extends GetxController {
  static ProductsController get to => Get.find();

  final _db = Get.find<DatabaseController>().db;

  final RxList<Product>  products   = <Product>[].obs;
  final RxList<Category> categories = <Category>[].obs;
  final RxList<Unit>     units      = <Unit>[].obs;
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    products.value   = await _db.getAllProducts();
    categories.value = await _db.getAllCategories();
    units.value      = await _db.getAllUnits();
    loading.value = false;
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<String?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // always load bytes so we can compress
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.bytes == null) return null;

    // Compress to WebP 1024×1024
    final compressed = await FlutterImageCompress.compressWithList(
      file.bytes!,
      minWidth: 1024,
      minHeight: 1024,
      quality: 85,
      format: CompressFormat.webp,
      keepExif: false,
    );

    if (kIsWeb) {
      return _bytesToDataUrl(compressed, 'webp');
    } else {
      return _saveToAppDir(compressed);
    }
  }

  Future<String> _saveToAppDir(Uint8List bytes) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'kassa_images'));
    if (!imagesDir.existsSync()) imagesDir.createSync(recursive: true);
    final destName = '${DateTime.now().millisecondsSinceEpoch}.webp';
    final destPath = p.join(imagesDir.path, destName);
    await File(destPath).writeAsBytes(bytes);
    return destPath;
  }

  String _bytesToDataUrl(Uint8List bytes, String ext) {
    return 'data:image/$ext;base64,${base64Encode(bytes)}';
  }

  Future<void> _deleteOldImage(String? path) async {
    if (path == null || path.isEmpty || kIsWeb || path.startsWith('data:')) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  // ── Category CRUD ──────────────────────────────────────────────────────────

  Future<void> addCategory(String name, String color) async {
    await _db.createCategory(CategoriesCompanion.insert(
      name: name,
      color: drift.Value(color),
      sortOrder: drift.Value(categories.length),
    ));
    await loadAll();
  }

  Future<void> updateCategory(Category cat, String name, String color) async {
    await _db.updateCategory(cat.copyWith(name: name, color: color));
    await loadAll();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    await loadAll();
  }

  // ── Product CRUD ───────────────────────────────────────────────────────────

  Future<void> save({
    Product? existing,
    required String name,
    required String sku,
    required double price,
    required double purchasePrice,
    required double discount,
    required String discountType,
    required int quantity,
    int? categoryId,
    int? unitId,
    String? imagePath,
    DateTime? expireDate,
  }) async {
    if (existing == null) {
      await _db.createProduct(ProductsCompanion.insert(
        name: name,
        sku: sku.isEmpty ? 'SKU-${DateTime.now().millisecondsSinceEpoch}' : sku,
        imagePath: drift.Value(imagePath),
        categoryId: drift.Value(categoryId),
        unitId: drift.Value(unitId),
        price: drift.Value(price),
        purchasePrice: drift.Value(purchasePrice),
        discount: drift.Value(discount),
        discountType: drift.Value(discountType),
        quantity: drift.Value(quantity),
        expireDate: drift.Value(expireDate),
      ));
    } else {
      if (imagePath != null && imagePath != existing.imagePath) {
        await _deleteOldImage(existing.imagePath);
      }
      await _db.updateProduct(existing.copyWith(
        name: name,
        sku: sku,
        imagePath: drift.Value(imagePath ?? existing.imagePath),
        categoryId: drift.Value(categoryId),
        unitId: drift.Value(unitId),
        price: price,
        purchasePrice: purchasePrice,
        discount: discount,
        discountType: discountType,
        quantity: quantity,
        expireDate: drift.Value(expireDate),
      ));
    }
    await loadAll();
  }

  Future<void> delete(int id) async {
    final prod = products.firstWhereOrNull((p) => p.id == id);
    if (prod != null) await _deleteOldImage(prod.imagePath);
    await _db.deleteProduct(id);
    await loadAll();
  }
}
