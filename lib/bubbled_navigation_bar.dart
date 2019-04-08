library bubbled_navigation_bar;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

import 'dart:ui';
import 'dart:math' as math;

class BubbledNavigationBar extends StatefulWidget {
  final List<BubbledNavigationBarItem> items;
  final MenuPositionController controller;
  final int initialIndex;
  final double iconRightMargin;
  final EdgeInsets itemMargin;
  final Color defaultBubbleColor;
  final Color backgroundColor;
  final Curve animationCurve;
  final Duration animationDuration;
  final ValueChanged<int> onTap;

  BubbledNavigationBar({
    Key key,
    @required this.items,
    this.controller,
    this.defaultBubbleColor = Colors.blueAccent,
    this.iconRightMargin = 6,
    this.initialIndex = 0,
    this.itemMargin,
    this.backgroundColor = Colors.white,
    this.onTap,
    this.animationCurve = Curves.easeInOutQuad,
    this.animationDuration,
  }) : 
  assert(items != null), 
  assert(items.length >= 2), 
  assert(initialIndex < items.length && initialIndex >= 0), 
  super(key: key);

  @override
  _BubbledNavigationBarState createState() => new _BubbledNavigationBarState();
}

class _BubbledNavigationBarState extends State<BubbledNavigationBar> with TickerProviderStateMixin {
  static const double _kBottomMargin = 8.0;
  static const double _kMinIconWidth = 1.0;
  static const double _kBarHeight = 55.0;
  static const double _kBubbleHeight = 45.0;
  static const double _kHorizontalPadding = 8.0;
  static const EdgeInsets _kBubblePadding = EdgeInsets.only(left: 13, right: 10);

  double _selectedItemWidthMax = 0;
  double _customDrawingForWidth = 0;

  MenuPositionController _controller;

  List<GlobalKey> titlesKeys = List<GlobalKey>();
  List<GlobalKey> iconsKeys = List<GlobalKey>();
  List<double> titleWidths = List<double>();
  List<double> iconsWidths = List<double>();

  List<Rect> selectedItemsRects = List<Rect>();

  @override
  void initState() {
    widget.items.forEach((_) {
      titlesKeys.add(GlobalKey());
      iconsKeys.add(GlobalKey());
    });

    _initController();
    super.initState();
  }

  void _initController() {
    if (_controller != null) {
      _controller.removeListener(_positionControllerValueChanged);
    }
    _controller = widget.controller ?? MenuPositionController(initPosition: 0);
    _controller.defaultAnimationDuration = widget.animationDuration ?? Duration(milliseconds: 500);
    _controller.defaultAnimationCurve = widget.animationCurve;
    
    // TODO remove vsync from here
    _controller.vsync = this;
    
    _controller.addListener(_positionControllerValueChanged);
    if (widget.initialIndex != null) {
      _controller.lastPosition = widget.initialIndex;
    }
  }

  void didUpdateWidget(BubbledNavigationBar oldWidget) {
    _initController();

    super.didUpdateWidget(oldWidget);
  }

  _updateDrawingInfo() {
    titleWidths.clear();
    iconsWidths.clear();
    selectedItemsRects.clear();

    titlesKeys.forEach((key) {
      RenderBox renderBox = key.currentContext.findRenderObject();
      titleWidths.add(renderBox.size.width);
    });
    iconsKeys.forEach((key) {
      RenderBox renderBox = key.currentContext.findRenderObject();
      iconsWidths.add(math.max(_kMinIconWidth, renderBox.size.width));
    });

    _calculateRectsForGroundedItems();

    double currentWidgetWidth = _getMenuWidth();
    if (_customDrawingForWidth != currentWidgetWidth) {
      setState(() {
        _customDrawingForWidth = currentWidgetWidth;
      });
    }
  }

  double _getMenuWidth() => (MediaQuery.of(context).size.width - 2 * _kHorizontalPadding);

  void _calculateRectsForGroundedItems() {
    _selectedItemWidthMax = 0;
    for (var index = 0; index < widget.items.length; index++) {
      _selectedItemWidthMax = math.max(_selectedItemWidthMax, _itemWidth(index));
    }
    _selectedItemWidthMax += (widget.itemMargin != null ? widget.itemMargin.left + widget.itemMargin.right : 0);

    for (var index = 0; index < widget.items.length; index++) {
      selectedItemsRects.add(_rectForItem(index));
    }
  }

