import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'theme.dart';
import 'toc_fragment_native.dart'
    if (dart.library.js_interop) 'toc_fragment_web.dart'
    as fragments;

/// Tracks mounted heading anchors in the insertion order of [sections].
///
/// The caller owns [scrollController] and the heading keys. Call [refresh]
/// after layout changes, or [updateSections] when the tracked anchors change.
/// Browser fragments are read automatically; native routers can call
/// [syncFromFragment]. Selecting a section does not write browser history.
class SteyTableOfContentsController extends ChangeNotifier {
  SteyTableOfContentsController({
    required this.scrollController,
    required Map<String, GlobalKey> sections,
    this.offset = 0,
    this.trackHash = true,
    this.scrollOnHashChange = true,
  }) : assert(offset >= 0),
       _sections = Map.of(sections) {
    scrollController.addListener(_onScroll);
    if (trackHash) {
      _stopListening = fragments.listenToFragment(syncFromFragment);
      syncFromFragment(fragments.readFragment());
    }
    refresh();
  }

  final ScrollController scrollController;
  final double offset;
  final bool trackHash;
  final bool scrollOnHashChange;
  Map<String, GlobalKey> _sections;
  String? _activeId, _pendingHashId;
  Timer? _settleTimer;
  VoidCallback? _stopListening;
  bool _pinned = false, _scheduled = false, _disposed = false;

  String? get activeId => _activeId;

  void _setActive(String id) {
    if (_activeId == id) return;
    _activeId = id;
    notifyListeners();
  }

  /// Pins the choice until scrolling has been quiet for 150 milliseconds.
  void selectSection(String id) {
    if (_disposed) return;
    _pendingHashId = null;
    _pinned = true;
    _armSettleTimer();
    _setActive(id);
  }

  void _armSettleTimer() {
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 150), () {
      _pinned = false;
    });
  }

  /// Decodes once, falling back to the raw fragment on malformed escapes.
  void syncFromFragment(String fragment) {
    if (_disposed || !trackHash) return;
    var id = fragment.startsWith('#') ? fragment.substring(1) : fragment;
    try {
      id = Uri.decodeComponent(id);
    } catch (_) {
      // Native Dart and Web/Wasm can expose different decoding exception
      // types (including JS URIError). Match Kumo's raw-fragment fallback.
    }
    if (id.isEmpty || !_sections.containsKey(id)) return;
    selectSection(id);
    if (scrollOnHashChange) {
      _pendingHashId = id;
      refresh();
    }
  }

  void updateSections(Map<String, GlobalKey> sections) {
    if (mapEquals(_sections, sections) &&
        listEquals(_sections.keys.toList(), sections.keys.toList())) {
      return;
    }
    _sections = Map.of(sections);
    if (trackHash) syncFromFragment(fragments.readFragment());
    refresh();
  }

  void _onScroll() {
    if (_pinned) _armSettleTimer();
    refresh();
  }

  /// Schedules one measurement after the current frame has laid out.
  void refresh() {
    if (_disposed || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_disposed || scrollController.positions.length != 1) return;
      final pending = _pendingHashId;
      if (pending != null && _target(pending) != null) {
        _pendingHashId = null;
        scrollToSection(pending, duration: Duration.zero);
      }
      if (_pinned) return;
      final position = scrollController.position;
      for (final entry in _sections.entries) {
        final target = _target(entry.key);
        if (target == null) continue;
        final viewport = RenderAbstractViewport.of(target);
        final rect = MatrixUtils.transformRect(
          target.getTransformTo(viewport),
          target.paintBounds,
        );
        final bounds = viewport.paintBounds;
        if (rect.bottom >= bounds.top + offset &&
            rect.top <= bounds.bottom &&
            rect.right >= bounds.left &&
            rect.left <= bounds.right &&
            position.axis == Axis.vertical) {
          _setActive(entry.key);
          return;
        }
      }
      // As in Kumo, gaps between headings retain the last active section.
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  RenderObject? _target(String id) {
    final context = _sections[id]?.currentContext;
    if (context == null || scrollController.positions.length != 1) return null;
    if (Scrollable.maybeOf(context)?.position != scrollController.position) {
      return null;
    }
    final target = context.findRenderObject();
    return target != null && target.attached ? target : null;
  }

  /// Scrolls inside the supplied root, accounting for fixed-header [offset].
  Future<void> scrollToSection(
    String id, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (_disposed) return;
    selectSection(id);
    final target = _target(id);
    if (target == null) return;
    final position = scrollController.position;
    final destination =
        (RenderAbstractViewport.of(target).getOffsetToReveal(target, 0).offset -
                offset)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (duration == Duration.zero) {
      scrollController.jumpTo(destination);
    } else {
      await scrollController.animateTo(
        destination,
        duration: duration,
        curve: curve,
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _settleTimer?.cancel();
    _stopListening?.call();
    scrollController.removeListener(_onScroll);
    super.dispose();
  }
}

/// A presentational navigation region. Supply [child] for compound content,
/// or use the existing [items]/[activeId]/[onSelected] convenience API.
class SteyTableOfContents extends StatelessWidget {
  const SteyTableOfContents({
    super.key,
    this.items = const {},
    this.activeId,
    this.onSelected,
    this.title = 'On this page',
    this.label = 'Table of contents',
    this.child,
  }) : assert(child == null || items.length == 0);

  final Map<String, String> items;
  final String? activeId;
  final ValueChanged<String>? onSelected;
  final String title, label;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    role: SemanticsRole.navigation,
    label: label,
    child:
        child ??
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SteyTableOfContentsTitle(title),
            SteyTableOfContentsList(
              children: [
                for (final entry in items.entries)
                  SteyTableOfContentsItem(
                    label: entry.value,
                    href: Uri(fragment: entry.key).toString(),
                    active: entry.key == activeId,
                    onPressed: onSelected == null
                        ? null
                        : () => onSelected!(entry.key),
                  ),
              ],
            ),
          ],
        ),
  );
}

