import 'dart:js_interop';

import 'package:flutter/foundation.dart';

@JS('globalThis.location.hash')
external String get _hash;
@JS('globalThis.addEventListener')
external void _addEventListener(String type, JSFunction listener);
@JS('globalThis.removeEventListener')
external void _removeEventListener(String type, JSFunction listener);

String readFragment() => _hash;

VoidCallback listenToFragment(ValueChanged<String> onChanged) {
  final listener = ((JSAny? _) => onChanged(_hash)).toJS;
  _addEventListener('hashchange', listener);
  return () {
    _removeEventListener('hashchange', listener);
  };
}
