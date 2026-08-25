import 'package:flutter/material.dart';

import 'package:demo/data/demo_settings.dart';
import 'package:demo/screens/articles_screen.dart';
import 'package:demo/shell/demo_shell.dart';
import 'package:demo/screens/feed_screen.dart';
import 'package:demo/screens/inbox/inbox_screen.dart';
import 'package:demo/screens/sheets_screen.dart';

/// A real, runnable demo app for the `material_layout` package.
///
/// It is an ordinary Flutter app — there is no simulated window. Resize the OS
/// or browser window to watch it adapt: the bottom bar becomes a rail and then
/// an expanded rail; the Inbox screen goes from a single pane (tapping a
/// message pushes a real detail route) to two resizable panes, and to three at
/// extra-large. Open the demo settings (the rail's Settings destination, or the
/// drawer) to toggle dark mode, RTL, resizable panes, and more — the settings
/// panel is itself an adaptive sheet from the package.
///
/// This entrypoint drives navigation with plain [State] and an [IndexedStack].
/// `main_router.dart` renders the **same** app through GoRouter; the two
/// differ only in how a destination change is carried out.
///
/// Run with `flutter run -t lib/main_navigator.dart -d chrome`.
void main() => runApp(const AdaptiveLayoutsDemoApp());

class AdaptiveLayoutsDemoApp extends StatefulWidget {
  const AdaptiveLayoutsDemoApp({super.key});

  @override
  State<AdaptiveLayoutsDemoApp> createState() => _AdaptiveLayoutsDemoAppState();
}

class _AdaptiveLayoutsDemoAppState extends State<AdaptiveLayoutsDemoApp> {
  DemoSettings _settings = const DemoSettings();

  ThemeData _theme(Brightness brightness) => ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorSchemeSeed: const Color(0xFF4F6BED),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'material_layout',
      debugShowCheckedModeBanner: false,
      themeMode: _settings.themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      // RTL above the Navigator so it covers pushed routes and sheets too; the
      // settings scope makes the live settings available to every screen.
      builder: (context, child) => Directionality(
        textDirection: _settings.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: DemoSettingsScope(
          settings: _settings,
          onChanged: (s) => setState(() => _settings = s),
          child: child!,
        ),
      ),
      home: const _NavigatorShell(),
    );
  }
}

/// Selection lives in plain [State]; the screens live in an [IndexedStack] so
/// each keeps its state when you switch destinations.
class _NavigatorShell extends StatefulWidget {
  const _NavigatorShell();

  @override
  State<_NavigatorShell> createState() => _NavigatorShellState();
}

class _NavigatorShellState extends State<_NavigatorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final settings = DemoSettingsScope.of(context).settings;
    return DemoShell(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      body: IndexedStack(
        index: _index,
        children: [
          InboxScreen(
            resizable: settings.resizablePanes,
            behavior: settings.listDetailBehavior,
            dismissible: settings.supportingDismissible,
          ),
          ArticlesScreen(
            resizable: settings.resizablePanes,
            dismissible: settings.supportingDismissible,
          ),
          const FeedScreen(),
          const SheetsScreen(),
        ],
      ),
    );
  }
}
