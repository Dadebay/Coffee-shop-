import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../controllers/database_controller.dart';
import '../../controllers/stock_controller.dart';
import '../../data/database/app_database.dart';
import '../../core/constants/color_constants.dart';
import '../../core/widgets/numpad.dart';

class StockMovementsScreen extends StatelessWidget {
  const StockMovementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = StockController.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : const Color(0xFFF5F5F7);
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final surfaceColor = isDark ? AppColors.bgSurface : const Color(0xFFF8FAFF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedWarehouse,
                  size: 22,
                  color: AppColors.primary2,
                ),
                const SizedBox(width: 12),
                Text(
                  'stock_movements'.tr,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                // Period filter chips
                _PeriodChips(ctrl: ctrl),
              ],
            ),
          ),

          // ── Body: split panel ─────────────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Left panel — ingredient list
                _IngredientPanel(ctrl: ctrl, isDark: isDark),

                // Right panel — transaction history + action buttons
                Expanded(
                  child: Column(
                    children: [
                      // Action buttons row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          border: Border(bottom: BorderSide(color: borderColor)),
                        ),
                        child: Obx(() {
                          final hasSelected =
                              ctrl.selectedIngredient.value != null;
                          final ing = ctrl.selectedIngredient.value;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Buttons — wrap if not enough space
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _ActionButton(
                                    label: 'stock_receipt'.tr,
                                    icon: HugeIcons.strokeRoundedPackageAdd,
                                    color: AppColors.green,
                                    enabled: hasSelected,
                                    onTap: hasSelected
                                        ? () => _showReceiptDialog(context, ctrl, isDark)
                                        : null,
                                  ),
                                  _ActionButton(
                                    label: 'stock_writeoff'.tr,
                                    icon: HugeIcons.strokeRoundedPackageRemove,
                                    color: AppColors.red,
                                    enabled: hasSelected,
                                    onTap: hasSelected
                                        ? () => _showWriteOffDialog(context, ctrl, isDark)
                                        : null,
                                  ),
                                  _ActionButton(
                                    label: 'stock_used_in_btn'.tr,
                                    icon: HugeIcons.strokeRoundedPackageSearch,
                                    color: AppColors.primary2,
                                    enabled: hasSelected,
                                    onTap: hasSelected
                                        ? () => _showUsedInDialog(context, ctrl, isDark)
                                        : null,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Selected ingredient info
                              if (ing != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ing.name,
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      '${'ing_stock'.tr}: ${ing.stock.toStringAsFixed(2)} ${ing.unit}',
                                      style: const TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 13,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          );
                        }),
                      ),

                      // Transaction list
                      Expanded(
                        child: Obx(() {
                          if (ctrl.selectedIngredient.value == null) {
                            return _EmptyState(
                              icon: HugeIcons.strokeRoundedWarehouse,
                              message: 'stock_select_ingredient'.tr,
                            );
                          }
                          if (ctrl.txLoading.value) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (ctrl.transactions.isEmpty) {
                            return _EmptyState(
                              icon: HugeIcons.strokeRoundedFileNotFound,
                              message: 'stock_no_movements'.tr,
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: ctrl.transactions.length,
                            itemBuilder: (ctx, i) {
                              final tx = ctrl.transactions[i];
                              return _TransactionTile(
                                tx: tx,
                                ctrl: ctrl,
                                isDark: isDark,
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _showUsedInDialog(
      BuildContext context, StockController ctrl, bool isDark) {
    final ing = ctrl.selectedIngredient.value!;
    final db = Get.find<DatabaseController>().db;
    Get.dialog(_UsedInDialog(ing: ing, db: db, isDark: isDark));
  }

  void _showReceiptDialog(
      BuildContext context, StockController ctrl, bool isDark) {
    final ing = ctrl.selectedIngredient.value!;
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    Get.dialog(
      _StockDialog(
        title: 'stock_receipt'.tr,
        titleColor: AppColors.green,
        icon: HugeIcons.strokeRoundedPackageAdd,
        ingredient: ing,
        isDark: isDark,
        qtyCtrl: qtyCtrl,
        costCtrl: costCtrl,
        noteCtrl: noteCtrl,
        showCost: true,
        onConfirm: () async {
          final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
          final cost =
              double.tryParse(costCtrl.text.replaceAll(',', '.')) ?? 0.0;
          if (qty == null || qty <= 0) {
            Get.snackbar('gen_error'.tr, 'stock_invalid_qty'.tr,
                backgroundColor: AppColors.red,
                colorText: Colors.white);
            return;
          }
          Get.back();
          await ctrl.addReceipt(
            ingredientId: ing.id,
            qty: qty,
            unitCost: cost,
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          );
        },
      ),
      barrierDismissible: true,
    );
  }

  void _showWriteOffDialog(
      BuildContext context, StockController ctrl, bool isDark) {
    final ing = ctrl.selectedIngredient.value!;
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    Get.dialog(
      _StockDialog(
        title: 'stock_writeoff'.tr,
        titleColor: AppColors.red,
        icon: HugeIcons.strokeRoundedPackageRemove,
        ingredient: ing,
        isDark: isDark,
        qtyCtrl: qtyCtrl,
        noteCtrl: noteCtrl,
        showCost: false,
        costCtrl: TextEditingController(),
        onConfirm: () async {
          final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));
          if (qty == null || qty <= 0) {
            Get.snackbar('gen_error'.tr, 'stock_invalid_qty'.tr,
                backgroundColor: AppColors.red,
                colorText: Colors.white);
            return;
          }
          Get.back();
          await ctrl.addWriteOff(
            ingredientId: ing.id,
            qty: qty,
            reason: noteCtrl.text.trim().isEmpty
                ? 'stock_writeoff'.tr
                : noteCtrl.text.trim(),
          );
        },
      ),
      barrierDismissible: true,
    );
  }
}

// ── Ingredient panel (left sidebar) ──────────────────────────────────────────
class _IngredientPanel extends StatefulWidget {
  final StockController ctrl;
  final bool isDark;
  const _IngredientPanel({required this.ctrl, required this.isDark});

  @override
  State<_IngredientPanel> createState() => _IngredientPanelState();
}

class _IngredientPanelState extends State<_IngredientPanel> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final ctrl = widget.ctrl;
    final bg = isDark ? AppColors.bgCard : Colors.white;
    final border = isDark ? AppColors.bgBorder : const Color(0xFFE8EAEF);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ing_title'.tr,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'pos_search'.tr,
                    hintStyle: const TextStyle(fontFamily: 'Gilroy', fontSize: 13, color: AppColors.textGrey),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 15, color: AppColors.textGrey),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () { _search.clear(); setState(() => _query = ''); },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 13, color: AppColors.textGrey),
                            ),
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    filled: true,
                    fillColor: isDark ? AppColors.bgSurface : const Color(0xFFF4F6FA),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary2, width: 1.5)),
                  ),
                ),
              ],
            ),
          ),

          // List — loading/ingredients/selected are each in their own Obx
          Expanded(
            child: Obx(() {
              if (ctrl.loading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary2));
              }
              final all = ctrl.ingredients;
              final filtered = _query.isEmpty
                  ? all
                  : all.where((i) => i.name.toLowerCase().contains(_query)).toList();
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 28, color: AppColors.textGrey),
                      const SizedBox(height: 8),
                      Text('pos_no_products'.tr, style: const TextStyle(fontFamily: 'Gilroy', color: AppColors.textGrey, fontSize: 12)),
                    ],
                  ),
                );
              }
              final selectedId = ctrl.selectedIngredient.value?.id;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final ing = filtered[i];
                  final selected = selectedId == ing.id;
                  final isLow = ing.minStock > 0 && ing.stock <= ing.minStock;
                  return _IngredientTile(
                    ingredient: ing,
                    selected: selected,
                    isLow: isLow,
                    isDark: isDark,
                    borderColor: border,
                    onTap: () => ctrl.selectIngredient(ing),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Period filter chips ────────────────────────────────────────────────────────
class _PeriodChips extends StatelessWidget {
  final StockController ctrl;
  const _PeriodChips({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    const periods = ['all', 'today', 'week'];
    final labels = [
      'rep_all'.tr.isEmpty ? 'Все' : 'rep_all'.tr,
      'rep_today'.tr,
      'rep_week'.tr,
    ];
    return Obx(() {
      final current = ctrl.filterPeriod.value;
      return Row(
        children: List.generate(periods.length, (i) {
          final selected = current == periods[i];
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () => ctrl.setPeriod(periods[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withAlpha(30)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary2 : AppColors.bgBorder,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.primary2 : AppColors.textGrey,
                  ),
                ),
              ),
            ),
          );
        }),
      );
    });
  }
}

