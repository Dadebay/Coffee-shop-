import 'package:flutter/widgets.dart';

/// Central place for the responsive breakpoints/sizing this app uses.
///
/// Every screen used to invent its own thresholds inline (`w < 460`,
/// `w < 700`, `.clamp(400, 860)`...) with no shared source of truth. This
/// isn't a ScreenUtil-style DPI-scaling layer — this is a single desktop
/// window that gets resized, not many differently-sized phones — so the
/// fix is just naming the numbers and reusing the same handful of helpers.

// ── Shell / navigation ───────────────────────────────────────────────────

/// Below this window width the sidebar can no longer stay expanded.
const double kDesktopBreakpoint = 1000.0;
const double kSidebarCollapsedWidth = 72.0;
const double kSidebarExpandedWidth = 220.0;

// ── Card grids: fixed column steps (e.g. ingredient tiles) ───────────────

const double kGridBreakpointNarrow = 460.0;
const double kGridBreakpointMedium = 700.0;

/// Column count that steps 2 → 3 → 4 as the grid widens. For dense grids
/// with many small cards, prefer [gridColumnsForTileWidth] instead.
int gridColumnsStepped(double width) {
  if (width < kGridBreakpointNarrow) return 2;
  if (width < kGridBreakpointMedium) return 3;
  return 4;
}

// ── Card grids: fluid, keyed to a target tile width (e.g. POS products) ──

const double kProductTileTargetWidth = 160.0;

/// Column count that keeps tiles close to [targetWidth] wide, clamped to a
/// sane range regardless of window size.
int gridColumnsForTileWidth(
  double width, {
  double targetWidth = kProductTileTargetWidth,
  int min = 2,
  int max = 10,
}) {
  return (width / targetWidth).floor().clamp(min, max);
}

// ── Dialogs ────────────────────────────────────────────────────────────────

/// Caps a dialog's height to the available window space (minus [margin] for
/// insets) so tall forms scroll instead of overflowing off-screen, while
/// never shrinking below [min] even on very short windows.
double dialogMaxHeight(
  BuildContext context, {
  double margin = 40,
  double min = 400,
  double max = 860,
}) {
  return (MediaQuery.of(context).size.height - margin).clamp(min, max);
}

// ── Responsive side panels ──────────────────────────────────────────────

/// Width for a side panel that should track a fraction of the available
/// space but stay within [min]/[max] so it's never cramped or absurdly wide.
double responsiveWidth(
  double available, {
  double fraction = 0.36,
  double min = 320,
  double max = 520,
}) {
  return (available * fraction).clamp(min, max);
}
