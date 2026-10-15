import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'dropdown.dart';
import 'messages.dart';
import 'theme.dart';

enum SteyLayerDialogSize {
  sm(448),
  base(576),
  lg(672),
  xl(768);

  const SteyLayerDialogSize(this.width);
  final double width;
}

enum SteyLayerDialogVerticalAlign { top, center }

enum SteyLayerDialogActionVariant { primary, destructive }

/// Controls pending work and programmatic closure independently of user
/// dismissal. A controller can belong to at most one open dialog at a time.
class SteyLayerDialogController<T> extends ChangeNotifier {
  SteyLayerDialogController({bool dismissDisabled = false})
    // Keep the public named argument independent of the private state field.
    // ignore: prefer_initializing_formals
    : _dismissDisabled = dismissDisabled;
  bool _dismissDisabled;
  ValueChanged<T?>? _close;
  bool get isOpen => _close != null;
  bool get dismissDisabled => _dismissDisabled;
  set dismissDisabled(bool value) {
    if (_dismissDisabled == value) return;
    _dismissDisabled = value;
    notifyListeners();
  }

  /// Programmatic closure remains available while user dismissal is disabled.
  void close([T? result]) => _close?.call(result);
}

class SteyLayerDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? description,
    required Widget child,
    SteyLayerDialogAction? action,
    String? dismissLabel,
    String? closeLabel,
    bool alert = false,
    bool dismissDisabled = false,
    SteyLayerDialogController<T>? controller,
    SteyLayerDialogSize size = SteyLayerDialogSize.base,
    SteyLayerDialogVerticalAlign verticalAlign =
        SteyLayerDialogVerticalAlign.center,
    double? width,
    // Retained for callers of the original show helper. New code should use
    // the single typed action, which also supplies the automatic dismiss.
    List<Widget> actions = const [],
  }) async {
    assert(action == null || actions.isEmpty);
    assert(!alert || action != null || actions.isNotEmpty);
    assert(width == null || width > 0);
    if (controller?.isOpen ?? false) {
      throw StateError('A LayerDialog controller already has an open dialog.');
    }
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = _LayerDialogRoute<T>(
      title: title,
      description: description,
      body: child,
      action: action,
      legacyActions: actions,
      dismissLabel: dismissLabel,
      closeLabel: closeLabel,
      alert: alert,
      dismissDisabled: dismissDisabled,
      dialogController: controller,
      width: width ?? size.width,
      verticalAlign: verticalAlign,
      desktop: MediaQuery.sizeOf(context).width >= 640,
      colors: SteyTheme.colorsOf(context),
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );
    final result = await navigator.push<T>(route);
    await route.completed;
    return result;
  }
}

