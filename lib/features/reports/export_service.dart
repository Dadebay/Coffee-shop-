import 'dart:io';
import 'package:flutter/material.dart' hide Border, BorderStyle;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:file_picker/file_picker.dart';

import '../../core/constants/color_constants.dart';
import '../../data/database/app_database.dart';

class ExportService {
  static final ExcelColor _headerBg = ExcelColor.fromHexString('FF1946BB');
  static final ExcelColor _zebraBg = ExcelColor.fromHexString('FFF3F6FC');
  static final ExcelColor _returnedBg = ExcelColor.fromHexString('FFFCEBEA');
  static final ExcelColor _totalBg = ExcelColor.fromHexString('FFEAF0FB');
  static final ExcelColor _borderColor = ExcelColor.fromHexString('FFE1E6EF');
  static final ExcelColor _greenText = ExcelColor.fromHexString('FF2E7D32');
  static final ExcelColor _redText = ExcelColor.fromHexString('FFD32F2F');
  static final ExcelColor _orangeText = ExcelColor.fromHexString('FFB8860B');
  static final ExcelColor _greyText = ExcelColor.fromHexString('FF6B7280');

  static final CellStyle _titleStyle = CellStyle(
    bold: true,
    fontSize: 16,
    fontColorHex: _headerBg,
  );

  static final CellStyle _subtitleStyle = CellStyle(
    italic: true,
    fontColorHex: _greyText,
  );

