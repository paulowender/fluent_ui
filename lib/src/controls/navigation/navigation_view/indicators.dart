// ignore_for_file: use_key_in_widget_constructors

part of 'view.dart';

const kIndicatorAnimationDuration = Duration(milliseconds: 500);

/// A indicator used by [NavigationPane] to render the selected
/// indicator.
class NavigationIndicator extends StatefulWidget {
  /// Creates a navigation indicator used by [NavigationPane]
  /// to render the selected indicator.
  const NavigationIndicator({
    this.curve = Curves.linear,
    this.color,
    this.duration = kIndicatorAnimationDuration,
  }) : super();

  /// The curve used on the animation, if any
  ///
  /// For sticky navigation indicator, [Curves.easeIn] is recommended
  final Curve curve;

  /// The duration used on the animation, if any
  ///
  /// 500 milliseconds is used by default
  final Duration duration;

  /// The highlight color
  final Color? color;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty(
      'curve',
      curve,
      defaultValue: Curves.linear,
    ));
    properties.add(ColorProperty('highlight color', color));
  }

  @override
  NavigationIndicatorState createState() => NavigationIndicatorState();
}

class NavigationIndicatorState<T extends NavigationIndicator> extends State<T> {
  List<Offset>? offsets;

  @override
  void initState() {
    super.initState();
    fetch();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {});
    });
  }

  void fetch() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final localOffsets = pane.effectiveItems._getPaneItemsOffsets(
        pane.paneKey,
      );
      if (mounted && (offsets != localOffsets)) {
        offsets = localOffsets;
      }
    });
  }

  NavigationPane get pane {
    return InheritedNavigationView.of(context).pane!;
  }

  int get selectedIndex {
    return pane.selected ?? -1;
  }

  bool get isSelected {
    return pane.isSelected(pane.effectiveItems[itemIndex]);
  }

  Axis get axis {
    if (InheritedNavigationView.maybeOf(context)?.displayMode ==
        PaneDisplayMode.top) {
      return Axis.vertical;
    }
    return Axis.horizontal;
  }

  int get itemIndex {
    return InheritedNavigationView.of(context).currentItemIndex;
  }

  int get oldIndex {
    return InheritedNavigationView.of(context).oldIndex;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// The end navigation indicator
class EndNavigationIndicator extends NavigationIndicator {
  const EndNavigationIndicator({
    Color? color,
    this.unselectedColor = Colors.transparent,
  }) : super(color: color);

  /// The color of the indicator when the item is not selected
  final Color unselectedColor;

  @override
  _EndNavigationIndicatorState createState() => _EndNavigationIndicatorState();
}

class _EndNavigationIndicatorState
    extends NavigationIndicatorState<EndNavigationIndicator> {
  @override
  Widget build(BuildContext context) {
    if (selectedIndex.isNegative) return const SizedBox.shrink();
    assert(debugCheckHasFluentTheme(context));

    final bool isTop = axis == Axis.vertical;
    final theme = NavigationPaneTheme.of(context);

    return IgnorePointer(
      child: Align(
        alignment: isTop
            ? AlignmentDirectional.bottomCenter
            : AlignmentDirectional.centerStart,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 75),
          reverseDuration: Duration.zero,
          child: Container(
            key: ValueKey<int>(itemIndex),
            margin: EdgeInsets.symmetric(
              vertical: isTop ? 0.0 : 10.0,
              horizontal: isTop ? 10.0 : 0.0,
            ),
            width: isTop ? 20.0 : 6.0,
            height: isTop ? 4.5 : double.infinity,
            color: itemIndex != selectedIndex
                ? widget.unselectedColor
                : widget.color ?? theme.highlightColor,
          ),
        ),
      ),
    );
  }
}

/// A sticky navigation indicator.
class StickyNavigationIndicator extends NavigationIndicator {
  /// Creates a sticky navigation indicator.
  const StickyNavigationIndicator({
    Curve curve = Curves.easeIn,
    Color? color,
    Duration duration = kIndicatorAnimationDuration,
    this.topPadding = 12.0,
    this.leftPadding = 10.0,
  }) : super(curve: curve, color: color, duration: duration);