  double _itemWidth(int index) => iconsWidths[index] + 
                                  widget.iconRightMargin + 
                                  titleWidths[index];

  Rect _rectForItem(int index) {
    double shrinkedItemWidth = (_getMenuWidth() - _selectedItemWidthMax) / (widget.items.length - 1);
    double paddingForEmptySpace = (_selectedItemWidthMax - _itemWidth(index)) / 2;

    return Rect.fromLTWH(
      shrinkedItemWidth * index + paddingForEmptySpace,
      (_kBarHeight - _kBubbleHeight) / 2,
      _selectedItemWidthMax - 2 * paddingForEmptySpace,
      _kBubbleHeight
    );
  }

  void _positionControllerValueChanged() {
    /// Checking [absolutePosition] is enough for [targetStablePosition]
    /// and set [lastStablePosition] new value
    if (_controller.targetPosition != null && 
        (_controller.absolutePosition <= _controller.targetPosition &&
         _controller.targetPosition - _controller.lastPosition < 0) ||
        (_controller.absolutePosition >= _controller.targetPosition &&
         _controller.targetPosition - _controller.lastPosition > 0)) {

      _controller.lastPosition = _controller.targetPosition;
    }
    setState(() {});
  }

  SelectionPainter _buildSelectionPainter() {
    if (selectedItemsRects.length == 0) {
      return null;
    }

    Rect lastRect = selectedItemsRects[_controller.lastPosition];
    Color lastColor = widget.items[_controller.lastPosition].bubbleColor ?? widget.defaultBubbleColor;
    if (_controller.selectionNotGoingAnywhere) {
      return _selectionPainter(lastRect, lastColor);
    }

    Rect targetRect = selectedItemsRects[_controller.targetPosition];
    Rect mergedRect = Rect.lerp(lastRect, targetRect, _controller.progressToTargetPosition);

    Color targetColor = widget.items[_controller.targetPosition].bubbleColor ?? widget.defaultBubbleColor;
    Color mergedColor = Color.lerp(lastColor, targetColor, _controller.progressToTargetPosition);

    return _selectionPainter(mergedRect, mergedColor);
  }

  SelectionPainter _selectionPainter(Rect rect, Color color) {
    double y = rect.top + rect.height / 2;
    return SelectionPainter(
      rect.left + _kBubblePadding.left,
      y,
      rect.left + rect.width - _kBubblePadding.right,
      y,
      radius: rect.height / 2,
      controlPointsOffset: rect.height / 10 * 3,
      color: color
    );
  }