// ── Ingredient tile ────────────────────────────────────────────────────────────
class _IngredientTile extends StatefulWidget {
  final Ingredient ingredient;
  final bool selected;
  final bool isLow;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _IngredientTile({
    required this.ingredient,
    required this.selected,
    required this.isLow,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_IngredientTile> createState() => _IngredientTileState();
}

class _IngredientTileState extends State<_IngredientTile> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    final sel = widget.selected;
    final isDark = widget.isDark;

    final hoverColor = isDark ? AppColors.bgSurface : const Color(0xFFF0F4FF);
    final bg = sel
        ? AppColors.primary2
        : _hov
            ? hoverColor
            : hoverColor.withAlpha(0);
    final nameColor = sel ? Colors.white : (isDark ? AppColors.textWhite : const Color(0xFF0F172A));
    final subColor = sel
        ? Colors.white.withAlpha(190)
        : (widget.isLow ? AppColors.red : AppColors.textGrey);

    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel
                ? [BoxShadow(color: AppColors.primary2.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          child: Row(
            children: [
              // Avatar initial
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: sel
                      ? Colors.white.withAlpha(30)
                      : AppColors.primary.withAlpha(isDark ? 30 : 15),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  ing.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: sel ? Colors.white : AppColors.primary2,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: nameColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        if (widget.isLow && !sel)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                  color: AppColors.red, shape: BoxShape.circle),
                            ),
                          ),
                        Text(
                          '${ing.stock.toStringAsFixed(2)} ${ing.unit}',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 11,
                            color: subColor,
                            fontWeight: widget.isLow ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (sel)
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                  size: 16,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Transaction tile ──────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final InventoryTransaction tx;
  final StockController ctrl;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;

  const _TransactionTile({
    required this.tx,
    required this.ctrl,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = ctrl.isPositiveType(tx.type);
    final color = isPositive ? AppColors.green : AppColors.red;
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    final canDrill = tx.type == 'consume' && tx.referenceId != null;

    return GestureDetector(
      onTap: canDrill
          ? () => _showOrderProductsDialog(context, tx.referenceId!)
          : null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: canDrill
            ? borderColor.withAlpha(200)
            : borderColor),
      ),
      child: Row(
        children: [
          // Type indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: HugeIcon(
                icon: isPositive
                    ? HugeIcons.strokeRoundedArrowDown01
                    : HugeIcons.strokeRoundedArrowUp01,
                size: 18,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Type label + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctrl.typeLabel(tx.type),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (tx.note != null && tx.note!.isNotEmpty)
                  Text(
                    tx.note!,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  fmt.format(tx.createdAt),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 11,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          // Quantity
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}${tx.quantity.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (tx.unitCost > 0)
                Text(
                  '${tx.unitCost.toStringAsFixed(2)} / ед.',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
            ],
          ),
        ],
      ),
    ));
  }

  void _showOrderProductsDialog(BuildContext context, int orderId) {
    final db = Get.find<DatabaseController>().db;
    Get.dialog(_OrderProductsDialog(orderId: orderId, db: db, isDark: isDark));
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 48, color: AppColors.textDim),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final List<List<dynamic>> icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: enabled ? color : color.withAlpha(60),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 17,
              color: Colors.white.withAlpha(enabled ? 255 : 150),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withAlpha(enabled ? 255 : 150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stock dialog (receipt / write-off) ────────────────────────────────────────
class _StockDialog extends StatefulWidget {
  final String title;
  final Color titleColor;
  final List<List<dynamic>> icon;
  final Ingredient ingredient;
  final bool isDark;
  final TextEditingController qtyCtrl;
  final TextEditingController costCtrl;
  final TextEditingController noteCtrl;
  final bool showCost;
  final VoidCallback onConfirm;

  const _StockDialog({
    required this.title,
    required this.titleColor,
    required this.icon,
    required this.ingredient,
    required this.isDark,
    required this.qtyCtrl,
    required this.costCtrl,
    required this.noteCtrl,
    required this.showCost,
    required this.onConfirm,
  });

  @override
  State<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<_StockDialog> {
  // Numpad display value
  String _numpadValue = '';

  void _onNumpadTap(String val) {
    setState(() {
      if (val == '⌫') {
        if (_numpadValue.isNotEmpty) {
          _numpadValue = _numpadValue.substring(0, _numpadValue.length - 1);
        }
      } else if (val == '.') {
        if (!_numpadValue.contains('.')) {
          _numpadValue = _numpadValue.isEmpty ? '0.' : '$_numpadValue.';
        }
      } else {
        _numpadValue += val;
      }
      widget.qtyCtrl.text = _numpadValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final surfaceColor = isDark ? AppColors.bgSurface : Colors.white;
    final cardColor = isDark ? AppColors.bgCard : const Color(0xFFF8FAFF);
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: cardColor,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary2),
      ),
      labelStyle: const TextStyle(fontFamily: 'Gilroy', fontSize: 13),
    );

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.titleColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: HugeIcon(
                        icon: widget.icon, size: 20, color: widget.titleColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        widget.ingredient.name,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: Get.back,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 22,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quantity display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.titleColor.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.titleColor.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Text(
                    'stock_qty'.tr,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 13,
                      color: widget.titleColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _numpadValue.isEmpty ? '0' : _numpadValue,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: widget.titleColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.ingredient.unit,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 13,
                      color: widget.titleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Numpad
            _Numpad(
              onTap: _onNumpadTap,
              accentColor: widget.titleColor,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Unit cost (only for receipt)
            if (widget.showCost) ...[
              TextFormField(
                controller: widget.costCtrl,
                style: TextStyle(fontFamily: 'Gilroy', color: textColor),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: inputDecoration.copyWith(
                  labelText: 'stock_unit_cost'.tr,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedMoney01, size: 18, color: AppColors.textGrey),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Note
            TextField(
              controller: widget.noteCtrl,
              style: TextStyle(fontFamily: 'Gilroy', color: textColor),
              decoration: inputDecoration.copyWith(
                labelText: 'stock_note'.tr,
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedNote01, size: 18, color: AppColors.textGrey),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: widget.titleColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: widget.onConfirm,
                child: Text(
                  'gen_save'.tr,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Numpad widget ──────────────────────────────────────────────────────────────
class _Numpad extends StatelessWidget {
  final Function(String) onTap;
  final Color accentColor;
  final bool isDark;

  const _Numpad({
    required this.onTap,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = isDark ? AppColors.bgCard : const Color(0xFFF0F0F5);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    const keys = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              final isBack = key == '⌫';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onTap(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      height: 52,
                      decoration: BoxDecoration(
                        color: isBack
                            ? AppColors.red.withAlpha(20)
                            : btnColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isBack
                              ? AppColors.red.withAlpha(60)
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: isBack
                            ? const HugeIcon(
                                icon: HugeIcons.strokeRoundedDelete02,
                                size: 20,
                                color: AppColors.red,
                              )
                            : Text(
                                key,
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Used-in Products Dialog ────────────────────────────────────────────────

class _UsedInDialog extends StatefulWidget {
  final Ingredient ing;
  final AppDatabase db;
  final bool isDark;
  const _UsedInDialog({required this.ing, required this.db, required this.isDark});

  @override
  State<_UsedInDialog> createState() => _UsedInDialogState();
}

class _UsedInDialogState extends State<_UsedInDialog> {
  List<Product>? _products;

  @override
  void initState() {
    super.initState();
    widget.db.getProductsUsingIngredient(widget.ing.id).then((list) {
      if (mounted) setState(() => _products = list);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary2.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPackageSearch,
                      size: 18,
                      color: AppColors.primary2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ing.name,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'stock_used_in_title'.tr,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close, color: AppColors.textGrey, size: 20),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor, height: 1),
            // Content
            if (_products == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary2)),
              )
            else if (_products!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Hiç bir harytda ulanylmaýar',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      color: AppColors.textGrey,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _products!.length,
                  separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
                  itemBuilder: (_, i) {
                    final p = _products![i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                p.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.primary2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          Text(
                            'SKU: ${p.sku}',
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 11,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Order Products Dialog ───────────────────────────────────────────────────

class _OrderProductsDialog extends StatefulWidget {
  final int orderId;
  final AppDatabase db;
  final bool isDark;
  const _OrderProductsDialog({required this.orderId, required this.db, required this.isDark});

  @override
  State<_OrderProductsDialog> createState() => _OrderProductsDialogState();
}

class _OrderProductsDialogState extends State<_OrderProductsDialog> {
  List<OrderItem>? _items;

  @override
  void initState() {
    super.initState();
    widget.db.getOrderItems(widget.orderId).then((list) {
      if (mounted) setState(() => _items = list);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardColor = isDark ? AppColors.bgCard : Colors.white;
    final borderColor = isDark ? AppColors.bgBorder : const Color(0xFFE2E8F0);
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary2.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedShoppingCart01,
                      size: 18,
                      color: AppColors.primary2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'rep_order_detail'.tr}${widget.orderId}',
                          style: TextStyle(fontFamily: 'Gilroy', fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        Text(
                          'rep_order_items'.tr,
                          style: const TextStyle(fontFamily: 'Gilroy', fontSize: 12, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close, color: AppColors.textGrey, size: 20),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor, height: 1),
            if (_items == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary2)),
              )
            else if (_items!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('pos_no_products'.tr,
                      style: const TextStyle(fontFamily: 'Gilroy', color: AppColors.textGrey, fontSize: 13)),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _items!.length,
                  separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
                  itemBuilder: (_, i) {
                    final item = _items![i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                item.productName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(item.productName,
                                style: TextStyle(fontFamily: 'Gilroy', fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary2.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('×${item.quantity}',
                                style: const TextStyle(fontFamily: 'Gilroy', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary2)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