  /// The padding used on both horizontal sides of the indicator when the
  /// current display mode is top.
  ///
  /// Defaults to 12.0
  final double topPadding;

  /// The padding used on both vertical sides of the indicator when the current
  /// display mode is not top.
  ///
  /// Defaults to 10.0
  final double leftPadding;

  @override
  _StickyNavigationIndicatorState createState() =>
      _StickyNavigationIndicatorState();
}

class _StickyNavigationIndicatorState
    extends NavigationIndicatorState<StickyNavigationIndicator>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController upController;
  late AnimationController downController;

  @override
  void initState() {
    super.initState();
    upController = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    downController = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
  }

  Animation<double>? upAnimation;
  Animation<double>? downAnimation;

  int _old = -1;

  @override
  void dispose() {
    upController.dispose();
    downController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StickyNavigationIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      upController.duration = downController.duration = widget.duration;
    }
  }

  bool get isShowing {
    if (itemIndex.isNegative) return false;

    if (itemIndex == selectedIndex) return true;
    return itemIndex == oldIndex && _old != oldIndex;
  }

  bool get isAbove => oldIndex < selectedIndex;
  bool get isBelow => oldIndex > selectedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    animate();
  }

  void animate() async {
    if (!mounted) {
      return;
    }

    if (isShowing) {
      if (isBelow) {
        if (isSelected) {
          downAnimation = Tween<double>(begin: 0, end: 1.0).animate(
            CurvedAnimation(
              curve: Interval(0.5, 1.0, curve: widget.curve),
              parent: downController,
            ),
          );
          upAnimation = null;
          await downController.forward(from: 0.0);
        } else {
          upAnimation = Tween<double>(begin: 0, end: 1.0).animate(
            CurvedAnimation(curve: widget.curve, parent: upController),
          );
          downAnimation = null;
          await upController.reverse(from: 1.0);
        }
      } else if (isAbove) {
        if (isSelected) {
          upAnimation = Tween<double>(begin: 0, end: 1.0).animate(
            CurvedAnimation(
              curve: Interval(0.5, 1.0, curve: widget.curve),
              parent: upController,
            ),
          );
          downAnimation = null;
          await upController.forward(from: 0.0);
        } else {
          downAnimation = Tween<double>(begin: 0, end: 1.0).animate(
            CurvedAnimation(curve: widget.curve, parent: downController),
          );
          upAnimation = null;
          await downController.reverse(from: 1.0);
        }
      }
    }

    _old = oldIndex;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (offsets == null || !isShowing || selectedIndex.isNegative) {
      return const SizedBox.shrink();
    }

    // Ensure it is only kept alive after if it's showing and after the offets
    // are fetched
    super.build(context);
    assert(debugCheckHasFluentTheme(context));

    final NavigationPaneThemeData theme = NavigationPaneTheme.of(context);
    final bool isHorizontal = axis == Axis.horizontal;

    final decoration = BoxDecoration(
      color: widget.color ?? theme.highlightColor,
      borderRadius: BorderRadius.circular(100),
    );

    return SizedBox(
      height: double.infinity,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([upController, downController]),
          child: isHorizontal
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(width: 2.5, decoration: decoration),
                )
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(height: 2.5, decoration: decoration),
                ),
          builder: (context, child) {
            if (!isSelected) {
              if (upController.status == AnimationStatus.dismissed ||
                  downController.status == AnimationStatus.dismissed) {
                return const SizedBox.shrink();
              }
            }

            return Padding(
              padding: isHorizontal
                  ? EdgeInsets.only(
                      left: offsets![itemIndex].dx,
                      top: widget.leftPadding * (upAnimation?.value ?? 1.0),
                      bottom:
                          widget.leftPadding * (downAnimation?.value ?? 1.0),
                    )
                  : EdgeInsetsDirectional.only(
                      start: widget.topPadding * (upAnimation?.value ?? 1.0),
                      end: widget.topPadding * (downAnimation?.value ?? 1.0),
                    ),
              child: child,
            );
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
