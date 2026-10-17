import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/diff.dart';
import 'package:re_highlight/languages/graphql.dart';
import 'package:re_highlight/languages/ini.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/shell.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';

import 'button.dart';
import 'theme.dart';

/// Kumo's bundled language identifiers and exact, case-sensitive aliases.
const steyCodeLanguages = <String>[
  'javascript',
  'typescript',
  'jsx',
  'tsx',
  'json',
  'jsonc',
  'html',
  'css',
  'python',
  'yaml',
  'markdown',
  'graphql',
  'sql',
  'bash',
  'shell',
  'diff',
  'hcl',
  'toml',
];
const _aliases = <String, String>{
  'js': 'javascript',
  'cjs': 'javascript',
  'mjs': 'javascript',
  'ts': 'typescript',
  'cts': 'typescript',
  'mts': 'typescript',
  'sh': 'bash',
  'zsh': 'bash',
  'yml': 'yaml',
  'py': 'python',
  'md': 'markdown',
  'gql': 'graphql',
};
String? normalizeSteyCodeLanguage(String lang) =>
    steyCodeLanguages.contains(lang) ? lang : _aliases[lang];

/// Synchronous, native Dart highlighting. Grammars compile on first use.
///
/// The parser is highlight.js-based, rather than Shiki's TextMate engine.
/// Token boundaries and classifications can differ; this is not Shiki parity.
class SteyCodeHighlighter {
  SteyCodeHighlighter({Iterable<String> languages = steyCodeLanguages})
    : languages = Set.unmodifiable(
        languages.map(normalizeSteyCodeLanguage).nonNulls,
      );
  final Set<String> languages;
  final _engine = Highlight();
  final _registered = <String>{};
  static final standard = SteyCodeHighlighter();

  void _register(String name, Mode mode) {
    if (_registered.add(name)) _engine.registerLanguage(name, mode);
  }

  TextSpan? highlight(String code, String lang, {required bool dark}) {
    final canonical = normalizeSteyCodeLanguage(lang);
    if (canonical == null || !languages.contains(canonical)) return null;
    try {
      // XML and script/style grammars are dependencies of JSX and tagged text.
      _register('xml', langXml);
      _register('javascript', langJavascript);
      _register('css', langCss);
      if (canonical == 'shell') _register('bash', langBash);
      final grammar = switch (canonical) {
        'javascript' || 'jsx' => langJavascript,
        'typescript' || 'tsx' => langTypescript,
        'json' || 'jsonc' => langJson,
        'html' => langXml,
        'css' => langCss,
        'python' => langPython,
        'yaml' => langYaml,
        'markdown' => langMarkdown,
        'graphql' => langGraphql,
        'sql' => langSql,
        'bash' => langBash,
        'shell' => langShell,
        'diff' => langDiff,
        'toml' => langIni,
        _ => _hcl,
      };
      _register(canonical, grammar);
      final result = _engine.highlight(
        code: code,
        language: canonical,
        ignoreIllegals: true,
      );
      if (result.errorRaised != null) return null;
      final renderer = TextSpanRenderer(null, _codeTheme(dark));
      result.render(renderer);
      return renderer.span;
    } catch (_) {
      // Unavailable/failed highlighting must never hide source text.
      return null;
    }
  }
}

// HCL is not bundled by re_highlight. This small native grammar handles common
// blocks/attributes/comments/values; heredoc and full interpolation remain open.
final _hcl = Mode(
  name: 'HCL',
  keywords: {
    'keyword': 'resource data variable output locals module provider terraform dynamic for in if',
    'literal': 'true false null',
  },
  contains: [
    HASH_COMMENT_MODE,
    C_LINE_COMMENT_MODE,
    C_BLOCK_COMMENT_MODE,
    QUOTE_STRING_MODE,
    C_NUMBER_MODE,
    Mode(scope: 'attr', begin: r'[A-Za-z_][\w-]*(?=\s*=)'),
  ],
);

