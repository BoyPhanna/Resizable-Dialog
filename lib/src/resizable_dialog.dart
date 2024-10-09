import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import './resize_direction.dart';
import './resizable_dialog_position.dart';
import './resizable_dialog_theme_options.dart';

Future<void> showResizableDialog(
  Key? key,
  BuildContext context,
  Widget title,
  ResizableDialogPosition? position,
  Size? size,
  Size? minSize,
  ResizableDialogThemeOptions? options,
  ValueChanged<Size>? onResize,
  ValueChanged<Offset>? onDrag,
  ValueChanged<Rect>? onChange,
  Widget child,
) async {
  return await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        key: key,
        child: ResizableDialog(
          title: title,
          position: position ?? ResizableDialogPosition.center,
          initialSize: size ?? const Size(300, 300),
          minSize: minSize ?? const Size(100, 100),
          onResize: onResize,
          onDrag: onDrag,
          onChange: onChange,
          options: options,
          child: child,
        ),
      );
    },
  );
}

class ResizableDialog extends StatefulWidget {
  final Widget title;
  final ResizableDialogPosition position;
  final Size initialSize;
  final Size minSize;
  final ValueChanged<Size>? onResize;
  final ValueChanged<Offset>? onDrag;
  final ValueChanged<Rect>? onChange;
  final ResizableDialogThemeOptions? options;
  final Widget child;

  const ResizableDialog({
    super.key,
    required this.title,
    this.position = ResizableDialogPosition.center,
    this.initialSize = const Size(300, 300),
    this.minSize = const Size(100, 100),
    this.onResize,
    this.onDrag,
    this.onChange,
    this.options,
    required this.child,
  });

  @override
  State<ResizableDialog> createState() => _ResizableDialogState();
}

