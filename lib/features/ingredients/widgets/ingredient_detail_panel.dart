import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../../controllers/stock_controller.dart';
import '../../../controllers/database_controller.dart';
import '../../../data/database/app_database.dart';
import '../../../core/constants/color_constants.dart';
import 'ing_shared.dart';

class IngDetailPanel extends StatefulWidget {
  final Ingredient ingredient;
  final VoidCallback onClose;
  final bool isDark;

  const IngDetailPanel({
    super.key,
    required this.ingredient,
    required this.onClose,
    required this.isDark,
  });

  @override
  State<IngDetailPanel> createState() => _IngDetailPanelState();
}

class _IngDetailPanelState extends State<IngDetailPanel> {
  final _stock = StockController.to;
  List<Product>? _usedInProducts;

  @override
  void initState() {
    super.initState();
    _stock.selectIngredient(widget.ingredient);
    _loadUsedIn();
  }

  @override
  void didUpdateWidget(IngDetailPanel old) {
    super.didUpdateWidget(old);
    if (old.ingredient.id != widget.ingredient.id) {
      _stock.selectIngredient(widget.ingredient);
      setState(() => _usedInProducts = null);
      _loadUsedIn();
    }
  }

  Future<void> _loadUsedIn() async {
    final db = Get.find<DatabaseController>().db;
    final products =
        await db.getProductsUsingIngredient(widget.ingredient.id);
    if (mounted) setState(() => _usedInProducts = products);
  }

