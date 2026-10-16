import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dropdown_example.dart';

/// Isolated comparison fixture. Keys change the application layout without
/// clicking outside (which should dismiss an open menu).
class DropdownTrackingSample extends StatefulWidget {
  const DropdownTrackingSample({super.key});
  @override
  State<DropdownTrackingSample> createState() => _TrackingState();
}

class _TrackingState extends State<DropdownTrackingSample> {
  final scroll = ScrollController();
  bool moved = false, expanded = false;
  KeyEventResult keyEvent(KeyEvent event) {
    if (event is! KeyDownEvent ||
        !HardwareKeyboard.instance.isControlPressed ||
        !HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyM) {
      setState(() => moved = !moved);
    } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
      scroll.animateTo(
        scroll.offset > 0 ? 0 : 120,
        duration: const Duration(milliseconds: 120),
        curve: Curves.linear,
      );
    } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
      setState(() => expanded = !expanded);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(keyEvent);
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(keyEvent);
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      controller: scroll,
      child: SizedBox(
        height: box.maxHeight * 2,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: box.maxHeight / 2 - 18),
            child: Transform.translate(
              offset: moved ? const Offset(20, -80) : Offset.zero,
              child: DropdownExample(
                fixture: true,
                extraItems: expanded ? 12 : 0,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
