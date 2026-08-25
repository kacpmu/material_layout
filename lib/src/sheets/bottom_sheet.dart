import 'package:flutter/material.dart';

import 'sheet_drag_handle.dart';
import 'sheet_mode.dart';

/// Shows a Material 3 bottom sheet.
///
/// * [SheetMode.modal] (default) → a modal bottom sheet over a scrim
///   ([showModalBottomSheet]).
/// * [SheetMode.standard] → a persistent bottom sheet attached to the nearest
///   [Scaffold] ([ScaffoldState.showBottomSheet]); the returned future
///   completes when it closes.
///
/// [enableDrag] allows dragging the sheet away to dismiss it. [showDragHandle]
/// draws the affordance for that: [dragHandle] when given, otherwise the
/// package's [SheetDragHandle] — the same mark [showSideSheet] uses, so the two
/// sheet forms match.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  SheetMode mode = SheetMode.modal,
  bool isScrollControlled = false,
  bool showDragHandle = true,
  bool enableDrag = true,
  Widget? dragHandle,
  bool useRootNavigator = false,
  bool useSafeArea = true,
  Color? backgroundColor,
}) {
  // The handle is drawn here rather than delegated to Flutter's own
  // `showDragHandle`, so that a custom [dragHandle] is honoured and both sheet
  // forms share one default.
  WidgetBuilder content = builder;
  if (showDragHandle) {
    final Widget handle = dragHandle ?? const SheetDragHandle();
    content = (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            handle,
            // Flexible, not Expanded: content that sizes to itself stays that
            // size, and content that wants to fill (a ListView) still can.
            Flexible(child: builder(context)),
          ],
        );
  }

  if (mode == SheetMode.modal) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      // Ours is already in `content`; Flutter's would be a second one.
      showDragHandle: false,
      enableDrag: enableDrag,
      useRootNavigator: useRootNavigator,
      useSafeArea: useSafeArea,
      backgroundColor: backgroundColor,
      builder: content,
    );
  }

  final scaffold = Scaffold.maybeOf(context);
  assert(
    scaffold != null,
    'showAppBottomSheet(mode: SheetMode.standard) attaches the sheet to the '
    'nearest Scaffold, and there is none above this context. Either use '
    'SheetMode.modal, or call this from a context below a Scaffold (a Builder '
    'inside Scaffold.body is the usual fix).',
  );
  final controller = scaffold!.showBottomSheet(
    content,
    showDragHandle: false,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
  );
  return controller.closed.then((_) => null);
}