  Widget _getMenuItem(int index, double unselectedItemWidth) {
    return _MenuItem(
      item: widget.items[index],
      selectProgress: _controller.itemSelectedProgress(index).abs(),
      onPressed: () {
        _controller.lastPosition = _controller.targetPosition;
        _controller.targetPosition = index;
        _controller.animateToPosition(index);
        widget.onTap(index);
      },
      forceWidth: unselectedItemWidth,
      forceSelectedWidth: _selectedItemWidthMax,
      vsync: this,
      iconRightMargin: widget.iconRightMargin,
      titleKey: titlesKeys[index],
      iconKey: iconsKeys[index],
      titleWidth: titleWidths.length > 0 ? titleWidths[index] : 0,
      iconWidth: iconsWidths.length > 0 ? iconsWidths[index] : 0,
      height: _kBarHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double additionalBottomPadding = math.max(MediaQuery.of(context).padding.bottom - _kBottomMargin, 0.0);
    final double unselectedItemWidth = (_getMenuWidth() - _selectedItemWidthMax) / (widget.items.length - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateDrawingInfo());

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: kBottomNavigationBarHeight + additionalBottomPadding,
      ),
      child: Container(
        color: widget.backgroundColor,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: additionalBottomPadding,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kHorizontalPadding),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                CustomPaint(
                  painter: _buildSelectionPainter(),
                  child: Container(
                    height: _kBarHeight,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(widget.items.length, (index) {
                    return _getMenuItem(index, unselectedItemWidth);
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_positionControllerValueChanged);
    super.dispose();
  }
}

class BubbledNavigationBarItem {
  const BubbledNavigationBarItem({
    @required this.icon,
    this.title,
    Widget activeIcon,
    this.bubbleColor,
  }) :
  activeIcon = activeIcon ?? icon,
  assert(icon != null);

  final Widget icon;
  final Widget activeIcon;
  final Widget title;
  final Color bubbleColor;
}

class _MenuItem extends StatelessWidget {
  final BubbledNavigationBarItem item;
  final double selectProgress;
  final VoidCallback onPressed;
  final TickerProvider vsync;
  final GlobalKey titleKey;
  final GlobalKey iconKey;
  final double forceWidth;
  final double forceSelectedWidth;
  final double titleWidth;
  final double iconWidth;
  final double iconRightMargin;
  final double height;

  _MenuItem({
    Key key,
    @required this.item,
    @required this.selectProgress,
    @required this.onPressed,
    @required this.vsync,
    this.height,
    this.forceWidth,
    this.forceSelectedWidth,
    this.iconRightMargin = 0,
    this.titleKey,
    this.iconKey,
    this.titleWidth = 0,
    this.iconWidth = 0
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double iconXPos = _getIconPosition();

    return GestureDetector(
      // onTap: onPressed,
      onTapUp: (_) {
        onPressed();
      },
      child: Container(
        color: Colors.white.withAlpha(1),
        child: AnimatedSize(
          vsync: vsync,
          curve: Curves.easeInOutQuart,
          duration: Duration(milliseconds: 300),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              Positioned(
                left: iconXPos,
                child: Opacity(
                  opacity: 1 - selectProgress,
                  child: Container(
                    key: iconKey,
                    child: item.icon
                  )
                ),
              ),
              Positioned(
                left: iconXPos,
                child: Opacity(
                  opacity: selectProgress,
                  child: item.activeIcon
                ),
              ),
              Positioned(
                left: _getTitlePosition(),
                child: Opacity(
                  opacity: math.max(3 * selectProgress - 2, 0),
                  child: Container(
                    key: titleKey,
                    child: item.title,
                  )
                ),
              )
            ],
          ),
        ),
        width: _getWidth(),
        height: height ?? 0,
      ),
    );
  }

  double _getIconAndTextWidth() => iconWidth + iconRightMargin + titleWidth;

  double _getIconSelectedPosition() => (forceSelectedWidth - _getIconAndTextWidth()) / 2;

  double _getIconShrinkedPosition() => (forceWidth - iconWidth) / 2;

  double _getIconPosition() {
    if (forceWidth == null) {
      return 0;
    } else {
      return lerpDouble(
        _getIconShrinkedPosition(),
        _getIconSelectedPosition(),
        selectProgress
      );
    }
  }

  double _getTitlePosition() {
    if (forceWidth == null) { 
      return iconWidth + iconRightMargin;
    } else {
      double fadingOffset = 50.0 * (1 - selectProgress);
      return _getIconSelectedPosition() + iconWidth + iconRightMargin - fadingOffset;
    }
  }

  double _getWidth() {
    double width = forceWidth ?? iconWidth;
    double selectedWidth = forceSelectedWidth ?? iconWidth + iconRightMargin + titleWidth;
    return lerpDouble(width, selectedWidth, selectProgress);
  }
}

class SelectionPainter extends CustomPainter {
  double startX;
  double startY;
  double endX;
  double endY;
  double radius = 5;
  double controlPointsOffset = 3;
  Color color;

  SelectionPainter(double startX, double startY, double endX, double endY, {this.radius, this.controlPointsOffset, this.color}) {
    this.startX = startX;
    this.startY = startY;
    this.endX = endX;
    this.endY = endY;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(startX, startY - radius)
      ..cubicTo(startX + controlPointsOffset, startY - radius, endX - controlPointsOffset, startY - radius, endX, startY - radius)
      ..cubicTo(endX + controlPointsOffset, startY - radius, endX + radius, startY - controlPointsOffset, endX + radius, startY)
      ..cubicTo(endX + radius, startY + controlPointsOffset, endX + controlPointsOffset, startY + radius, endX, startY + radius)
      ..cubicTo(endX - controlPointsOffset, startY + radius, startX + controlPointsOffset, startY + radius, startX, startY + radius)
      ..cubicTo(startX - controlPointsOffset, startY + radius, startX - radius, startY + controlPointsOffset, startX - radius, startY)
      ..cubicTo(startX - radius, startY - controlPointsOffset, startX - controlPointsOffset, startY - radius, startX, startY - radius)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return this != oldDelegate;
  }
}

class MenuPositionState {
  final double absolutePosition;
  final int lastPosition;
  final int targetPosition;

  MenuPositionState({
    this.absolutePosition = 0,
    this.lastPosition = 0,
    this.targetPosition = 0
  }) : assert(absolutePosition != null),
       assert(lastPosition != null);

  MenuPositionState copyWith({
    double absolutePosition,
    int lastPosition,
    int targetPosition
  }) {
    return MenuPositionState(
      absolutePosition: absolutePosition ?? this.absolutePosition,
      lastPosition: lastPosition ?? this.lastPosition,
      targetPosition: targetPosition != null ? (targetPosition == -1 ? null : targetPosition) : this.targetPosition,
    );
  }

  static MenuPositionState init = MenuPositionState();

  @override
  String toString() => '$runtimeType(absolute: $absolutePosition, last: $lastPosition, target: $targetPosition)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! MenuPositionState)
      return false;
    final MenuPositionState typedOther = other;
    return typedOther.absolutePosition == absolutePosition
        && typedOther.lastPosition == lastPosition
        && typedOther.targetPosition == targetPosition;
  }

  @override
  int get hashCode => hashValues(
    absolutePosition.hashCode,
    lastPosition.hashCode,
    targetPosition.hashCode
  );
}

class MenuPositionController extends ValueNotifier<MenuPositionState> {
  Curve defaultAnimationCurve;
  Duration defaultAnimationDuration;
  // TODO remove vsync from here
  TickerProvider vsync;

