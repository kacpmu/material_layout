import 'package:flutter/material.dart';

import 'bottom_sheet.dart';
import 'sheet_mode.dart';
import 'side_sheet.dart';

/// Shows an **adaptive** sheet: a bottom sheet on narrow windows and a side
/// sheet on wide ones (at/above [sideBreakpoint], default 840dp).
///
/// Honors [mode] (standard vs modal) for whichever form is chosen. This is the
/// one-call way to present supplementary content that should feel native at any
/// width.
///
/// Both forms can be dragged away to dismiss ([enableDrag]) and show a drag
/// handle ([showDragHandle]) — downward for the bottom sheet, toward the
/// trailing edge for the side sheet. The handle is [dragHandle] when given,
/// otherwise the package's [SheetDragHandle], oriented to whichever form the
/// width selects.
Future<T?> showAdaptiveSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  SheetMode mode = SheetMode.modal,
  double sideBreakpoint = 840,
  double sideWidth = 256,
  double sideMaxWidth = 400,
  bool isScrollControlled = false,
  bool showDragHandle = true,
  bool enableDrag = true,
  Widget? dragHandle,
  bool useRootNavigator = false,
  Color? backgroundColor,
  Color? barrierColor,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= sideBreakpoint) {
    return showSideSheet<T>(
      context,
      builder: builder,
      mode: mode,
      width: sideWidth,
      maxWidth: sideMaxWidth,
      backgroundColor: backgroundColor,
      barrierColor: barrierColor,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      dragHandle: dragHandle,
      useRootNavigator: useRootNavigator,
    );
  }
  return showAppBottomSheet<T>(
    context,
    builder: builder,
    mode: mode,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    enableDrag: enableDrag,
    dragHandle: dragHandle,
    useRootNavigator: useRootNavigator,
    backgroundColor: backgroundColor,
  );
}
