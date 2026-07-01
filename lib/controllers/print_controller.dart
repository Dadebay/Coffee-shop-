import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win32/win32.dart';

import '../core/utils/formatters.dart';
import '../data/database/app_database.dart';

// ── Win32 DOC_INFO_1 struct ───────────────────────────────────────────────────

final class _DocInfo extends Struct {
  external Pointer<Utf16> pDocName;
  external Pointer<Utf16> pOutputFile;
  external Pointer<Utf16> pDatatype;
}

// ── Minimal ESC/POS byte builder ──────────────────────────────────────────────

class _EscPos {
  static const _w = 42;
  final _buf = BytesBuilder();

  void init() => _add([0x1B, 0x40]);
  void align(int a) => _add([0x1B, 0x61, a]); // 0=L 1=C 2=R
  void bold(bool on) => _add([0x1B, 0x45, on ? 1 : 0]);
  void doubleSize(bool on) => _add([0x1D, 0x21, on ? 0x11 : 0x00]);
  void feed(int n) => _add([0x1B, 0x64, n]);
  void cut() => _add([0x1D, 0x56, 0x41, 0x00]);
  void hr() { align(0); _line('-' * _w); }

  void _line(String s) {
    _buf.add(s.runes.map((r) => r <= 0xFF ? r : 0x3F).toList());
    _buf.addByte(0x0A);
  }

  void text(String s) => _line(s);

  void row2(String left, String right) {
    final sp = _w - left.length - right.length;
    _line(sp > 0
        ? '$left${' ' * sp}$right'
        : '${left.substring(0, (_w - right.length - 1).clamp(0, left.length))} $right');
  }

  Uint8List get bytes => _buf.toBytes();
  void _add(List<int> b) => _buf.add(b);
}

// ── PrintController ───────────────────────────────────────────────────────────

class PrintController extends GetxController {
  static PrintController get to => Get.find();

  static const _keyPrinter = 'receipt_printer';
  static const _keyAuto = 'receipt_auto_print';

  final RxString selectedPrinter = ''.obs;
  final RxList<String> printers = <String>[].obs;
  final RxBool autoPrint = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPrefs();
    if (!kIsWeb && Platform.isWindows) refreshPrinters();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    selectedPrinter.value = p.getString(_keyPrinter) ?? '';
    autoPrint.value = p.getBool(_keyAuto) ?? true;
  }

  Future<void> selectPrinter(String name) async {
    selectedPrinter.value = name;
    final p = await SharedPreferences.getInstance();
    name.isEmpty ? p.remove(_keyPrinter) : p.setString(_keyPrinter, name);
  }

  Future<void> setAutoPrint(bool v) async {
    autoPrint.value = v;
    (await SharedPreferences.getInstance()).setBool(_keyAuto, v);
  }

  Future<void> refreshPrinters() async {
    printers.value = await _listPrinters();
  }

  // ── Printer enumeration (PowerShell) ──────────────────────────────────────

  Future<List<String>> _listPrinters() async {
    try {
      final r = await Process.run('powershell', [
        '-NoProfile', '-NonInteractive', '-command',
        'Get-Printer | Select-Object -ExpandProperty Name',
      ]);
      if (r.exitCode == 0) {
        return (r.stdout as String)
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Receipt building ──────────────────────────────────────────────────────

  Uint8List _buildReceipt(Order order, List<OrderItem> items) {
    final b = _EscPos();
    b.init();

    b.align(1);
    b.doubleSize(true);
    b.bold(true);
    b.text('Owaz Coffee Shop');
    b.doubleSize(false);
    b.bold(false);
    b.text('Sifaris #${order.id}');
    b.text(DateFormat('dd.MM.yyyy  HH:mm').format(order.createdAt));
    b.align(0);
    b.hr();

    for (final item in items) {
      b.row2(
        item.productName.length > 22
            ? '${item.productName.substring(0, 20)}..'
            : item.productName,
        'x${item.quantity}  ${formatCurrency(item.total)}',
      );
    }

    b.hr();
    b.bold(true);
    b.row2('JEMI:', formatCurrency(order.total));
    b.bold(false);

    if (order.discount > 0) {
      b.row2('Arzanlyk:', '-${formatCurrency(order.discount)}');
    }
    b.row2('Toleg:', formatCurrency(order.paid));

    final change = order.paid - order.total;
    if (change > 0.005) b.row2('Gaytargy:', formatCurrency(change));

    b.hr();
    b.align(1);
    b.bold(true);
    b.text('Sag bolun!');
    b.bold(false);
    b.feed(4);
    b.cut();

    return b.bytes;
  }

  Uint8List _buildTestReceipt() {
    final b = _EscPos();
    b.init();
    b.align(1);
    b.bold(true);
    b.doubleSize(true);
    b.text('TEST');
    b.doubleSize(false);
    b.text('Owaz Coffee Shop');
    b.bold(false);
    b.text(DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()));
    b.hr();
    b.text('Yazici test basarili!');
    b.hr();
    b.feed(4);
    b.cut();
    return b.bytes;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<bool> printReceipt(Order order, List<OrderItem> items) async {
    if (kIsWeb || !Platform.isWindows) return false;
    if (selectedPrinter.value.isEmpty) return false;
    try {
      return _rawPrint(selectedPrinter.value, _buildReceipt(order, items));
    } catch (_) {
      return false;
    }
  }

  Future<bool> testPrint() async {
    if (kIsWeb || !Platform.isWindows) return false;
    if (selectedPrinter.value.isEmpty) return false;
    try {
      return _rawPrint(selectedPrinter.value, _buildTestReceipt());
    } catch (_) {
      return false;
    }
  }

  // ── Win32 raw print ───────────────────────────────────────────────────────

  bool _rawPrint(String name, Uint8List data) {
    return using<bool>((arena) {
      final hPrinter = arena<IntPtr>();
      final pName = name.toNativeUtf16(allocator: arena);

      if (OpenPrinter(pName, hPrinter.cast(), nullptr) == FALSE) return false;

      final di = arena<_DocInfo>();
      di.ref.pDocName = 'Receipt'.toNativeUtf16(allocator: arena);
      di.ref.pOutputFile = nullptr;
      di.ref.pDatatype = 'RAW'.toNativeUtf16(allocator: arena);

      if (StartDocPrinter(hPrinter.value, 1, di.cast()) == 0) {
        ClosePrinter(hPrinter.value);
        return false;
      }

      StartPagePrinter(hPrinter.value);

      final buf = arena<Uint8>(data.length);
      buf.asTypedList(data.length).setAll(0, data);
      final written = arena<DWORD>();
      WritePrinter(hPrinter.value, buf, data.length, written);

      EndPagePrinter(hPrinter.value);
      EndDocPrinter(hPrinter.value);
      ClosePrinter(hPrinter.value);
      return true;
    });
  }
}
