import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'gallery.dart';
import 'native_navigation.dart'
    if (dart.library.js_interop) 'web_navigation.dart';

late final SemanticsHandle semanticsHandle;
void main() {
  configureNavigation();
  WidgetsFlutterBinding.ensureInitialized();
  semanticsHandle = SemanticsBinding.instance.ensureSemantics();
  runApp(const SteyGallery());
}
