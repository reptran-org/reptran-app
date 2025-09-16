import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInputRow extends StatefulWidget {
  final int length;
  final void Function(String) onChanged;
  final double size;
  final double gap;

  const OtpInputRow({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.size = 48,
    this.gap = 8,
  });

  @override
  State<OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<OtpInputRow> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    for (final fn in _focusNodes) {
      fn.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String val, int index) {
    // Move forward when typing
    if (val.isNotEmpty && index + 1 < widget.length) {
      _focusNodes[index + 1].requestFocus();
    } else if (val.isNotEmpty && index == widget.length - 1) {
      // Unfocus on last digit to remove cursor
      _focusNodes[index].unfocus();
    }

    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        widget.onChanged(_controllers.map((c) => c.text).join());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final hasFocus = _focusNodes[index].hasFocus;

        return Container(
          width: widget.size,
          height: widget.size,
          margin: EdgeInsets.only(
            right: index < widget.length - 1 ? widget.gap : 0,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: hasFocus ? scheme.primary : scheme.outline,
              width: hasFocus ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              // Completely invisible TextField for input
              Positioned.fill(
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (KeyEvent event) => _onKeyEvent(event, index),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    style: const TextStyle(color: Colors.transparent),
                    cursorColor: scheme.primary,
                    cursorWidth: 2,
                    cursorHeight: 20,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                    onChanged: (val) => _onChanged(val, index),
                  ),
                ),
              ),
              // Visible text display
              IgnorePointer(
                child: Center(
                  child: Text(
                    _controllers[index].text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
