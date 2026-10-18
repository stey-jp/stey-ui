import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'button.dart';
import 'theme.dart';

enum SteyBannerVariant { defaultValue, alert, error, secondary }

enum SteyBannerSize { base, sm }

enum SteyBannerActionVariant { primary, secondary, ghost }

/// A native message bar. Structured content takes precedence over legacy child.
class SteyBanner extends StatelessWidget {
  const SteyBanner({
    super.key,
    this.title,
    this.description,
    this.icon,
    this.variant,
    this.size = SteyBannerSize.base,
    this.action,
    this.child,
    this.text,
    this.tone,
    this.onDismiss,
    this.dismissLabel,
    this.liveRegion = false,
  });
  final String? title, text, dismissLabel;
  final Widget? description, icon, action, child;
  final SteyBannerVariant? variant;
  final SteyBannerSize size;
  final SteyTone? tone;
  final VoidCallback? onDismiss;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final compact = size == SteyBannerSize.sm;
    final selected =
        variant ??
        switch (tone) {
          SteyTone.warning => SteyBannerVariant.alert,
          SteyTone.danger => SteyBannerVariant.error,
          SteyTone.neutral => SteyBannerVariant.secondary,
          _ => SteyBannerVariant.defaultValue,
        };
    final legacySuccess = variant == null && tone == SteyTone.success;
    final background = legacySuccess
        ? c.successTint
        : switch (selected) {
            SteyBannerVariant.defaultValue => c.infoTint,
            SteyBannerVariant.alert => c.warningTint,
            SteyBannerVariant.error => c.dangerTint,
            SteyBannerVariant.secondary => c.contrast.withValues(alpha: .05),
          };
    final foreground = legacySuccess
        ? c.successText
        : switch (selected) {
            SteyBannerVariant.defaultValue => c.link,
            SteyBannerVariant.alert => c.warningText,
            SteyBannerVariant.error => c.dangerText,
            SteyBannerVariant.secondary => c.text.withValues(alpha: .7),
          };
    final iconColor = legacySuccess
        ? c.success
        : switch (selected) {
            SteyBannerVariant.defaultValue => c.info,
            SteyBannerVariant.alert => c.warning,
            SteyBannerVariant.error => c.danger,
            SteyBannerVariant.secondary => c.interact,
          };
    final bannerIcon =
        icon ??
        (tone == null
            ? null
            : Icon(switch (tone!) {
                SteyTone.danger => Icons.error_outline,
                SteyTone.warning => Icons.warning_amber,
                SteyTone.success => Icons.check_circle_outline,
                _ => Icons.info_outline,
              }, size: 18));
    final structured = (title?.isNotEmpty ?? false) || description != null;
    final gap = compact ? 8.0 : 12.0;
    final font = compact ? 13.0 : 14.0;
    final hasTitle = title?.isNotEmpty ?? false;
    final linkAction = action is SteyLink
        ? _BannerInlineLink(action! as SteyLink)
        : null;
    final inlineLink = compact ? linkAction : null;
    Widget? titleWidget = hasTitle
        ? Text(
            title!,
            style: const TextStyle(fontWeight: FontWeight.w500, height: 1.375),
          )
        : null;
    Widget? descriptionWidget = description == null
        ? null
        : DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 13, height: 1.375),
            child: description!,
          );
    if (inlineLink != null) {
      final source = description ?? titleWidget;
      Widget append(Widget? value) {
        if (value is Text) {
          return Text.rich(
            TextSpan(
              style: value.style,
              children: [
                value.textSpan ?? TextSpan(text: value.data),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 6),
                    child: DefaultTextStyle.merge(
                      style: (value.style ?? const TextStyle()).copyWith(
                        height: 1.375,
                      ),
                      child: inlineLink,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [?value, inlineLink],
        );
      }

      if (description != null) {
        descriptionWidget = DefaultTextStyle.merge(
          style: const TextStyle(fontSize: 13, height: 1.375),
          child: append(source),
        );
      } else {
        titleWidget = append(source);
      }
    }
    final dismiss = onDismiss == null
        ? null
        : SteyBannerAction(
            variant: SteyBannerActionVariant.ghost,
            icon: const Icon(Icons.close),
            semanticLabel:
                dismissLabel ??
                (Localizations.maybeLocaleOf(context)?.languageCode == 'ja'
                    ? '通知を閉じる'
                    : 'Dismiss notification'),
            onPressed: onDismiss,
          );
    final trailing = [
      if (inlineLink == null && structured && action != null)
        linkAction ?? action!,
      ?dismiss,
    ];
    Widget content;
    if (structured) {
      content = Padding(
        padding: EdgeInsets.only(top: hasTitle ? 0 : 1),
        child: Row(
          spacing: gap,
          children: [
            Expanded(
              child: compact
                  ? Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [?titleWidget, ?descriptionWidget],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [?titleWidget, ?descriptionWidget],
                    ),
            ),
            if (trailing.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: trailing,
              ),
          ],
        ),
      );
    } else {
      content = Row(
        spacing: gap,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child ?? Text(text ?? '')),
          ?dismiss,
        ],
      );
    }
    return _BannerScope(
      variant: selected,
      size: size,
      foreground: foreground,
      child: Semantics(
        explicitChildNodes: true,
        liveRegion: liveRegion,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(compact ? 6 : 8),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 8 : 12,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(fontSize: font, height: 1.5, color: foreground),
              child: Row(
                spacing: gap,
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  if (bannerIcon != null)
                    ExcludeSemantics(
                      child: IconTheme.merge(
                        data: IconThemeData(size: font, color: iconColor),
                        child: structured
                            ? SizedBox(
                                height: font * (compact ? 1.25 : 1.375),
                                child: Center(child: bannerIcon),
                              )
                            : bannerIcon,
                      ),
                    ),
                  Expanded(child: content),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerScope extends InheritedWidget {
  const _BannerScope({
    required this.variant,
    required this.size,
    required this.foreground,
    required super.child,
  });
  final SteyBannerVariant variant;
  final SteyBannerSize size;
  final Color foreground;
  @override
  bool updateShouldNotify(_BannerScope oldWidget) =>
      variant != oldWidget.variant ||
      size != oldWidget.size ||
      foreground != oldWidget.foreground;
}

/// Banner.Action: inherits the nearest banner's color and sm/xs button size.
class SteyBannerAction extends StatelessWidget {
  const SteyBannerAction({
    super.key,
    this.child = const SizedBox.shrink(),
    this.onPressed,
    this.variant = SteyBannerActionVariant.primary,
    this.icon,
    this.trailing,
    this.loading = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.shape = SteyButtonShape.base,
  });
  final Widget child;
  final Widget? icon, trailing;
  final VoidCallback? onPressed;
  final SteyBannerActionVariant variant;
  final bool loading, autofocus;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final SteyButtonShape shape;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final banner = context.dependOnInheritedWidgetOfExactType<_BannerScope>();
    final tone = banner?.variant ?? SteyBannerVariant.defaultValue;
    final (accent, start, highlight, ring) = switch (tone) {
      SteyBannerVariant.defaultValue => (
        c.info,
        c.infoEmphasisStart,
        c.infoEmphasisHover,
        c.infoEmphasisRing,
      ),
      SteyBannerVariant.alert => (
        c.warning,
        c.warningEmphasisStart,
        c.warningEmphasisHover,
        c.warningEmphasisRing,
      ),
      SteyBannerVariant.error => (
        c.danger,
        c.dangerEmphasisStart,
        c.dangerEmphasisHover,
        c.dangerEmphasisRing,
      ),
      SteyBannerVariant.secondary => (
        c.bannerNeutral,
        c.bannerNeutralEmphasisStart,
        c.bannerNeutralEmphasisHover,
        c.bannerNeutralEmphasisRing,
      ),
    };
    final primary = variant == SteyBannerActionVariant.primary;
    final foreground = banner?.foreground ?? c.link;
    final neutral = tone == SteyBannerVariant.secondary;
    final size = banner?.size == SteyBannerSize.sm ? SteySize.xs : SteySize.sm;
    return _BannerActionKeys(
      onPressed: loading ? null : onPressed,
      child: SteyButton(
        onPressed: onPressed,
        icon: icon == null
            ? null
            : IconTheme.merge(
                data: IconThemeData(
                  color: primary
                      ? Colors.white
                      : neutral
                      ? c.subtle
                      : accent,
                ),
                child: icon!,
              ),
        trailing: trailing == null
            ? null
            : IconTheme.merge(
                data: IconThemeData(
                  color: primary
                      ? Colors.white
                      : neutral
                      ? c.subtle
                      : accent,
                ),
                child: trailing!,
              ),
        loading: loading,
        semanticLabel: semanticLabel,
        focusNode: focusNode,
        autofocus: autofocus,
        size: size,
        shape: shape,
        variant: switch (variant) {
          SteyBannerActionVariant.primary => SteyButtonVariant.primary,
          SteyBannerActionVariant.secondary => SteyButtonVariant.outline,
          SteyBannerActionVariant.ghost => SteyButtonVariant.ghost,
        },
        foregroundColor: primary ? Colors.white : foreground,
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(
            primary ? Colors.white : foreground,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => !primary && states.contains(WidgetState.hovered)
                ? (neutral ? c.contrast : accent).withValues(alpha: .1)
                : Colors.transparent,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: primary
                  ? ring
                  : states.contains(WidgetState.focused)
                  ? c.brand
                  : variant == SteyBannerActionVariant.secondary
                  ? (neutral
                        ? c.focus.withValues(alpha: .2)
                        : accent.withValues(alpha: .5))
                  : Colors.transparent,
              width: states.contains(WidgetState.focused) ? 2 : 1,
            ),
          ),
          backgroundBuilder: primary
              ? (context, states, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(
                    shape == SteyButtonShape.circle ? 100 : size.radius,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          states.contains(WidgetState.hovered)
                              ? highlight
                              : start,
                          accent,
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _BannerHighlight(highlight),
                      child: child,
                    ),
                  ),
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}

class _BannerActionKeys extends StatefulWidget {
  const _BannerActionKeys({required this.onPressed, required this.child});
  final VoidCallback? onPressed;
  final Widget child;
  @override
  State<_BannerActionKeys> createState() => _BannerActionKeysState();
}

class _BannerActionKeysState extends State<_BannerActionKeys> {
  bool spacePressed = false;
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    includeSemantics: false,
    onFocusChange: (focused) {
      if (!focused) spacePressed = false;
    },
    onKeyEvent: (_, event) {
      if (event.logicalKey != LogicalKeyboardKey.space) {
        return KeyEventResult.ignored;
      }
      if (event is KeyDownEvent) spacePressed = widget.onPressed != null;
      if (event is KeyUpEvent) {
        final invoke = spacePressed;
        spacePressed = false;
        if (invoke) widget.onPressed?.call();
      }
      return KeyEventResult.handled;
    },
    child: widget.child,
  );
}

class _BannerHighlight extends CustomPainter {
  const _BannerHighlight(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Rect.fromLTWH(0, 0, size.width, 1),
    Paint()..color = color,
  );
  @override
  bool shouldRepaint(_BannerHighlight oldDelegate) =>
      color != oldDelegate.color;
}

/// Keep a compact Kumo Link in the description's line box, without button padding.
class _BannerInlineLink extends StatefulWidget {
  const _BannerInlineLink(this.link);
  final SteyLink link;
  @override
  State<_BannerInlineLink> createState() => _BannerInlineLinkState();
}

class _BannerInlineLinkState extends State<_BannerInlineLink> {
  final focus = FocusNode();
  bool highlight = false;
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  void followLink() {
    focus.requestFocus();
    widget.link.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final enabled = widget.link.onPressed != null;
    return MergeSemantics(
      child: FocusableActionDetector(
        focusNode: focus,
        enabled: enabled,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space):
              DoNothingAndStopPropagationIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (enabled) followLink();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (v) => setState(() => highlight = v),
        child: Semantics(
          link: true,
          linkUrl: !enabled || widget.link.href == null
              ? null
              : kIsWeb && widget.link.href!.toString().startsWith('#')
              ? Uri.base.resolveUri(widget.link.href!)
              : widget.link.href,
          enabled: enabled,
          onTap: enabled ? followLink : null,
          child: MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              excludeFromSemantics: true,
              onTap: enabled ? followLink : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: highlight
                      ? Border.all(
                          color: c.brand,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        )
                      : null,
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: c.link,
                    decoration: TextDecoration.underline,
                    decorationColor: c.link,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 3,
                    children: [
                      widget.link.child,
                      if (widget.link.external)
                        const Icon(Icons.open_in_new, size: 12),
                    ],
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
