# material_layout — demo

A runnable Flutter app that exercises every part of the
[`material_layout`](../) package. It depends on the package by relative path
(`material_layout: path: ../`), so any edit to `../lib` shows up on the next
hot restart — this doubles as the manual test bed for the package.

## Running

```sh
cd demo
flutter pub get
flutter run                          # plain setState navigation
flutter run -t lib/main_router.dart  # GoRouter, selection mirrored in the URL
```

**Resize the window while it runs** — that is the whole point. Web and Linux
desktop are the best targets for that; Android works but can only show the
compact and (in split-screen or on a tablet) medium layouts.

```sh
flutter run -d chrome                # web
flutter run -d linux                 # desktop
```

### Web

The demo is web-ready: `web/` is set up, and the GoRouter entrypoint calls
`usePathUrlStrategy()` so the inbox selection shows as `/inbox/1` rather than
`/#/inbox/1`. That call comes from `flutter_web_plugins`, which ships a non-web
stub, so it stays a no-op on Android, desktop and in tests.

If `flutter run -d chrome` reports no Chrome device, point Flutter at whichever
browser you have:

```sh
CHROME_EXECUTABLE=/usr/bin/chromium flutter run -d chrome
```

`.vscode/launch.json` already sets that for the two web configurations, so
running from the IDE works without touching your shell. **It hardcodes
`/usr/bin/chromium` — change or drop that `env` block if your browser lives
somewhere else.**

To build a deployable bundle:

```sh
flutter build web -t lib/main_router.dart
```

Three panes (Mail's filters pane) need a window of 1600dp or wider, so web or
desktop is the only way to see that layout.

## Where things live

Start with **`lib/main_navigator.dart`** — it is the simpler entrypoint, and the
shortest path from `runApp` to a layout.

```
lib/
  main_navigator.dart      entrypoint A — setState + IndexedStack
  main_router.dart         entrypoint B — GoRouter, selection in the URL
  shell/                   the chrome both entrypoints share
    demo_shell.dart          AdaptiveNavigationScaffold, destinations, rail sections
    settings_sheet.dart      the demo's own settings, in an adaptive sheet
    animated_fab.dart        rail widgets used by the shell
    animated_menu_button.dart
  screens/                 one file per destination
    inbox/                   the busiest screen, so it gets a folder
      inbox_screen.dart        ListDetailLayout + SupportingPaneLayout
      info_pane.dart           the supporting pane (about the selected message)
      filters_sheet.dart       filters, in a standard sheet
    articles_screen.dart     SupportingPaneLayout with the default resolver
    feed_screen.dart         FeedLayout
    sheets_screen.dart       every sheet the package can open
  data/                    plain sample data and settings — no package APIs
    demo_data.dart
    demo_settings.dart
```

Every file opens with a `Demonstrates:` line naming the package APIs it shows,
so you can jump straight to the one you care about.

### Which file shows which feature

| Package API | Read |
| --- | --- |
| `AdaptiveNavigationScaffold` | `shell/demo_shell.dart` |
| `ListDetailLayout` | `screens/inbox/inbox_screen.dart` |
| `SupportingPaneLayout` | `screens/articles_screen.dart` (default resolver), `screens/inbox/inbox_screen.dart` (custom) |
| `FeedLayout` | `screens/feed_screen.dart` |
| `PaneContainer` | `screens/inbox/inbox_screen.dart`, `screens/inbox/info_pane.dart` |
| Sheets | `screens/sheets_screen.dart`, `screens/inbox/filters_sheet.dart` |
| `adaptiveValue`, `context.windowSizeClass` | `shell/demo_shell.dart` |

## Entrypoints

| File | What it shows |
| --- | --- |
| `lib/main_navigator.dart` | Plain `setState` over an `IndexedStack`, so each destination keeps its state. **Start here.** |
| `lib/main_router.dart` | The same screens driven by **GoRouter**. The inbox selection lives in the URL (`/inbox/:id`), so `ListDetailLayout` runs in *controlled* mode. |

Both entrypoints render the same `DemoShell` and the same screens; only the
push/pop strategy differs.

## Screens

| Screen | Package feature |
| --- | --- |
| **Inbox** | `ListDetailLayout` — one pane on narrow widths (tapping pushes a real detail route, system Back returns), two resizable panes when wide, and **three** at extra-large: a `SupportingPaneLayout` adds an *info* pane about the selected message. Below 1600dp the detail's info action opens it as a sheet. Filters live in a **standard** sheet instead, since they act on the list rather than one message. |
| **Articles** | `SupportingPaneLayout` — a "Related people" pane beside the article when there is room, presented as an adaptive sheet when there is not. |
| **Feed** | `FeedLayout` — a grid that reflows by column count. |
| **Sheets** | `showAppBottomSheet`, `showSideSheet`, `showAdaptiveSheet` in both standard and modal modes. |

The chrome around them is `AdaptiveNavigationScaffold`, which places the
navigation bar (compact/medium) or rail (expanded and wider) by window size.
The bar and rail themselves come from the
[`material_navigation`](https://pub.dev/packages/material_navigation) package —
the scaffold only reveals and hides them; it never reaches inside.

## Demo settings

The tune icon (top right, or the rail's Settings destination in the router
demo) opens a settings sheet — itself an adaptive sheet from the package.
It toggles dark mode, RTL, resizable panes, the dismissible supporting pane,
the list-detail empty state (`placeholder` / `hidden` / `selected`),
the rail indicator size, and whether the extended rail is modal.

## Tests

```sh
flutter test
```

`test/widget_test.dart` is a smoke test over the real app: it pumps the demo at
compact and expanded window sizes and asserts that the navigation bar and rail
reveal and collapse correctly (using the package's `navigationBarRevealKey` /
`navigationRailRevealKey`), and that the list-detail layout pushes a page when
narrow but shows both panes when wide.

> The pane reveal is spring-driven and settles asymptotically, so these tests
> pump a fixed frame budget rather than calling `pumpAndSettle()`, which can
> spin on a spring that never reports itself done.

## Notes

* On web, URLs default to the hash strategy (`/#/inbox/1`). For clean paths,
  add `flutter_web_plugins` from the SDK and call `usePathUrlStrategy()` in
  `main_router.dart` — left out here so the demo carries no web-only deps.
* The Mail list pane is wrapped in a transparent `Material`. `ListDetailLayout`
  pushes it as a real page on compact widths, and the route transition paints a
  background behind it; without its own `Material` the tiles' ink and selection
  highlight would be hidden by it.