class SteyTableOfContentsTitle extends StatelessWidget {
  const SteyTableOfContentsTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        height: 4 / 3,
        fontWeight: FontWeight.w600,
        letterSpacing: .3,
        color: SteyTheme.colorsOf(context).subtle,
      ),
    ),
  );
}

class SteyTableOfContentsList extends StatelessWidget {
  const SteyTableOfContentsList({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Semantics(
    role: SemanticsRole.list,
    explicitChildNodes: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(
            color: SteyTheme.colorsOf(context).hairline,
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: children,
      ),
    ),
  );
}

class _TocIndent extends InheritedWidget {
  const _TocIndent({required super.child});
  @override
  bool updateShouldNotify(_TocIndent oldWidget) => false;
}

class SteyTableOfContentsItem extends StatefulWidget {
  const SteyTableOfContentsItem({
    super.key,
    required this.label,
    this.href,
    this.active = false,
    this.onPressed,
    this.focusNode,
    this.child,
  }) : _listItem = true;
  const SteyTableOfContentsItem._groupLabel({
    required this.label,
    this.href,
    this.active = false,
    this.onPressed,
  }) : focusNode = null,
       child = null,
       _listItem = false;
  final String label;
  final String? href;
  final bool active;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final Widget? child;
  final bool _listItem;
  @override
  State<SteyTableOfContentsItem> createState() => _TocItemState();
}

class _TocItemState extends State<SteyTableOfContentsItem> {
  bool hovered = false, focused = false;
  @override
  Widget build(BuildContext context) {
    final c = SteyTheme.colorsOf(context);
    final nested =
        context.dependOnInheritedWidgetOfExactType<_TocIndent>() != null;
    final href = widget.href == null ? null : Uri.tryParse(widget.href!);
    final link = Semantics(
      container: true,
      link: true,
      // A bare '#id' would resolve against Flutter Web's <base href="/">
      // and discard the current route and query during anchor navigation.
      linkUrl: kIsWeb && href != null && widget.href!.startsWith('#')
          ? Uri.base.resolveUri(href)
          : href,
      selected: widget.active,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        enabled: widget.onPressed != null,
        onShowFocusHighlight: (value) => setState(() => focused = value),
        onShowHoverHighlight: (value) => setState(() => hovered = value),
        mouseCursor: widget.onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Container(
            padding: EdgeInsetsDirectional.only(
              start: nested ? 28 : 16,
              top: 2,
              bottom: 2,
            ),
            foregroundDecoration: focused
                ? BoxDecoration(border: Border.all(color: c.focus, width: 2))
                : null,
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(
                  width: 2,
                  color: widget.active
                      ? c.brand
                      : hovered
                      ? c.line
                      : Colors.transparent,
                ),
              ),
            ),
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 13,
                height: 20 / 13,
                fontWeight: widget.active || hovered
                    ? FontWeight.w500
                    : FontWeight.w400,
                color: widget.active || hovered ? c.text : c.subtle,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              child: widget.child ?? Text(widget.label),
            ),
          ),
        ),
      ),
    );
    return widget._listItem
        ? Semantics(
            container: true,
            explicitChildNodes: true,
            role: SemanticsRole.listItem,
            child: link,
          )
        : link;
  }
}

class SteyTableOfContentsGroup extends StatelessWidget {
  const SteyTableOfContentsGroup({
    super.key,
    required this.label,
    required this.children,
    this.href,
    this.active = false,
    this.onPressed,
  });
  final String label;
  final List<Widget> children;
  final String? href;
  final bool active;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    role: SemanticsRole.listItem,
    explicitChildNodes: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (href != null)
          SteyTableOfContentsItem._groupLabel(
            label: label,
            href: href,
            active: active,
            onPressed: onPressed,
          )
        else
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 16,
              top: 2,
              bottom: 2,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: SteyTheme.colorsOf(context).subtle,
                fontSize: 13,
                height: 20 / 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        _TocIndent(child: SteyTableOfContentsList(children: children)),
      ],
    ),
  );
}