  static final CellStyle _headerStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: _headerBg,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: _headerBg),
    bottomBorder:
        Border(borderStyle: BorderStyle.Thin, borderColorHex: _headerBg),
    leftBorder:
        Border(borderStyle: BorderStyle.Thin, borderColorHex: _headerBg),
    rightBorder:
        Border(borderStyle: BorderStyle.Thin, borderColorHex: _headerBg),
  );

  static void _setCell(
      Sheet sheet, int col, int row, CellValue value, CellStyle style) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      value,
      cellStyle: style,
    );
  }

  static CellStyle _rowStyle(
    ExcelColor bg, {
    HorizontalAlign align = HorizontalAlign.Left,
    bool bold = false,
    ExcelColor? fontColor,
    NumFormat numberFormat = NumFormat.standard_0,
  }) =>
      CellStyle(
        backgroundColorHex: bg,
        horizontalAlign: align,
        bold: bold,
        fontColorHex: fontColor ?? ExcelColor.black,
        numberFormat: numberFormat,
        bottomBorder:
            Border(borderStyle: BorderStyle.Hair, borderColorHex: _borderColor),
      );

  static void _writeTitleBlock(
      Sheet sheet, String title, int columnCount, String subtitle) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: columnCount - 1, rowIndex: 0),
    );
    _setCell(sheet, 0, 0, TextCellValue(title), _titleStyle);
    sheet.setRowHeight(0, 24);

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: columnCount - 1, rowIndex: 1),
    );
    _setCell(sheet, 0, 1, TextCellValue(subtitle), _subtitleStyle);
  }

  static void _writeHeaderRow(Sheet sheet, int rowIndex, List<String> headers) {
    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, i, rowIndex, TextCellValue(headers[i]), _headerStyle);
    }
    sheet.setRowHeight(rowIndex, 22);
  }

  static void _setColumnWidths(Sheet sheet, List<double> widths) {
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  static String _paymentLabel(String method) {
    final key = 'pay_method_$method';
    final label = key.tr;
    return label == key ? method.toUpperCase() : label;
  }

  static String _movementTypeLabel(String type) {
    final key = 'exp_type_$type';
    final label = key.tr;
    return label == key ? type : label;
  }

  static ExcelColor _movementTypeColor(String type) {
    switch (type) {
      case 'add':
      case 'purchase':
      case 'restore':
        return _greenText;
      case 'remove':
      case 'consume':
        return _redText;
      default:
        return _orangeText;
    }
  }

  static Future<bool> exportOrders(
    List<Order> orders, {
    required DateTime periodFrom,
    required DateTime periodTo,
    Map<int, String> usersMap = const {},
    String fileName = 'Siparis_Gecmisi',
  }) async {
    var excel = Excel.createExcel();
    const sheetName = 'Siparişler';
    Sheet sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    const columnCount = 9;
    _writeTitleBlock(
      sheet,
      'rep_orders_tab'.tr,
      columnCount,
      '${'exp_period'.tr}: ${DateFormat('dd.MM.yyyy').format(periodFrom)} – ${DateFormat('dd.MM.yyyy').format(periodTo)}  •  '
      '${'exp_generated'.tr}: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}  •  ${'exp_no'.tr}: ${orders.length}',
    );

    const headerRow = 2;
    _writeHeaderRow(sheet, headerRow, [
      'exp_order_no'.tr,
      'rep_cashier'.tr,
      'exp_date'.tr,
      'exp_status'.tr,
      'exp_subtotal'.tr,
      'exp_discount'.tr,
      'exp_net'.tr,
      'exp_due'.tr,
      'exp_pay_method'.tr,
    ]);

    var row = headerRow + 1;
    double sumSub = 0, sumDisc = 0, sumNet = 0, sumDue = 0;

    for (var i = 0; i < orders.length; i++) {
      final order = orders[i];
      final returned = order.isReturned;
      final bg =
          returned ? _returnedBg : (i.isEven ? ExcelColor.white : _zebraBg);

      _setCell(sheet, 0, row, IntCellValue(order.id),
          _rowStyle(bg, align: HorizontalAlign.Center));
      _setCell(sheet, 1, row, TextCellValue(usersMap[order.userId] ?? '-'),
          _rowStyle(bg));
      _setCell(
        sheet,
        2,
        row,
        TextCellValue(DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt)),
        _rowStyle(bg),
      );
      _setCell(
        sheet,
        3,
        row,
        TextCellValue(returned ? 'exp_returned'.tr : 'exp_sale'.tr),
        _rowStyle(bg,
            align: HorizontalAlign.Center,
            bold: returned,
            fontColor: returned ? _redText : _greenText),
      );
      _setCell(
        sheet,
        4,
        row,
        DoubleCellValue(order.subTotal),
        _rowStyle(bg,
            align: HorizontalAlign.Right, numberFormat: NumFormat.standard_4),
      );
      _setCell(
        sheet,
        5,
        row,
        DoubleCellValue(order.discount),
        _rowStyle(bg,
            align: HorizontalAlign.Right, numberFormat: NumFormat.standard_4),
      );
      _setCell(
        sheet,
        6,
        row,
        DoubleCellValue(order.total),
        _rowStyle(bg,
            align: HorizontalAlign.Right,
            bold: true,
            numberFormat: NumFormat.standard_4),
      );
      final hasDue = order.due > 0;
      _setCell(
        sheet,
        7,
        row,
        DoubleCellValue(order.due),
        _rowStyle(bg,
            align: HorizontalAlign.Right,
            numberFormat: NumFormat.standard_4,
            bold: hasDue,
            fontColor: hasDue ? _redText : _greyText),
      );
      _setCell(
        sheet,
        8,
        row,
        TextCellValue(_paymentLabel(order.paymentMethod)),
        _rowStyle(bg, align: HorizontalAlign.Center),
      );

      // Returned orders are shown in the table (highlighted) but excluded
      // from the totals row — the money was refunded, so it shouldn't
      // count toward revenue collected.
      if (!returned) {
        sumSub += order.subTotal;
        sumDisc += order.discount;
        sumNet += order.total;
        sumDue += order.due;
      }
      row++;
    }

    final totalStyle = CellStyle(
      bold: true,
      backgroundColorHex: _totalBg,
      horizontalAlign: HorizontalAlign.Right,
      numberFormat: NumFormat.standard_4,
      topBorder:
          Border(borderStyle: BorderStyle.Medium, borderColorHex: _headerBg),
    );
    final totalLabelStyle = CellStyle(
      bold: true,
      backgroundColorHex: _totalBg,
      horizontalAlign: HorizontalAlign.Right,
      topBorder:
          Border(borderStyle: BorderStyle.Medium, borderColorHex: _headerBg),
    );

    final hasReturns = orders.any((o) => o.isReturned);
    final totalLabel = hasReturns
        ? '${'exp_total_row'.tr} (${'exp_total_excl_returns'.tr})'
        : 'exp_total_row'.tr;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
    );
    _setCell(sheet, 0, row, TextCellValue(totalLabel), totalLabelStyle);
    _setCell(sheet, 4, row, DoubleCellValue(sumSub), totalStyle);
    _setCell(sheet, 5, row, DoubleCellValue(sumDisc), totalStyle);
    _setCell(sheet, 6, row, DoubleCellValue(sumNet), totalStyle);
    _setCell(
      sheet,
      7,
      row,
      DoubleCellValue(sumDue),
      CellStyle(
        bold: true,
        backgroundColorHex: _totalBg,
        horizontalAlign: HorizontalAlign.Right,
        numberFormat: NumFormat.standard_4,
        fontColorHex: sumDue > 0 ? _redText : ExcelColor.black,
        topBorder:
            Border(borderStyle: BorderStyle.Medium, borderColorHex: _headerBg),
      ),
    );
    _setCell(
        sheet,
        8,
        row,
        TextCellValue(''),
        CellStyle(
            backgroundColorHex: _totalBg,
            topBorder: Border(
                borderStyle: BorderStyle.Medium, borderColorHex: _headerBg)));

    _setColumnWidths(sheet, [10, 16, 17, 14, 13, 12, 13, 13, 14]);

    return _saveExcel(excel, fileName);
  }

  static Future<bool> exportStockMovements(
    List<InventoryTransaction> movements, {
    Map<int, String> ingredientsMap = const {},
    Map<int, String> ingredientUnits = const {},
    String fileName = 'Stok_Hareketleri',
  }) async {
    var excel = Excel.createExcel();
    const sheetName = 'Stok';
    Sheet sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    const columnCount = 8;
    _writeTitleBlock(
      sheet,
      'stock_rep_title'.tr,
      columnCount,
      '${'exp_generated'.tr}: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}  •  ${'exp_no'.tr}: ${movements.length}',
    );

    const headerRow = 2;
    _writeHeaderRow(sheet, headerRow, [
      'exp_no'.tr,
      'exp_date'.tr,
      'exp_ingredient'.tr,
      'exp_type'.tr,
      'exp_qty'.tr,
      'exp_unit_cost'.tr,
      'exp_line_total'.tr,
      'exp_ref_no'.tr,
    ]);

    var row = headerRow + 1;
    double sumTotal = 0;

    for (var i = 0; i < movements.length; i++) {
      final mov = movements[i];
      final bg = i.isEven ? ExcelColor.white : _zebraBg;
      final lineTotal = mov.quantity * mov.unitCost;
      final unit = ingredientUnits[mov.ingredientId];

      _setCell(sheet, 0, row, IntCellValue(mov.id),
          _rowStyle(bg, align: HorizontalAlign.Center));
      _setCell(
        sheet,
        1,
        row,
        TextCellValue(DateFormat('dd.MM.yyyy HH:mm').format(mov.createdAt)),
        _rowStyle(bg),
      );
      _setCell(
        sheet,
        2,
        row,
        TextCellValue(
            ingredientsMap[mov.ingredientId] ?? '#${mov.ingredientId}'),
        _rowStyle(bg),
      );
      _setCell(
        sheet,
        3,
        row,
        TextCellValue(_movementTypeLabel(mov.type)),
        _rowStyle(bg,
            align: HorizontalAlign.Center,
            bold: true,
            fontColor: _movementTypeColor(mov.type)),
      );
      _setCell(
        sheet,
        4,
        row,
        TextCellValue(unit == null
            ? mov.quantity.toStringAsFixed(2)
            : '${mov.quantity.toStringAsFixed(2)} $unit'),
        _rowStyle(bg, align: HorizontalAlign.Right),
      );
      _setCell(
        sheet,
        5,
        row,
        DoubleCellValue(mov.unitCost),
        _rowStyle(bg,
            align: HorizontalAlign.Right, numberFormat: NumFormat.standard_4),
      );
      _setCell(
        sheet,
        6,
        row,
        DoubleCellValue(lineTotal),
        _rowStyle(bg,
            align: HorizontalAlign.Right,
            bold: true,
            numberFormat: NumFormat.standard_4),
      );
      _setCell(
        sheet,
        7,
        row,
        TextCellValue(
            '${mov.referenceType ?? ''} ${mov.referenceId ?? ''}'.trim()),
        _rowStyle(bg, align: HorizontalAlign.Center),
      );

      sumTotal += lineTotal;
      row++;
    }

    final totalStyle = CellStyle(
      bold: true,
      backgroundColorHex: _totalBg,
      horizontalAlign: HorizontalAlign.Right,
      numberFormat: NumFormat.standard_4,
      topBorder:
          Border(borderStyle: BorderStyle.Medium, borderColorHex: _headerBg),
    );
    final totalLabelStyle = CellStyle(
      bold: true,
      backgroundColorHex: _totalBg,
      horizontalAlign: HorizontalAlign.Right,
      topBorder:
          Border(borderStyle: BorderStyle.Medium, borderColorHex: _headerBg),
    );

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
    );
    _setCell(sheet, 0, row, TextCellValue('exp_total_row'.tr), totalLabelStyle);
    _setCell(sheet, 6, row, DoubleCellValue(sumTotal), totalStyle);
    _setCell(
        sheet,
        7,
        row,
        TextCellValue(''),
        CellStyle(
            backgroundColorHex: _totalBg,
            topBorder: Border(
                borderStyle: BorderStyle.Medium, borderColorHex: _headerBg)));

    _setColumnWidths(sheet, [8, 17, 22, 16, 14, 13, 14, 16]);

    return _saveExcel(excel, fileName);
  }

  static String? _desktopDirectory() {
    if (Platform.isWindows) {
      final profile = Platform.environment['USERPROFILE'];
      return profile == null ? null : '$profile\\Desktop';
    }
    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      return home == null ? null : '$home/Desktop';
    }
    return null;
  }

  /// Returns `true` if the file was written to disk, `false` if the user
  /// cancelled the save dialog (or the download was handed off to the
  /// browser, on web).
  static Future<bool> _saveExcel(Excel excel, String baseName) async {
    final fileName =
        '${baseName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final bytes = excel.save();
    if (bytes == null) return false;

    if (kIsWeb) {
      final blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      return true;
    }

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'exp_save_dialog_title'.tr,
      fileName: fileName,
      initialDirectory: _desktopDirectory(),
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (path == null) return false;

    final savePath = path.toLowerCase().endsWith('.xlsx') ? path : '$path.xlsx';
    final file = File(savePath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);

    final directory = file.parent.path;
    Get.showSnackbar(GetSnackBar(
      title: 'exp_saved_to'.tr,
      message: savePath,
      duration: const Duration(seconds: 6),
      backgroundColor: AppColors.green,
      borderRadius: 12,
      margin: const EdgeInsets.all(12),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          if (Platform.isWindows) {
            Process.run('explorer.exe', ['/select,', savePath]);
          } else if (Platform.isMacOS) {
            Process.run('open', [directory]);
          }
        },
        child: Text(
          'exp_open_folder'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ));

    return true;
  }
}
