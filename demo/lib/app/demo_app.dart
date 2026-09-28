// Copyright (c) 2026 kacpmu
//
// Use of this source code is governed by the MIT license that can be found
// in the LICENSE file.

import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:material_layout/material_layout.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mail.dart';
import 'settings.dart';

export 'settings.dart';

/// How far the icon of an icon button in [theme] sits inside the button:
/// 12dp inside a padded 48dp target, 8dp inside a 40dp button where tap
/// targets are not padded, as on desktop.
double iconButtonInset(ThemeData theme) =>
    theme.materialTapTargetSize == MaterialTapTargetSize.padded ? 12 : 8;

/// Publishes the mail store.
class Mail extends InheritedNotifier<MailStore> {
  const new({super.key, required super.notifier, required super.child});

  static MailStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Mail>()!.notifier!;
}

/// The demo app: its theme, its settings and its data, around either a
/// home widget or a router.
class DemoApp extends StatefulWidget {
  const new({super.key, this.home, this.routerConfig})
    : assert((home == null) != (routerConfig == null));

  final Widget? home;
  final RouterConfig<Object>? routerConfig;

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  final _settings = ValueNotifier(const DemoSettings());
  final _inboxSplit = PaneSplitController();
  final _settingsSheet = SettingsSheetMemory();
  final _mail = MailStore();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_slowAnimations);
  }

  // Slows every animation of the app, the settings sheet's included, by as
  // much as the settings ask.
  void _slowAnimations() => timeDilation = _settings.value.slowAnimations;

  @override
  void dispose() {
    // Whatever runs next runs at normal speed.
    timeDilation = 1;
    _settings.dispose();
    _inboxSplit.dispose();
    _mail.dispose();
    super.dispose();
  }

  ThemeData _theme(Brightness brightness, DemoSettings settings) {
    final theme = ThemeData(
      brightness: brightness,
      colorSchemeSeed: const Color(0xFF35658F),
    );
    return theme.copyWith(
      // The layout tokens travel with the theme, as a theme extension.
      extensions: [
        MaterialLayoutThemeData(
          breakpoints: settings.breakpoints,
          motionScheme: settings.motionScheme,
          dragHandleStyle: settings.handleStyleIn(theme.colorScheme),
          paneSurfaceStyle: settings.paneSurfaceStyleIn(theme.colorScheme),
          sideSheetStyle: settings.sideSheetStyleIn(theme.colorScheme),
        ),
      ],
      // Material places an app bar's last action 16dp from its end, where
      // Flutter's app bar leaves the icon 12dp in, or 8dp in on desktop.
      appBarTheme: theme.appBarTheme.copyWith(
        actionsPadding: EdgeInsetsDirectional.only(
          end: 16 - iconButtonInset(theme),
        ),
      ),
    );
  }

  Widget _builder(BuildContext context, Widget? child) {
    // By default, the one pane of a compact window is flat, and panes are
    // rounded cards in wider windows. The layouts keep their margins within
    // the panes or around them to match, and keep the cards' corners
    // while panes and pages move.
    final settings = Settings.of(context);
    final layout = MaterialLayoutTheme.of(context);
    final flat = switch (settings.paneStyle) {
      PaneStyle.byWindow =>
        layout.breakpoints.forWidth(MediaQuery.sizeOf(context).width) ==
            Breakpoint.compact,
      PaneStyle.cards => false,
      PaneStyle.flat => true,
    };
    Widget app = Directionality(
      textDirection: settings.rtl ? TextDirection.rtl : TextDirection.ltr,
      child: MaterialLayoutTheme(
        data: layout.copyWith(
          marginPlacement: flat
              ? MarginPlacement.inside
              : MarginPlacement.outside,
          paneBorderRadius: flat
              ? BorderRadius.zero
              : BorderRadius.circular(settings.cardRadius),
        ),
        child: child!,
      ),
    );
    // As the platform's settings do, which the package follows. The
    // settings sheet keeps the platform's text scale.
    final textScale = settings.textScale;
    if (settings.reduceMotion || textScale != null) {
      final media = MediaQuery.of(context);
      app = MediaQuery(
        data: media.copyWith(
          disableAnimations: settings.reduceMotion || media.disableAnimations,
          textScaler: textScale == null ? null : TextScaler.linear(textScale),
        ),
        child: app,
      );
    }
    return app;
  }

  @override
  Widget build(BuildContext context) => Settings(
    notifier: _settings,
    child: InboxSplit(
      controller: _inboxSplit,
      child: SettingsSheetMemoryScope(
        memory: _settingsSheet,
        child: Mail(
          notifier: _mail,
          child: ValueListenableBuilder(
            valueListenable: _settings,
            builder: (context, settings, _) {
              final theme = _theme(Brightness.light, settings);
              final darkTheme = _theme(Brightness.dark, settings);
              final mode = settings.dark ? ThemeMode.dark : ThemeMode.light;
              const localizations = [MaterialLayoutLocalizations.delegate];
              final router = widget.routerConfig;
              if (router != null) {
                return MaterialApp.router(
                  title: 'material_layout',
                  debugShowCheckedModeBanner: false,
                  theme: theme,
                  darkTheme: darkTheme,
                  themeMode: mode,
                  localizationsDelegates: localizations,
                  builder: _builder,
                  routerConfig: router,
                );
              }
              return MaterialApp(
                title: 'material_layout',
                debugShowCheckedModeBanner: false,
                theme: theme,
                darkTheme: darkTheme,
                themeMode: mode,
                localizationsDelegates: localizations,
                builder: _builder,
                home: widget.home,
              );
            },
          ),
        ),
      ),
    ),
  );
}
