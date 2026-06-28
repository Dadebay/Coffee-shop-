import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';

class ExportService {
  
  static Future<void> exportOrders(List<Order> orders, {String fileName = 'Siparis_Gecmisi'}) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Siparişler'];
    excel.setDefaultSheet('Siparişler');

    // Headers
    sheet.appendRow([
      TextCellValue('exp_order_no'.tr),
      TextCellValue('exp_date'.tr),
      TextCellValue('exp_status'.tr),
      TextCellValue('exp_subtotal'.tr),
      TextCellValue('exp_discount'.tr),
      TextCellValue('exp_net'.tr),
      TextCellValue('exp_paid'.tr),
      TextCellValue('exp_pay_method'.tr),
    ]);

    for (var order in orders) {
      sheet.appendRow([
        IntCellValue(order.id),
        TextCellValue(DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt)),
        TextCellValue(order.isReturned ? 'exp_returned'.tr : 'exp_sale'.tr),
        DoubleCellValue(order.subTotal),
        DoubleCellValue(order.discount),
        DoubleCellValue(order.total),
        DoubleCellValue(order.paid),
        TextCellValue(order.paymentMethod.toUpperCase()),
      ]);
    }

    await _saveExcel(excel, fileName);
  }

  static Future<void> exportStockMovements(List<InventoryTransaction> movements, {String fileName = 'Stok_Hareketleri'}) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Stok'];
    excel.setDefaultSheet('Stok');

    // Headers
    sheet.appendRow([
      TextCellValue('exp_no'.tr),
      TextCellValue('exp_date'.tr),
      TextCellValue('exp_item_id'.tr),
      TextCellValue('exp_type'.tr),
      TextCellValue('exp_qty'.tr),
      TextCellValue('exp_unit_cost'.tr),
      TextCellValue('exp_ref_no'.tr),
    ]);

    for (var mov in movements) {
      sheet.appendRow([
        IntCellValue(mov.id),
        TextCellValue(DateFormat('dd.MM.yyyy HH:mm').format(mov.createdAt)),
        IntCellValue(mov.ingredientId),
        TextCellValue(mov.type),
        DoubleCellValue(mov.quantity),
        DoubleCellValue(mov.unitCost),
        TextCellValue('${mov.referenceType ?? ''} ${mov.referenceId ?? ''}'.trim()),
      ]);
    }

    await _saveExcel(excel, fileName);
  }

  static Future<void> _saveExcel(Excel excel, String baseName) async {
    final fileName = '${baseName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final bytes = excel.save();
    if (bytes == null) return;

    if (kIsWeb) {
      // Web download
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Desktop/Mobile download to documents
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
    }
  }
}
