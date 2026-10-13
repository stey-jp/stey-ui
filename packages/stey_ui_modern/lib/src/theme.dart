import 'package:flutter/material.dart';

import 'tokens.g.dart';

export 'tokens.g.dart';

/// Colors originate in Kumo's semantic tokens, converted from OKLCH to sRGB.
class SteyTheme extends InheritedWidget {
  const SteyTheme({super.key, required this.brightness, required super.child});
  final Brightness brightness;
  static SteyColors colorsOf(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<SteyTheme>();
    return SteyColors(theme?.brightness ?? Theme.of(context).brightness);
  }

  static ThemeData material(Brightness brightness) {
    final c = SteyColors(brightness);
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: 'Inter',
      package: 'stey_ui_modern',
      scaffoldBackgroundColor: c.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.brand,
        brightness: brightness,
        surface: c.base,
        onSurface: c.text,
        primary: c.brand,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme
          .apply(bodyColor: c.text, displayColor: c.text)
          .copyWith(
            bodyMedium: TextStyle(
              fontFamily: 'Inter',
              package: 'stey_ui_modern',
              fontSize: 14,
              height: 1.5,
              color: c.text,
            ),
            bodyLarge: TextStyle(
              fontFamily: 'Inter',
              package: 'stey_ui_modern',
              fontSize: 14,
              height: 1.5,
              color: c.text,
            ),
          ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: c.line,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.contrast,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(color: c.inverse, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  bool updateShouldNotify(SteyTheme oldWidget) =>
      brightness != oldWidget.brightness;
}

enum SteySize {
  xs(20, 6, 2, 12),
  sm(26, 8, 6, 12),
  base(36, 12, 8, 14),
  lg(40, 16, 8, 14);

  const SteySize(this.height, this.padding, this.radius, this.fontSize);
  final double height, padding, radius, fontSize;
}

enum SteyTone { neutral, info, success, warning, danger }

extension SteyToneColors on SteyTone {
  Color foreground(SteyColors c) => switch (this) {
    SteyTone.neutral => c.text,
    SteyTone.info => c.link,
    SteyTone.success => c.successText,
    SteyTone.warning => c.warningText,
    SteyTone.danger => c.dangerText,
  };
  Color background(SteyColors c) => switch (this) {
    SteyTone.neutral => c.fill,
    SteyTone.info => c.infoTint,
    SteyTone.success => c.successTint,
    SteyTone.warning => c.warningTint,
    SteyTone.danger => c.dangerTint,
  };
}