class _ResizableDialogState extends State<ResizableDialog> {
  late Offset offset = switch (widget.position) {
    ResizableDialogPosition.center => _middleOfScreen(),
    ResizableDialogPosition.left => Offset(0, _middleOfScreen().dy),
    ResizableDialogPosition.top => Offset(_middleOfScreen().dx, 0),
    ResizableDialogPosition.right =>
      Offset(View.of(context).physicalSize.width, _middleOfScreen().dy),
    ResizableDialogPosition.bottom =>
      Offset(_middleOfScreen().dx, View.of(context).physicalSize.height),
  };
  late Size size = widget.initialSize;
  bool resizing = false;
  ResizeDirection resizeDirection = ResizeDirection.none;
  SystemMouseCursor currentCursor = SystemMouseCursors.basic;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: offset.dx,
            top: offset.dy,
            width: size.width,
            height: size.height,
            child: MouseRegion(
              cursor: currentCursor,
              onHover: (event) => _updateCursor(
                  event.localPosition, Size(size.width, size.height)),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                  ),
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: widget.options?.handleColor ??
                        Theme.of(context).dialogTheme.surfaceTintColor ??
                        Theme.of(context).highlightColor,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: widget.options?.borderColor ??
                          Theme.of(context).dialogTheme.surfaceTintColor ??
                          Theme.of(context).highlightColor,
                      width: 0.75,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Stack(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.basic,
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Container(
                            color: Theme.of(context).dialogBackgroundColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: double.infinity,
                                    maxHeight: 100,
                                  ),
                                  color:
                                      widget.options?.headerBackgroundColor ??
                                          Theme.of(context)
                                              .dialogTheme
                                              .contentTextStyle
                                              ?.backgroundColor,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onPanUpdate: (details) {
                                            setState(() {
                                              offset += details.delta;
                                              _clampOffset(screenSize);
                                            });
                                          },
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 10),
                                            child: widget.title,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        icon: Icon(widget.options?.closeIcon,
                                            color:
                                                widget.options?.closeIconColor),
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                      ),
                                    ],
                                  ),
                                ),
                                // Divider
                                Divider(
                                  height: 2,
                                  thickness: 1,
                                  color: widget.options?.borderColor ??
                                      Theme.of(context).highlightColor,
                                ),
                                // Content
                                Expanded(
                                  child: Container(
                                    color: widget.options?.backgroundColor ??
                                        Theme.of(context).dialogBackgroundColor,
                                    child: widget.child,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: (_) {},
                          child: Container(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Offset _middleOfScreen() {
    final pos = View.of(context).physicalSize;

    return Offset(pos.width / 2, pos.height / 2);
  }

  void _onPanStart(DragStartDetails details) {
    final position = details.localPosition;
    const edgeMargin = 10.0;

    setState(() {
      resizeDirection = _getResizeDirection(position, size, edgeMargin);
      resizing = resizeDirection != ResizeDirection.none;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (resizing && resizeDirection != ResizeDirection.none) {
      _resizeDialog(details, resizeDirection);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      resizing = false;
      resizeDirection = ResizeDirection.none;
    });
  }

  ResizeDirection _getResizeDirection(
      Offset position, Size size, double edgeMargin) {
    if (position.dx < edgeMargin && position.dy < edgeMargin) {
      return ResizeDirection.topLeft;
    } else if (position.dx > size.width - edgeMargin &&
        position.dy < edgeMargin) {
      return ResizeDirection.topRight;
    } else if (position.dx > size.width - edgeMargin &&
        position.dy > size.height - edgeMargin) {
      return ResizeDirection.bottomRight;
    } else if (position.dx < edgeMargin &&
        position.dy > size.height - edgeMargin) {
      return ResizeDirection.bottomLeft;
    } else if (position.dx < edgeMargin) {
      return ResizeDirection.left;
    } else if (position.dx > size.width - edgeMargin) {
      return ResizeDirection.right;
    } else if (position.dy < edgeMargin) {
      return ResizeDirection.top;
    } else if (position.dy > size.height - edgeMargin) {
      return ResizeDirection.bottom;
    } else {
      return ResizeDirection.none;
    }
  }

  void _resizeDialog(DragUpdateDetails details, ResizeDirection direction) {
    final screenSize = MediaQuery.sizeOf(context);
    double newWidth = size.width;
    double newHeight = size.height;
    double newOffsetX = offset.dx;
    double newOffsetY = offset.dy;

    switch (direction) {
      case ResizeDirection.left:
        newWidth = size.width - details.delta.dx;
        newOffsetX += details.delta.dx;
        if (newWidth >= widget.minSize.width && newOffsetX >= 0) {
          size = Size(newWidth, size.height);
          offset = Offset(newOffsetX, offset.dy);
        }
        break;

      case ResizeDirection.right:
        newWidth = size.width + details.delta.dx;
        if (newWidth >= widget.minSize.width &&
            (offset.dx + newWidth) <= screenSize.width) {
          size = Size(newWidth, size.height);
        }
        break;

      case ResizeDirection.top:
        newHeight = size.height - details.delta.dy;
        newOffsetY += details.delta.dy;
        if (newHeight >= widget.minSize.height && newOffsetY >= 0) {
          size = Size(size.width, newHeight);
          offset = Offset(offset.dx, newOffsetY);
        }
        break;

      case ResizeDirection.bottom:
        newHeight = size.height + details.delta.dy;
        if (newHeight >= widget.minSize.height &&
            (offset.dy + newHeight) <= screenSize.height) {
          size = Size(size.width, newHeight);
        }
        break;

      case ResizeDirection.topLeft:
        newWidth = size.width - details.delta.dx;
        newHeight = size.height - details.delta.dy;
        newOffsetX += details.delta.dx;
        newOffsetY += details.delta.dy;
        if (newWidth >= widget.minSize.width &&
            newHeight >= widget.minSize.height &&
            newOffsetX >= 0 &&
            newOffsetY >= 0) {
          size = Size(newWidth, newHeight);
          offset = Offset(newOffsetX, newOffsetY);
        }
        break;

      case ResizeDirection.topRight:
        newWidth = size.width + details.delta.dx;
        newHeight = size.height - details.delta.dy;
        newOffsetY += details.delta.dy;
        if (newWidth >= widget.minSize.width &&
            newHeight >= widget.minSize.height &&
            (offset.dx + newWidth) <= screenSize.width &&
            newOffsetY >= 0) {
          size = Size(newWidth, newHeight);
          offset = Offset(offset.dx, newOffsetY);
        }
        break;

      case ResizeDirection.bottomLeft:
        newWidth = size.width - details.delta.dx;
        newHeight = size.height + details.delta.dy;
        newOffsetX += details.delta.dx;
        if (newWidth >= widget.minSize.width &&
            newHeight >= widget.minSize.height &&
            newOffsetX >= 0 &&
            (offset.dy + newHeight) <= screenSize.height) {
          size = Size(newWidth, newHeight);
          offset = Offset(newOffsetX, offset.dy);
        }
        break;

      case ResizeDirection.bottomRight:
        newWidth = size.width + details.delta.dx;
        newHeight = size.height + details.delta.dy;
        if (newWidth >= widget.minSize.width &&
            newHeight >= widget.minSize.height &&
            (offset.dx + newWidth) <= screenSize.width &&
            (offset.dy + newHeight) <= screenSize.height) {
          size = Size(newWidth, newHeight);
        }
        break;
      default:
        break;
    }

    setState(() {
      _clampSize(screenSize);
      _clampOffset(screenSize);
    });

    if (widget.onChange != null) {
      widget.onChange!(
          Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height));
    }

    if (widget.onDrag != null) {
      widget.onDrag!(offset);
    }

    if (widget.onResize != null) {
      widget.onResize!(size);
    }
  }

  void _clampOffset(Size screenSize) {
    offset = Offset(
      offset.dx.clamp(0.0, screenSize.width - size.width),
      offset.dy.clamp(0.0, screenSize.height - size.height),
    );
  }

  void _clampSize(Size screenSize) {
    size = Size(
      size.width.clamp(widget.minSize.width, screenSize.width - offset.dx),
      size.height.clamp(widget.minSize.height, screenSize.height - offset.dy),
    );
  }

  void _updateCursor(Offset position, Size size) {
    const edgeMargin = 10.0;

    if (position.dx < edgeMargin && position.dy < edgeMargin) {
      setState(() {
        currentCursor = SystemMouseCursors.resizeUpLeftDownRight;
      });
    } else if (position.dx > size.width - edgeMargin &&
        position.dy < edgeMargin) {
      setState(() {
        currentCursor = SystemMouseCursors.resizeUpRightDownLeft;
      });
    } else if (position.dx > size.width - edgeMargin &&
        position.dy > size.height - edgeMargin) {
      setState(() {
        currentCursor = SystemMouseCursors.resizeUpLeftDownRight;
      });
    } else if (position.dx < edgeMargin &&
        position.dy > size.height - edgeMargin) {
      setState(() {
        currentCursor = SystemMouseCursors.resizeUpRightDownLeft;
      });
    } else if (position.dx < edgeMargin ||
        position.dx > size.width - edgeMargin) {
      setState(() {
        currentCursor = SystemMouseCursors.resizeLeftRight;
      });
    } else if (position.dy < edgeMargin ||
        position.dy > size.height - edgeMargin) {
      setState(() {
        currentCursor = SystemMouseCursors.resizeUpDown;
      });
    } else {
      setState(() {
        currentCursor = SystemMouseCursors.basic;
      });
    }
  }
}