/// The one primary or destructive action; related commands use a split menu.
class SteyLayerDialogAction extends StatelessWidget {
  const SteyLayerDialogAction({
    super.key,
    required this.child,
    this.onPressed,
    this.loading = false,
    this.variant = SteyLayerDialogActionVariant.primary,
    this.menu = const [],
    this.menuLabel,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final bool loading;
  final SteyLayerDialogActionVariant variant;
  final List<SteyMenuItem> menu;
  final String? menuLabel;

  @override
  Widget build(BuildContext context) {
    final buttonVariant = variant == SteyLayerDialogActionVariant.destructive
        ? SteyButtonVariant.destructive
        : SteyButtonVariant.primary;
    final button = SteyButton(
      onPressed: onPressed,
      loading: loading,
      variant: buttonVariant,
      child: child,
    );
    if (menu.isEmpty) return button;
    return SteyButtonGroup(
      semanticLabel: menuLabel ?? SteyMessages.of(context).moreActions,
      children: [
        button,
        SteyDropdownMenu(
          items: menu,
          label: menuLabel ?? SteyMessages.of(context).moreActions,
          triggerBuilder: (context, open, focus) => SteyButton(
            onPressed: open,
            focusNode: focus,
            variant: buttonVariant,
            shape: SteyButtonShape.square,
            semanticLabel: menuLabel ?? SteyMessages.of(context).moreActions,
            icon: const Icon(Icons.expand_more, size: 16),
            child: const SizedBox.shrink(),
          ),
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Native Dart counterpart of the deprecated LayerDialog.Actions.Primary alias.
@Deprecated('Use SteyLayerDialogAction instead.')
typedef SteyLayerDialogPrimary = SteyLayerDialogAction;

class SteyLayerDialogActions extends StatelessWidget {
  const SteyLayerDialogActions({
    super.key,
    required this.action,
    this.dismissLabel,
    this.dismissDisabled = false,
    this.alert = false,
    this.onDismiss,
  });
  final SteyLayerDialogAction action;
  final String? dismissLabel;
  final bool dismissDisabled, alert;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 640;
    final messages = SteyMessages.of(context);
    return Padding(
      padding: EdgeInsets.only(top: desktop ? 7 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SteyButton(
            onPressed: dismissDisabled
                ? null
                : onDismiss ?? () => Navigator.of(context).maybePop(),
            variant: desktop
                ? SteyButtonVariant.ghost
                : SteyButtonVariant.secondary,
            child: Text(
              dismissLabel ?? (alert ? messages.cancel : messages.close),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: action),
        ],
      ),
    );
  }
}

class _LayerDialogRoute<T> extends PopupRoute<T> {
  _LayerDialogRoute({
    required this.title,
    required this.description,
    required this.body,
    required this.action,
    required this.legacyActions,
    required this.dismissLabel,
    required this.closeLabel,
    required this.alert,
    required this.dismissDisabled,
    required this.dialogController,
    required this.width,
    required this.verticalAlign,
    required this.desktop,
    required this.colors,
    required this.themes,
    required this.barrierLabel,
  }) : super(
         requestFocus: true,
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
       );
  final String title;
  final String? description, dismissLabel, closeLabel;
  final Widget body;
  final SteyLayerDialogAction? action;
  final List<Widget> legacyActions;
  final bool alert, dismissDisabled, desktop;
  final SteyLayerDialogController<T>? dialogController;
  final double width;
  final SteyLayerDialogVerticalAlign verticalAlign;
  final SteyColors colors;
  final CapturedThemes themes;
  @override
  final String barrierLabel;
  bool get blocked =>
      dismissDisabled || (dialogController?.dismissDisabled ?? false);
  @override
  bool get barrierDismissible => !alert && !blocked;
  @override
  Color get barrierColor => colors.recessed.withValues(alpha: .8);
  @override
  Curve get barrierCurve => const Cubic(.32, .72, 0, 1);
  @override
  Duration get transitionDuration =>
      Duration(milliseconds: desktop ? 200 : 450);
  @override
  AnimationController createAnimationController() => AnimationController(
    duration: transitionDuration,
    reverseDuration: reverseTransitionDuration,
    vsync: navigator!,
    animationBehavior: AnimationBehavior.preserve,
  );

  void changed() => changedInternalState();
  void close(T? result) {
    if (isCurrent) navigator?.pop<T>(result);
  }

  void dismiss() {
    if (!blocked && isCurrent) navigator?.maybePop();
  }

  @override
  void install() {
    super.install();
    dialogController?._close = close;
    dialogController?.addListener(changed);
  }

  @override
  void dispose() {
    dialogController?.removeListener(changed);
    dialogController?._close = null;
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => themes.wrap(
    SteyTheme(
      brightness: colors.brightness,
      child: Material(
        type: MaterialType.transparency,
        child: _LayerDialogSurface(route: this),
      ),
    ),
  );
}

class _LayerDialogSurface extends StatefulWidget {
  const _LayerDialogSurface({required this.route});
  final _LayerDialogRoute<dynamic> route;
  @override
  State<_LayerDialogSurface> createState() => _LayerDialogSurfaceState();
}

class _LayerDialogSurfaceState extends State<_LayerDialogSurface>
    with SingleTickerProviderStateMixin {
  final scroll = ScrollController();
  final descriptionKey = GlobalKey();
  bool condensed = false;
  late final descriptionAnimation = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 200),
    animationBehavior: AnimationBehavior.preserve,
  );
  double drag = 0;
  _LayerDialogRoute<dynamic> get route => widget.route;

  @override
  void initState() {
    super.initState();
    scroll.addListener(onScroll);
  }

  void onScroll() {
    if (route.description == null || !scroll.hasClients) return;
    if (scroll.offset <= 8) {
      if (condensed) {
        setState(() => condensed = false);
        descriptionAnimation.animateTo(1, curve: Curves.easeOut);
      }
    } else if (!condensed) {
      final height = descriptionKey.currentContext?.size?.height ?? 0;
      if (scroll.position.maxScrollExtent - height > 16) {
        setState(() => condensed = true);
        descriptionAnimation.animateTo(0, curve: Curves.easeOut);
      }
    }
  }

  @override
  void dispose() {
    scroll.dispose();
    descriptionAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([route.dialogController]),
    builder: (context, _) {
      final c = SteyTheme.colorsOf(context);
      final viewport = MediaQuery.sizeOf(context);
      final desktop = viewport.width >= 640;
      final horizontal = desktop ? 18.0 : 16.0;
      final hasActions = route.action != null || route.legacyActions.isNotEmpty;
      final footer = route.action == null
          ? Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: route.legacyActions,
            )
          : SteyLayerDialogActions(
              action: route.action!,
              alert: route.alert,
              dismissDisabled: route.blocked,
              dismissLabel: route.dismissLabel,
              onDismiss: route.dismiss,
            );
      final insets = MediaQuery.viewInsetsOf(context);
      final available = math.max(0.0, viewport.height - insets.bottom);
      final maxHeight = desktop
          ? math.max(
              0.0,
              available -
                  (route.verticalAlign == SteyLayerDialogVerticalAlign.top
                      ? 88
                      : 48),
            )
          : math.min(viewport.height * .85, available);
      final surface = Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        role: route.alert ? SemanticsRole.alertDialog : SemanticsRole.dialog,
        label: route.title,
        hint: route.description,
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          identifier: 'stey-layer-dialog-content',
          child: Container(
            key: const ValueKey('stey-layer-dialog-surface'),
            width: desktop
                ? math.min(route.width, viewport.width - 32)
                : viewport.width,
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: c.elevated,
              borderRadius: BorderRadius.circular(desktop ? 12 : 0),
              border: desktop
                  ? null
                  : Border(top: BorderSide(color: c.hairline)),
              boxShadow: [
                BoxShadow(
                  color: desktop ? c.line : Colors.transparent,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: .03),
                  offset: const Offset(0, 20),
                  blurRadius: 25,
                  spreadRadius: -5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: .03),
                  offset: const Offset(0, 8),
                  blurRadius: 10,
                  spreadRadius: -6,
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!desktop && !route.alert)
                  ExcludeSemantics(
                    child: GestureDetector(
                      key: const ValueKey('stey-layer-dialog-handle'),
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: route.blocked
                          ? null
                          : (d) => setState(
                              () => drag = math.max(0, drag + d.delta.dy),
                            ),
                      onVerticalDragEnd: route.blocked
                          ? null
                          : (d) {
                              if (drag > 64 || (d.primaryVelocity ?? 0) > 700) {
                                route.dismiss();
                              }
                              setState(() => drag = 0);
                            },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: c.fill,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.base,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: c.fill, spreadRadius: 1)],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontal,
                            vertical: 16,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        route.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (route.description != null)
                                      ClipRect(
                                        child: SizeTransition(
                                          sizeFactor: descriptionAnimation,
                                          alignment:
                                              AlignmentDirectional.topStart,
                                          child: FadeTransition(
                                            opacity: descriptionAnimation,
                                            child: Padding(
                                              key: descriptionKey,
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                route.description!,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  height: 1.5,
                                                  color: c.subtle,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!hasActions) ...[
                                const SizedBox(width: 16),
                                Transform.translate(
                                  offset: const Offset(6, -6),
                                  child: SteyButton(
                                    size: SteySize.sm,
                                    shape: SteyButtonShape.square,
                                    variant: SteyButtonVariant.ghost,
                                    semanticLabel:
                                        route.closeLabel ??
                                        SteyMessages.of(context).close,
                                    onPressed: route.blocked
                                        ? null
                                        : route.dismiss,
                                    icon: const Icon(Icons.close, size: 15),
                                    child: const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Flexible(
                          child: Scrollbar(
                            controller: scroll,
                            child: SingleChildScrollView(
                              key: const ValueKey('stey-layer-dialog-scroll'),
                              controller: scroll,
                              padding: EdgeInsets.fromLTRB(
                                horizontal,
                                2,
                                horizontal,
                                horizontal,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: route.body,
                              ),
                            ),
                          ),
                        ),
                        if (!desktop && hasActions)
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: c.hairline),
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: footer,
                          ),
                      ],
                    ),
                  ),
                ),
                if (desktop && hasActions) footer,
              ],
            ),
          ),
        ),
      );
      return PopScope(
        canPop: !route.blocked,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): route.dismiss,
          },
          child: Focus(
            autofocus: true,
            skipTraversal: true,
            includeSemantics: false,
            child: AnimatedBuilder(
              animation: route.animation!,
              child: surface,
              builder: (context, child) {
                final progress = const Cubic(
                  .32,
                  .72,
                  0,
                  1,
                ).transform(route.animation!.value);
                return Padding(
                  padding: EdgeInsets.only(
                    left: desktop ? 16 : 0,
                    right: desktop ? 16 : 0,
                    top: desktop
                        ? (route.verticalAlign ==
                                  SteyLayerDialogVerticalAlign.top
                              ? 64
                              : 24)
                        : 0,
                    bottom: insets.bottom + (desktop ? 24 : 0),
                  ),
                  child: Align(
                    alignment: desktop
                        ? (route.verticalAlign ==
                                  SteyLayerDialogVerticalAlign.top
                              ? Alignment.topCenter
                              : Alignment.center)
                        : Alignment.bottomCenter,
                    child: Opacity(
                      opacity: desktop ? progress : 1,
                      child: desktop
                          ? Transform.translate(
                              offset: Offset(0, 8 * (1 - progress)),
                              child: child,
                            )
                          : FractionalTranslation(
                              translation: Offset(0, 1 - progress),
                              child: Transform.translate(
                                offset: Offset(0, drag),
                                child: child,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
