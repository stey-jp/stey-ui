import 'package:flutter/widgets.dart';

/// Mirrors the CSS ancestor-link hover selector for native badges. SteyLink
/// and SteyBreadcrumbsLink include this scope; custom links can opt in too.
/// It adds neither semantics nor a keyboard focus stop.
class SteyBadgeLinkScope extends StatefulWidget {
  const SteyBadgeLinkScope({super.key, required this.child});
  final Widget child;
  static bool hoveredOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LinkHover>()?.hovered ??
      false;
  @override
  State<SteyBadgeLinkScope> createState() => _BadgeLinkScopeState();
}

class _BadgeLinkScopeState extends State<SteyBadgeLinkScope> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: _LinkHover(
      hovered: hovered || SteyBadgeLinkScope.hoveredOf(context),
      child: widget.child,
    ),
  );
}

class _LinkHover extends InheritedWidget {
  const _LinkHover({required this.hovered, required super.child});
  final bool hovered;
  @override
  bool updateShouldNotify(_LinkHover oldWidget) => hovered != oldWidget.hovered;
}
