import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PerformanceMonitor {
  static void logNavigationTime(String screenName, DateTime startTime) {
    if (kDebugMode) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint(
        '🚀 Navigation to $screenName took: ${duration.inMilliseconds}ms',
      );
    }
  }

  static void logWidgetBuildTime(String widgetName, DateTime startTime) {
    if (kDebugMode) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('🔨 Build time for $widgetName: ${duration.inMilliseconds}ms');
    }
  }

  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      debugPrint('📊 Memory context: $context');
      // Note: Detailed memory profiling requires additional tools in production
    }
  }
}

// Widget wrapper for performance monitoring
class PerformanceWrapper extends StatefulWidget {
  final Widget child;
  final String name;

  const PerformanceWrapper({
    super.key,
    required this.child,
    required this.name,
  });

  @override
  State<PerformanceWrapper> createState() => _PerformanceWrapperState();
}

class _PerformanceWrapperState extends State<PerformanceWrapper> {
  late DateTime _buildStartTime;

  @override
  void initState() {
    super.initState();
    _buildStartTime = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PerformanceMonitor.logWidgetBuildTime(widget.name, _buildStartTime);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Mixin for screen performance monitoring
mixin ScreenPerformanceMixin<T extends StatefulWidget> on State<T> {
  late DateTime _screenStartTime;
  String get screenName;

  @override
  void initState() {
    super.initState();
    _screenStartTime = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PerformanceMonitor.logNavigationTime(screenName, _screenStartTime);
  }
}

// Image caching helper
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return placeholder ??
            Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Icon(Icons.error_outline, color: Colors.grey[600]),
        );
      },
    );
  }
}