Map<String, TextStyle> _codeTheme(bool dark) {
  // Semantic equivalents of github-light and vesper, not TextMate scopes.
  final keyword = Color(dark ? 0xffa0a0a0 : 0xffd73a49);
  final string = Color(dark ? 0xff99ffe4 : 0xff032f62);
  final number = Color(dark ? 0xffffc799 : 0xff005cc5);
  final function = Color(dark ? 0xffffc799 : 0xff6f42c1);
  final comment = Color(dark ? 0x948b8b8b : 0xff6a737d);
  return {
    'keyword': TextStyle(color: keyword),
    'operator': TextStyle(color: keyword),
    'string': TextStyle(color: string),
    'regexp': TextStyle(color: string),
    'number': TextStyle(color: number),
    'literal': TextStyle(color: number),
    'built_in': TextStyle(color: number),
    'symbol': TextStyle(color: number),
    'type': TextStyle(color: number),
    'variable': TextStyle(color: number),
    'attr': TextStyle(color: number),
    'attribute': TextStyle(color: function),
    'title': TextStyle(color: function),
    'title.function': TextStyle(color: function),
    'title.class': TextStyle(color: function),
    'selector-tag': TextStyle(color: function),
    'selector-class': TextStyle(color: function),
    'selector-id': TextStyle(color: function),
    'tag': TextStyle(color: keyword),
    'name': TextStyle(color: dark ? number : const Color(0xff22863a)),
    'comment': TextStyle(color: comment),
    'doctag': TextStyle(color: comment),
    'meta': TextStyle(color: keyword),
    'section': TextStyle(color: function),
    'bullet': TextStyle(color: number),
    'link': TextStyle(color: string, decoration: TextDecoration.underline),
    'strong': const TextStyle(fontWeight: FontWeight.w600),
    'emphasis': const TextStyle(fontStyle: FontStyle.italic),
    'addition': const TextStyle(color: Color(0xff22863a)),
    'deletion': const TextStyle(color: Color(0xffb31d28)),
    'subst': TextStyle(color: dark ? Colors.white : const Color(0xff24292e)),
  };
}

/// Optional shared language configuration and copy labels.
/// A null highlighter renders plain text, including while an owner loads one.
class SteyCodeHighlighting extends InheritedWidget {
  const SteyCodeHighlighting({
    super.key,
    required super.child,
    required this.highlighter,
    this.copyLabel,
    this.copiedLabel,
  });
  final SteyCodeHighlighter? highlighter;
  final String? copyLabel, copiedLabel;
  static SteyCodeHighlighting? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SteyCodeHighlighting>();
  @override
  bool updateShouldNotify(SteyCodeHighlighting oldWidget) =>
      highlighter != oldWidget.highlighter ||
      copyLabel != oldWidget.copyLabel ||
      copiedLabel != oldWidget.copiedLabel;
}

enum SteyCodeHighlightedVariant { standard, plain }

/// Selectable, native syntax-highlighted code with fixed line numbers and
/// horizontal scrolling. Copy always uses the original, unmodified source.
class SteyCodeHighlighted extends StatefulWidget {
  const SteyCodeHighlighted(
    this.code, {
    super.key,
    required this.lang,
    this.variant = SteyCodeHighlightedVariant.standard,
    this.showLineNumbers = false,
    this.highlightLines = const [],
    this.showCopyButton = false,
    this.copyLabel,
    this.copiedLabel,
    this.onCopyError,
  });
  final String code, lang;
  final SteyCodeHighlightedVariant variant;
  final bool showLineNumbers, showCopyButton;
  final List<int> highlightLines;
  final String? copyLabel, copiedLabel;
  final ValueChanged<Object>? onCopyError;
  @override
  State<SteyCodeHighlighted> createState() => _CodeHighlightedState();
}