  AnimationController _animationController;
  Animation<double> _positionAnimation;

  MenuPositionController({int initPosition})
    : super(MenuPositionState(lastPosition: initPosition));

  MenuPositionController.fromValue(MenuPositionState value)
    : super(value ?? MenuPositionState.init);

  void animateToPosition(int position, {Curve curve, Duration duration}) {
    _animationController = AnimationController(
      vsync: vsync, 
      duration: duration ?? defaultAnimationDuration,
    );

    _positionAnimation = Tween(begin: lastPosition.toDouble(), end: position.toDouble()).animate(
      CurvedAnimation(parent: _animationController, curve: curve ?? defaultAnimationCurve)
    );

    _positionAnimation.addListener(() {
      absolutePosition = _positionAnimation.value;
    });

    targetPosition = position;
    _animationController.forward();
  }

  double get absolutePosition => value.absolutePosition;

  set absolutePosition(double newAbsolutePosition) {
    value = value.copyWith(absolutePosition: newAbsolutePosition);
  }

  int get lastPosition => value.lastPosition;

  set lastPosition(int newLastStablePosition) {
    value = value.copyWith(lastPosition: newLastStablePosition);
  }

  int get targetPosition => value.targetPosition;

  set targetPosition(int newTargetStablePosition) {
    value = value.copyWith(targetPosition: newTargetStablePosition ?? -1);
  }

  void findNearestTarget(double newAbsolutePosition) {
    double delta = newAbsolutePosition - value.lastPosition;
    int positionDelta = 0;
    if (delta < 0) positionDelta = - 1;
    if (delta > 0) positionDelta = 1;
    value = value.copyWith(targetPosition:value.lastPosition + positionDelta);
  }

  double get movementDelta => (value.targetPosition - value.lastPosition).toDouble();

  double get progressToTargetPosition => (value.absolutePosition - value.lastPosition) / movementDelta;

  double itemSelectedProgress(int index) {
    if (selectionNotGoingAnywhere) {
      return value.lastPosition == index ? 1.0 : 0.0;
    }

    if (index == value.targetPosition) {
      return math.min(1, math.max(0, progressToTargetPosition));
    } else if (index == value.lastPosition) {
      return math.max(0, math.min(1, 1 - progressToTargetPosition));
    }
    return 0;
  }

  bool get selectionNotGoingAnywhere {
    return value.targetPosition == null || value.targetPosition == value.lastPosition;
  }

  void clear() {
    value = MenuPositionState.init;
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }
}
