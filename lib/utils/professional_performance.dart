import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ProfessionalPerformance {
  static final ProfessionalPerformance _instance = ProfessionalPerformance._internal();
  factory ProfessionalPerformance() => _instance;
  ProfessionalPerformance._internal();

  Timer? _performanceTimer;
  int _frameCount = 0;
  double _averageFPS = 60.0;
  bool _isMonitoring = false;

  // Performance monitoring
  void startPerformanceMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _performanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateFPS();
    });
  }

  void stopPerformanceMonitoring() {
    _isMonitoring = false;
    _performanceTimer?.cancel();
    _performanceTimer = null;
  }

  void _updateFPS() {
    // FPS hesaplama (basitleştirilmiş)
    _averageFPS = _frameCount.toDouble();
    _frameCount = 0;
    
    if (_averageFPS < 30) {
      _optimizePerformance();
    }
  }

  void _optimizePerformance() {
    // Performans optimizasyonları
    _clearImageCache();
    _reduceAnimations();
    _optimizeMemory();
  }

  void _clearImageCache() {
    // Image cache temizle
    PaintingBinding.instance.imageCache.clear();
  }

  void _reduceAnimations() {
    // Animasyonları azalt
    // Bu gerçek uygulamada daha detaylı olacak
  }

  void _optimizeMemory() {
    // Bellek optimizasyonu
    // Garbage collection tetikle
    // System.gc() Flutter'da mevcut değil, alternatif yöntemler kullanılır
  }

  // Memory optimization
  static void optimizeMemoryUsage() {
    // Image cache temizle
    PaintingBinding.instance.imageCache.clear();
    
    // Garbage collection - Flutter'da otomatik yönetilir
    // System.gc() Flutter'da mevcut değil
  }

  // Widget optimization
  static Widget optimizedBuilder({
    required Widget Function(BuildContext context) builder,
    String? key,
  }) {
    return Builder(
      key: key != null ? Key(key) : null,
      builder: builder,
    );
  }

  // List optimization
  static Widget optimizedListView({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }

  // Grid optimization
  static Widget optimizedGridView({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    required int crossAxisCount,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 0.0,
    double mainAxisSpacing = 0.0,
    ScrollController? controller,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }

  // Image optimization
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
        },
        // Cache optimization
        cacheWidth: width?.toInt(),
        cacheHeight: height?.toInt(),
      ),
    );
  }

  // Animation optimization
  static Widget optimizedAnimatedContainer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      child: RepaintBoundary(
        child: child,
      ),
    );
  }

  // Text optimization
  static Widget optimizedText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      // Text rendering optimization
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
  }

  // Button optimization
  static Widget optimizedButton({
    required VoidCallback? onPressed,
    required Widget child,
    ButtonStyle? style,
    bool autofocus = false,
    Clip clipBehavior = Clip.none,
  }) {
    return RepaintBoundary(
      child: ElevatedButton(
        onPressed: onPressed,
        style: style,
        autofocus: autofocus,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }

  // Card optimization
  static Widget optimizedCard({
    required Widget child,
    Color? color,
    Color? shadowColor,
    double? elevation,
    ShapeBorder? shape,
    bool borderOnForeground = true,
    EdgeInsetsGeometry? margin,
    Clip? clipBehavior,
  }) {
    return RepaintBoundary(
      child: Card(
        color: color,
        shadowColor: shadowColor,
        elevation: elevation,
        shape: shape,
        borderOnForeground: borderOnForeground,
        margin: margin,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }

  // Container optimization
  static Widget optimizedContainer({
    Widget? child,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
    Color? color,
    Decoration? decoration,
    Decoration? foregroundDecoration,
    double? width,
    double? height,
    BoxConstraints? constraints,
    EdgeInsetsGeometry? margin,
    Matrix4? transform,
    AlignmentGeometry? transformAlignment,
    Clip? clipBehavior,
  }) {
    return RepaintBoundary(
      child: Container(
        alignment: alignment,
        padding: padding,
        color: color,
        decoration: decoration,
        foregroundDecoration: foregroundDecoration,
        width: width,
        height: height,
        constraints: constraints,
        margin: margin,
        transform: transform,
        transformAlignment: transformAlignment,
        clipBehavior: clipBehavior ?? Clip.none,
        child: child,
      ),
    );
  }

  // Scroll optimization
  static Widget optimizedScrollView({
    required Widget child,
    ScrollController? controller,
    ScrollPhysics? physics,
    bool reverse = false,
    bool primary = false,
    EdgeInsetsGeometry? padding,
  }) {
    return SingleChildScrollView(
      controller: controller,
      physics: physics,
      reverse: reverse,
      primary: primary,
      padding: padding,
      child: RepaintBoundary(
        child: child,
      ),
    );
  }

  // Performance metrics
  double get averageFPS => _averageFPS;
  bool get isMonitoring => _isMonitoring;

  // Cleanup
  void dispose() {
    stopPerformanceMonitoring();
  }
}

// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addObserver(this);
      ProfessionalPerformance().startPerformanceMonitoring();
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      WidgetsBinding.instance.removeObserver(this);
      ProfessionalPerformance().stopPerformanceMonitoring();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        ProfessionalPerformance().startPerformanceMonitoring();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        ProfessionalPerformance().stopPerformanceMonitoring();
        ProfessionalPerformance.optimizeMemoryUsage();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