class _CodeHighlightedState extends State<SteyCodeHighlighted>
    with SingleTickerProviderStateMixin {
  final scroll = ScrollController();
  late final visibility = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    animationBehavior: AnimationBehavior.preserve,
  );
  bool lastVisible = false;
  Timer? reset;
  int attempt = 0;
  bool copied = false, hovered = false, focused = false;
  SteyCodeHighlighter? cachedHighlighter;
  String? cachedCode, cachedLang;
  bool? cachedDark;
  TextSpan? highlighted;

  Future<void> copy() async {
    final current = ++attempt;
    reset?.cancel();
    try {
      await Clipboard.setData(ClipboardData(text: widget.code));
      if (!mounted || current != attempt) return;
      setState(() => copied = true);
      reset = Timer(const Duration(seconds: 2), () {
        if (mounted && current == attempt) setState(() => copied = false);
      });
    } catch (error) {
      if (!mounted || current != attempt) return;
      setState(() => copied = false);
      widget.onCopyError?.call(error);
    }
  }

  @override
  void dispose() {
    attempt++;
    reset?.cancel();
    visibility.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SteyTheme.colorsOf(context);
    final dark =
        (context.dependOnInheritedWidgetOfExactType<SteyTheme>()?.brightness ??
            Theme.of(context).brightness) ==
        Brightness.dark;
    final scope = SteyCodeHighlighting.maybeOf(context);
    final highlighter = scope == null
        ? SteyCodeHighlighter.standard
        : scope.highlighter;
    if (cachedCode != widget.code ||
        cachedLang != widget.lang ||
        cachedDark != dark ||
        cachedHighlighter != highlighter) {
      highlighted = highlighter?.highlight(
        widget.code,
        widget.lang,
        dark: dark,
      );
      cachedCode = widget.code;
      cachedLang = widget.lang;
      cachedDark = dark;
      cachedHighlighter = highlighter;
    }
    final lines = widget.code.split('\n').length;
    final plain = widget.variant == SteyCodeHighlightedVariant.plain;
    final padding = plain ? 0.0 : 16.0;
    final scale = MediaQuery.textScalerOf(context);
    final scaledLine = scale.scale(13) * 1.625;
    final style = TextStyle(
      fontFamily: 'SteyCodeMono',
      package: 'stey_ui_modern',
      fontSize: 13,
      height: 1.625,
      color: highlighted == null
          ? colors.subtle
          : dark
          ? Colors.white
          : const Color(0xff24292e),
    );
    final span = TextSpan(
      style: style,
      children: [highlighted ?? TextSpan(text: widget.code)],
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: scale,
    )..layout();
    final textWidth = painter.width.ceilToDouble();
    painter.dispose();
    final numberPainter = TextPainter(
      text: TextSpan(text: '$lines', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scale,
    )..layout();
    final gutter = widget.showLineNumbers && lines > 1
        ? numberPainter.width + 28
        : 0.0;
    numberPainter.dispose();
    final label = copied
        ? widget.copiedLabel ?? scope?.copiedLabel ?? 'Copied!'
        : widget.copyLabel ?? scope?.copyLabel ?? 'Copy';
    final visible = hovered || focused || copied;
    if (visible != lastVisible) {
      lastVisible = visible;
      visibility.animateTo(visible ? 1 : 0, curve: const Cubic(.4, 0, .2, 1));
    }
    final button = widget.showCopyButton
        ? FadeTransition(
            opacity: visibility,
            alwaysIncludeSemantics: true,
            child: SteyButton(
              size: SteySize.sm,
              onPressed: copy,
              semanticLabel: label,
              child: Text(label),
            ),
          )
        : null;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Focus(
        canRequestFocus: false,
        includeSemantics: false,
        onFocusChange: (value) => setState(() => focused = value),
        child: Container(
          decoration: plain
              ? null
              : BoxDecoration(
                  color: colors.base,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.fill),
                ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : textWidth +
                        2 * padding +
                        gutter +
                        (button != null && lines == 1 ? 100 : 0);
              Widget viewport(double available) => SizedBox(
                width: math.max(0, available),
                child: SingleChildScrollView(
                  controller: scroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: math.max(textWidth + 2 * padding, available),
                    height: lines * scaledLine + 2 * padding,
                    child: CustomPaint(
                      painter: _CodeLines(
                        highlighted == null ? const [] : widget.highlightLines,
                        lines,
                        padding,
                        scaledLine,
                        dark
                            ? const Color(0x14ffffff)
                            : const Color(0x0d000000),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: SelectableText.rich(
                          span,
                          semanticsLabel: widget.code,
                          textDirection: TextDirection.ltr,
                          textScaler: scale,
                          strutStyle: const StrutStyle(
                            fontFamily: 'SteyCodeMono',
                            package: 'stey_ui_modern',
                            fontSize: 13,
                            height: 1.625,
                            forceStrutHeight: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              final content = Row(
                crossAxisAlignment: lines == 1
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  if (gutter > 0)
                    ExcludeSemantics(
                      child: SizedBox(
                        width: gutter,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 12,
                            right: 16,
                            top: padding,
                            bottom: padding,
                          ),
                          child: Opacity(
                            opacity: .4,
                            child: Text(
                              List.generate(
                                lines,
                                (i) => '${i + 1}',
                              ).join('\n'),
                              textAlign: TextAlign.right,
                              style: style.copyWith(color: colors.text),
                              textScaler: scale,
                              strutStyle: const StrutStyle(
                                fontFamily: 'SteyCodeMono',
                                package: 'stey_ui_modern',
                                fontSize: 13,
                                height: 1.625,
                                forceStrutHeight: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Flexible(
                    fit: button != null && lines == 1
                        ? FlexFit.loose
                        : FlexFit.tight,
                    child: LayoutBuilder(
                      builder: (_, inner) => viewport(
                        button != null && lines == 1
                            ? math.min(inner.maxWidth, textWidth + 2 * padding)
                            : inner.maxWidth,
                      ),
                    ),
                  ),
                  if (button != null && lines == 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: button,
                    ),
                ],
              );
              return SizedBox(
                width: width,
                child: Stack(
                  children: [
                    content,
                    if (button != null && lines > 1)
                      Positioned(
                        top: plain ? 0 : 8,
                        right: plain ? 0 : 8,
                        child: button,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CodeLines extends CustomPainter {
  const _CodeLines(
    this.lines,
    this.count,
    this.padding,
    this.height,
    this.color,
  );
  final List<int> lines;
  final int count;
  final double padding, height;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final line in lines.toSet()) {
      if (line >= 1 && line <= count) {
        canvas.drawRect(
          Rect.fromLTWH(0, padding + (line - 1) * height, size.width, height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CodeLines oldDelegate) =>
      lines != oldDelegate.lines ||
      count != oldDelegate.count ||
      padding != oldDelegate.padding ||
      height != oldDelegate.height ||
      color != oldDelegate.color;
}
