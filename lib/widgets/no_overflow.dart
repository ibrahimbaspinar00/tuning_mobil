import 'package:flutter/material.dart';

/// A drop-in wrapper to eliminate bottom overflows in Container-heavy screens.
///
/// Usage:
///   return Scaffold(
///     body: NoOverflow(child: YourColumnOrList()),
///   );
class NoOverflow extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const NoOverflow({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);
          final double bottomInset = media.viewInsets.bottom; // keyboard, etc.
          final EdgeInsetsGeometry resolvedPadding = EdgeInsets.only(
            bottom: (bottomInset > 0 ? bottomInset : 0) + 16,
          ).add(padding ?? EdgeInsets.zero);

          return SingleChildScrollView(
            padding: resolvedPadding,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                minWidth: constraints.maxWidth,
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}


