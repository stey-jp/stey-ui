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
  bool moved = false, expanded = false, inset = false;
  int clipped = 0;
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
    } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
      setState(() => inset = !inset);
    } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
      clipped = (clipped + 1) % 4;
      final height = MediaQuery.sizeOf(context).height;
      scroll.jumpTo(
        [0.0, height / 2, height / 2 + 50, height / 2 + 300][clipped],
      );
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
    builder: (context, box) {
      final query = Uri.base.queryParameters;
      final values = query['boundary']?.split(',').map(double.parse).toList();
      final boundary = values == null
          ? null
          : Rect.fromLTWH(values[0], values[1], values[2], values[3]);
      final pads = query['collisionPadding']
          ?.split(',')
          .map(double.parse)
          .toList();
      final padding = pads == null
          ? const EdgeInsets.all(5)
          : EdgeInsets.fromLTRB(pads[3], pads[0], pads[1], pads[2]);
      return SingleChildScrollView(
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
                  collisionBoundary: inset ? boundary?.deflate(40) : boundary,
                  collisionPadding: padding,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
