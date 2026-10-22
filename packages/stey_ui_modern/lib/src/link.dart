import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

import 'badge_link_scope.dart';
import 'theme.dart';

enum SteyLinkVariant { inline, current, plain }

/// Routing belongs to the application. The provider receives the destination
/// and optional browser target without adding a platform or URL-launcher dependency.
class SteyLinkProvider extends InheritedWidget {
  const SteyLinkProvider({
    super.key,
    required this.onNavigate,
    required super.child,
  });
  final void Function(Uri href, String? target) onNavigate;
  static SteyLinkProvider? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SteyLinkProvider>();
  @override
  bool updateShouldNotify(SteyLinkProvider oldWidget) =>
      onNavigate != oldWidget.onNavigate;
}

/// Intrinsic native link. Enter activates; Space keeps the surrounding scroll
/// behavior. No visited state is invented: Kumo has no visited color override.
class SteyLink extends StatefulWidget {
  const SteyLink({
    super.key,
    required this.child,
    this.onPressed,
    this.href,
    this.target,
    this.external = false,
    this.disabled = false,
    this.variant = SteyLinkVariant.inline,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final Uri? href;
  final String? target;

  /// Appends [SteyLinkExternalIcon]. Does not select a navigation target.
  final bool external, disabled, autofocus;
  final SteyLinkVariant variant;
  final FocusNode? focusNode;
  final String? semanticLabel;
  @override
  State<SteyLink> createState() => _SteyLinkState();
}

class _SteyLinkState extends State<SteyLink> {
  final ownedFocus = FocusNode();
  bool hovered = false, highlight = false;
  FocusNode get focus => widget.focusNode ?? ownedFocus;
  @override
  void dispose() {
    ownedFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final provider = SteyLinkProvider.maybeOf(context);
    final enabled =
        !widget.disabled &&
        (widget.onPressed != null || widget.href != null && provider != null);
    final inherited = DefaultTextStyle.of(context).style;
    final color = widget.variant == SteyLinkVariant.current
        ? inherited.color ?? c.text
        : c.link;
    final plain = widget.variant == SteyLinkVariant.plain;
    final foreground = plain && hovered
        ? color.withValues(alpha: color.a * .7)
        : color;
    final dark = SteyTheme.colorsOf(context).brightness == Brightness.dark;
    void activate() {
      if (!enabled) return;
      focus.requestFocus();
      if (widget.onPressed != null) {
        widget.onPressed!();
      } else {
        provider!.onNavigate(widget.href!, widget.target);
      }
    }

    return SteyBadgeLinkScope(
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: focus,
        autofocus: widget.autofocus,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          // Space scrolls instead of falling back to Material's ActivateIntent.
          SingleActivator(LogicalKeyboardKey.space): ScrollIntent(
            direction: AxisDirection.down,
            type: ScrollIncrementType.page,
          ),
          SingleActivator(LogicalKeyboardKey.space, shift: true): ScrollIntent(
            direction: AxisDirection.up,
            type: ScrollIncrementType.page,
          ),
        },
        actions: {
          ScrollIntent: CallbackAction<ScrollIntent>(
            onInvoke: (intent) {
              final action = ScrollAction();
              if (action.isEnabled(intent, context)) {
                action.invoke(intent, context);
              }
              return null;
            },
          ),
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              activate();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => highlight = value),
        child: _LinkMinContent(
          preserveWordWidth: widget.child is Text || widget.child is RichText,
          child: MergeSemantics(
            child: Semantics(
              container: true,
              link: true,
              enabled: enabled,
              label: widget.semanticLabel,
              excludeSemantics: widget.semanticLabel != null,
              linkUrl: !enabled || widget.href == null
                  ? null
                  : kIsWeb
                  ? Uri.base.resolveUri(widget.href!)
                  : widget.href,
              onTap: enabled ? activate : null,
              child: MouseRegion(
                cursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                onEnter: (_) => setState(() => hovered = true),
                onExit: (_) => setState(() => hovered = false),
                child: GestureDetector(
                  excludeFromSemantics: true,
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled ? activate : null,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: highlight && enabled
                          ? Border.all(
                              color: c.focus,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            )
                          : null,
                    ),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: foreground,
                        decoration: plain
                            ? TextDecoration.none
                            : TextDecoration.underline,
                        decorationColor: hovered
                            ? color
                            : color.withValues(
                                alpha: color.a * (dark ? .65 : .35),
                              ),
                      ),
                      child: IconTheme.merge(
                        data: IconThemeData(color: foreground),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing:
                              MediaQuery.textScalerOf(context)
                                  .scale(inherited.fontSize ?? 14) *
                              .1875,
                          children: [
                            Flexible(child: widget.child),
                            if (widget.external) const SteyLinkExternalIcon(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// CSS flex items retain their min-content width. In particular, a long word
// and the external icon may overflow a narrow host instead of splitting a word.
class _LinkMinContent extends SingleChildRenderObjectWidget {
  const _LinkMinContent({
    required this.preserveWordWidth,
    required super.child,
  });
  final bool preserveWordWidth;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _LinkMinContentBox(preserveWordWidth);
  @override
  void updateRenderObject(
    BuildContext context,
    _LinkMinContentBox renderObject,
  ) {
    renderObject.preserveWordWidth = preserveWordWidth;
  }
}

class _LinkMinContentBox extends RenderProxyBox {
  _LinkMinContentBox(this._preserveWordWidth);
  bool _preserveWordWidth;
  set preserveWordWidth(bool value) {
    if (_preserveWordWidth == value) return;
    _preserveWordWidth = value;
    markNeedsLayout();
  }

  BoxConstraints childConstraints(BoxConstraints outer) {
    // LayoutBuilder and lazy/custom widget children may not support intrinsic
    // measurement. Keep their native layout contract instead of querying it.
    if (!_preserveWordWidth) return outer;
    final minimum = child!.getMinIntrinsicWidth(double.infinity);
    return outer.copyWith(
      minWidth: 0,
      maxWidth: outer.maxWidth < minimum ? minimum : outer.maxWidth,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(child!.getDryLayout(childConstraints(constraints)));
  @override
  void performLayout() {
    child!.layout(childConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(child!.size);
  }
}

/// Kumo's decorative 24-unit external-link geometry (MIT Cloudflare).
class SteyLinkExternalIcon extends StatelessWidget {
  const SteyLinkExternalIcon({super.key});
  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final size = MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14);
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _ExternalPainter(
          style.color ?? SteyTheme.colorsOf(context).link,
          SteyTheme.colorsOf(context).brightness == Brightness.dark ? 2 : 1.75,
        ),
      ),
    );
  }
}

class _ExternalPainter extends CustomPainter {
  const _ExternalPainter(this.color, this.stroke);
  final Color color;
  final double stroke;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final outline = Path()
      ..moveTo(9, 4)
      ..lineTo(8.8, 4)
      ..cubicTo(7.11984, 4, 6.27976, 4, 5.63803, 4.32698)
      ..cubicTo(5.07354, 4.6146, 4.6146, 5.07354, 4.32698, 5.63803)
      ..cubicTo(4, 6.27976, 4, 7.11984, 4, 8.8)
      ..lineTo(4, 15.2)
      ..cubicTo(4, 16.8802, 4, 17.7202, 4.32698, 18.362)
      ..cubicTo(4.6146, 18.9265, 5.07354, 19.3854, 5.63803, 19.673)
      ..cubicTo(6.27976, 20, 7.11984, 20, 8.8, 20)
      ..lineTo(15.2, 20)
      ..cubicTo(16.8802, 20, 17.7202, 20, 18.362, 19.673)
      ..cubicTo(18.9265, 19.3854, 19.3854, 18.9265, 19.673, 18.362)
      ..cubicTo(20, 17.7202, 20, 16.8802, 20, 15.2)
      ..lineTo(20, 15)
      ..moveTo(14, 4)
      ..lineTo(20, 4)
      ..lineTo(20, 10)
      ..moveTo(20, 4)
      ..lineTo(11, 13);
    canvas.drawPath(
      outline,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ExternalPainter oldDelegate) =>
      color != oldDelegate.color || stroke != oldDelegate.stroke;
}
