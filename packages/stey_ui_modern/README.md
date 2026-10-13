# stey_ui_modern

Native Flutter UI primitives based on Cloudflare, Inc.'s Kumo. Independent MIT
implementation with no React or WebView runtime dependency. Development preview:
full component, interaction and visual parity has not yet been certified.

Requires Flutter 3.47.0 / Dart 3.13+. Supports platform-neutral widgets for Web,
Windows, macOS, Linux, Android and iOS; see the monorepo verification report for
which builds and devices have actually been tested.

```dart
import 'package:flutter/material.dart';
import 'package:stey_ui_modern/stey_ui_modern.dart';

MaterialApp(
  theme: SteyTheme.material(Brightness.light),
  home: SteyTheme(
    brightness: Brightness.light,
    child: Scaffold(body: SteyButton(
      onPressed: save,
      child: const Text('Save'),
    )),
  ),
);
```

Documentation and interactive gallery source:
https://github.com/stey-jp/stey-ui

Cloudflare and Kumo trademarks belong to Cloudflare, Inc. No affiliation or
endorsement is claimed. Cloudflare logo assets are withheld pending written
permission. Original Kumo MIT notices are retained in LICENSE. Bundled Inter
fonts retain the SIL Open Font License under assets/fonts/OFL.txt.

Not published to pub.dev.