  void _openReceipt() {
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    Get.dialog(
      IngDialogShell(
        title: 'stock_receipt'.tr,
        width: 360,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IngField(
                controller: qtyCtrl,
                label: 'stock_qty'.tr,
                numeric: true,
                suffix: widget.ingredient.unit),
            const SizedBox(height: 12),
            IngField(
                controller: costCtrl,
                label: 'stock_unit_cost'.tr,
                numeric: true,
                suffix: 'TMT'),
            const SizedBox(height: 12),
            IngField(controller: noteCtrl, label: 'stock_note'.tr),
            const SizedBox(height: 20),
            IngDialogActions(
              cancelLabel: 'gen_cancel'.tr,
              confirmLabel: 'gen_add'.tr,
              onConfirm: () async {
                final qty = double.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) {
                  Get.snackbar('gen_error'.tr, 'stock_invalid_qty'.tr,
                      backgroundColor: AppColors.red,
                      colorText: Colors.white);
                  return;
                }
                final cost = double.tryParse(costCtrl.text) ?? 0;
                Get.back();
                await _stock.addReceipt(
                  ingredientId: widget.ingredient.id,
                  qty: qty,
                  unitCost: cost,
                  note: noteCtrl.text.trim().isEmpty
                      ? null
                      : noteCtrl.text.trim(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openWriteOff() {
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    Get.dialog(
      IngDialogShell(
        title: 'stock_writeoff'.tr,
        width: 360,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IngField(
                controller: qtyCtrl,
                label: 'stock_qty'.tr,
                numeric: true,
                suffix: widget.ingredient.unit),
            const SizedBox(height: 12),
            IngField(controller: reasonCtrl, label: 'stock_reason'.tr),
            const SizedBox(height: 20),
            IngDialogActions(
              cancelLabel: 'gen_cancel'.tr,
              confirmLabel: 'stock_writeoff'.tr,
              onConfirm: () async {
                final qty = double.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) {
                  Get.snackbar('gen_error'.tr, 'stock_invalid_qty'.tr,
                      backgroundColor: AppColors.red,
                      colorText: Colors.white);
                  return;
                }
                Get.back();
                await _stock.addWriteOff(
                  ingredientId: widget.ingredient.id,
                  qty: qty,
                  reason: reasonCtrl.text.trim().isEmpty
                      ? '—'
                      : reasonCtrl.text.trim(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.bgCard : Colors.white;
    final border = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final cardColor = isDark ? AppColors.bgSurface : const Color(0xFFF8FAFF);
    final ing = widget.ingredient;
    final isLow = ing.minStock > 0 && ing.stock <= ing.minStock;
    final accentColor = isLow ? AppColors.red : AppColors.primary2;

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: bg,
        border: Border(left: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ing.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ing.name,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Obx(() {
                            final sel = _stock.selectedIngredient.value;
                            final stock =
                                (sel?.id == ing.id ? sel?.stock : null) ??
                                    ing.stock;
                            final low =
                                ing.minStock > 0 && stock <= ing.minStock;
                            return Row(
                              children: [
                                if (low)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedAlert02,
                                      size: 11,
                                      color: AppColors.red,
                                    ),
                                  ),
                                Text(
                                  '${stock.toStringAsFixed(2)} ${ing.unit}',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 12,
                                    color: low
                                        ? AppColors.red
                                        : AppColors.textGrey,
                                    fontWeight: low
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(20),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PanelActionBtn(
                        label: 'stock_receipt'.tr,
                        icon: HugeIcons.strokeRoundedPackageAdd,
                        color: AppColors.green,
                        onTap: _openReceipt,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PanelActionBtn(
                        label: 'stock_writeoff'.tr,
                        icon: HugeIcons.strokeRoundedPackageRemove,
                        color: AppColors.red,
                        onTap: _openWriteOff,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Period filter ────────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border))),
            child: Obx(() {
              final current = _stock.filterPeriod.value;
              const periods = ['all', 'today', 'week'];
              final labels = [
                'rep_all'.tr,
                'rep_today'.tr,
                'rep_week'.tr
              ];
              return Row(
                children: List.generate(periods.length, (i) {
                  final sel = current == periods[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _stock.setPeriod(periods[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary.withAlpha(30)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sel
                                ? AppColors.primary2
                                : AppColors.bgBorder,
                          ),
                        ),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 11,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: sel
                                ? AppColors.primary2
                                : AppColors.textGrey,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),

          // ── Transactions + used-in ───────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (_stock.txLoading.value) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary2));
              }

              final txList = _stock.transactions;
              final groups = <int, _IngTxGroup>{};
              final List<Object> rows = [];
              for (final tx in txList) {
                if (tx.type == 'consume' &&
                    tx.referenceType == 'order' &&
                    tx.referenceId != null) {
                  final id = tx.referenceId!;
                  if (groups.containsKey(id)) {
                    groups[id]!.totalQty += tx.quantity;
                  } else {
                    final g = _IngTxGroup(
                        orderId: id,
                        totalQty: tx.quantity,
                        createdAt: tx.createdAt);
                    groups[id] = g;
                    rows.add(g);
                  }
                } else {
                  rows.add(tx);
                }
              }

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    'stock_movements'.tr,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'stock_no_movements'.tr,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            color: AppColors.textGrey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ...rows.map((row) {
                      if (row is _IngTxGroup) {
                        return _buildGroupTile(
                            row, cardColor, border, textColor);
                      }
                      return _buildTxTile(row as InventoryTransaction,
                          cardColor, border, textColor);
                    }),
                  const SizedBox(height: 16),
                  Divider(color: border),
                  const SizedBox(height: 8),
                  Text(
                    'stock_used_in_title'.tr,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_usedInProducts == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary2)),
                    )
                  else if (_usedInProducts!.isEmpty)
                    const Text(
                      'Hiç bir harytda ulanylmaýar',
                      style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: AppColors.textGrey,
                          fontSize: 12),
                    )
                  else
                    ..._usedInProducts!.map(
                      (p) => _buildProductTile(
                          p, cardColor, border, textColor),
                    ),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(
      _IngTxGroup group, Color cardColor, Color border, Color textColor) {
    final fmt = DateFormat('dd.MM HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowUp01,
                size: 16,
                color: AppColors.red,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('stock_consume'.tr,
                    style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                Text(
                  '${'rep_order_detail'.tr}${group.orderId}',
                  style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 11,
                      color: AppColors.textGrey),
                ),
                Text(
                  fmt.format(group.createdAt),
                  style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 10,
                      color: AppColors.textDim),
                ),
              ],
            ),
          ),
          Text(
            '-${group.totalQty.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxTile(InventoryTransaction tx, Color cardColor, Color border,
      Color textColor) {
    final isPositive = _stock.isPositiveType(tx.type);
    final color = isPositive ? AppColors.green : AppColors.red;
    final fmt = DateFormat('dd.MM HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: HugeIcon(
                icon: isPositive
                    ? HugeIcons.strokeRoundedArrowDown01
                    : HugeIcons.strokeRoundedArrowUp01,
                size: 16,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stock.typeLabel(tx.type),
                  style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor),
                ),
                if (tx.note != null && tx.note!.isNotEmpty)
                  Text(
                    tx.note!,
                    style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 11,
                        color: AppColors.textGrey),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  fmt.format(tx.createdAt),
                  style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 10,
                      color: AppColors.textDim),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}${tx.quantity.toStringAsFixed(2)}',
                style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
              if (tx.unitCost > 0)
                Text(
                  '${tx.unitCost.toStringAsFixed(2)} / ед.',
                  style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 10,
                      color: AppColors.textGrey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(
      Product p, Color cardColor, Color border, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              p.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.primary2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              p.name,
              style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor),
            ),
          ),
          Text(
            p.sku,
            style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 11,
                color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _IngTxGroup {
  final int orderId;
  double totalQty;
  final DateTime createdAt;
  _IngTxGroup(
      {required this.orderId,
      required this.totalQty,
      required this.createdAt});
}

class _PanelActionBtn extends StatefulWidget {
  final String label;
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;
  const _PanelActionBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  State<_PanelActionBtn> createState() => _PanelActionBtnState();
}

class _PanelActionBtnState extends State<_PanelActionBtn> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: _hov
                ? widget.color.withAlpha(30)
                : widget.color.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.color.withAlpha(60)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: widget.icon, size: 13, color: widget.color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
