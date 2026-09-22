import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_navigation/material_navigation.dart';

/// Live, user-tweakable demo settings, surfaced through an adaptive sheet.
class DemoSettings {
  const DemoSettings({
    this.themeMode = ThemeMode.system,
    this.rtl = false,
    this.resizablePanes = true,
    this.supportingDismissible = false,
    this.listDetailBehavior = ListDetailBehavior.placeholder,
    this.railIndicatorSize = NavigationIndicatorSize.fill,
    this.modalRail = false,
  });

  final ThemeMode themeMode;
  final bool rtl;
  final bool resizablePanes;
  final bool supportingDismissible;
  final ListDetailBehavior listDetailBehavior;
  final NavigationIndicatorSize railIndicatorSize;
  final bool modalRail;

  DemoSettings copyWith({
    ThemeMode? themeMode,
    bool? rtl,
    bool? resizablePanes,
    bool? supportingDismissible,
    ListDetailBehavior? listDetailBehavior,
    NavigationIndicatorSize? railIndicatorSize,
    bool? modalRail,
  }) {
    return DemoSettings(
      themeMode: themeMode ?? this.themeMode,
      rtl: rtl ?? this.rtl,
      resizablePanes: resizablePanes ?? this.resizablePanes,
      supportingDismissible: supportingDismissible ?? this.supportingDismissible,
      listDetailBehavior: listDetailBehavior ?? this.listDetailBehavior,
      railIndicatorSize: railIndicatorSize ?? this.railIndicatorSize,
      modalRail: modalRail ?? this.modalRail,
    );
  }
}

/// Exposes the live [DemoSettings] (and a setter) to everything below it.
///
/// Both entrypoints install one, so the shared shell and the screens can read
/// settings the same way regardless of how navigation is driven.
class DemoSettingsScope extends InheritedWidget {
  const DemoSettingsScope({
    super.key,
    required this.settings,
    required this.onChanged,
    required super.child,
  });

  final DemoSettings settings;
  final ValueChanged<DemoSettings> onChanged;

  static DemoSettingsScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<DemoSettingsScope>();
    assert(scope != null, 'No DemoSettingsScope above this context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(DemoSettingsScope old) => settings != old.settings;
}
