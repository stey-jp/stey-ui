import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'gallery.dart';

late final SemanticsHandle semanticsHandle;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  semanticsHandle = SemanticsBinding.instance.ensureSemantics();
  runApp(const SteyGallery());
}
