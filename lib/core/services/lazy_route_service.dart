import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/loading_widgets.dart';

/// Service for implementing lazy loading of routes and screens
class LazyRouteService {
  static final LazyRouteService _instance = LazyRouteService._internal();
  factory LazyRouteService() => _instance;
  LazyRouteService._internal();

  final Map<String, Widget Function()> _routeBuilders = {};
  final Map<String, Widget> _cachedRoutes = {};
  final Set<String> _preloadedRoutes = {};

  /// Register a route with lazy loading
  void registerRoute(String routeName, Widget Function() builder) {
    _routeBuilders[routeName] = builder;
  }

  /// Get a route with lazy loading
  Widget getRoute(String routeName) {
    if (_cachedRoutes.containsKey(routeName)) {
      return _cachedRoutes[routeName]!;
    }

    if (_routeBuilders.containsKey(routeName)) {
      final widget = _routeBuilders[routeName]!();
      _cachedRoutes[routeName] = widget;
      return widget;
    }

    return const Scaffold(
      body: Center(
        child: Text('Route not found'),
      ),
    );
  }

  /// Preload a route in the background
  Future<void> preloadRoute(String routeName) async {
    if (_preloadedRoutes.contains(routeName) || 
        _cachedRoutes.containsKey(routeName)) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    
    if (_routeBuilders.containsKey(routeName)) {
      final widget = _routeBuilders[routeName]!();
      _cachedRoutes[routeName] = widget;
      _preloadedRoutes.add(routeName);
    }
  }

  /// Clear cached routes to free memory
  void clearCache([List<String>? routesToKeep]) {
    if (routesToKeep != null) {
      _cachedRoutes.removeWhere((key, value) => !routesToKeep.contains(key));
    } else {
      _cachedRoutes.clear();
    }
    _preloadedRoutes.clear();
  }

  /// Get memory usage info
  Map<String, dynamic> getMemoryInfo() {
    return {
      'cached_routes': _cachedRoutes.length,
      'registered_routes': _routeBuilders.length,
      'preloaded_routes': _preloadedRoutes.length,
    };
  }
}

/// Widget that provides lazy loading for routes
class LazyRoute extends StatefulWidget {
  final String routeName;
  final Widget Function()? fallbackBuilder;
  final Widget? loadingWidget;
  final Duration? timeout;

  const LazyRoute({
    Key? key,
    required this.routeName,
    this.fallbackBuilder,
    this.loadingWidget,
    this.timeout,
  }) : super(key: key);

  @override
  State<LazyRoute> createState() => _LazyRouteState();
}

class _LazyRouteState extends State<LazyRoute> {
  Widget? _loadedWidget;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      final lazyService = LazyRouteService();
      
      // Add timeout if specified
      if (widget.timeout != null) {
        await Future.any([
          Future.delayed(widget.timeout!),
          _performLoad(lazyService),
        ]);
      } else {
        await _performLoad(lazyService);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performLoad(LazyRouteService lazyService) async {
    final widget = lazyService.getRoute(this.widget.routeName);
    
    if (mounted) {
      setState(() {
        _loadedWidget = widget;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallbackBuilder?.call() ?? 
        const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Failed to load screen'),
              ],
            ),
          ),
        );
    }

    if (_isLoading) {
      return widget.loadingWidget ?? 
        const Scaffold(
          body: Center(
            child: ModernLoadingWidget(),
          ),
        );
    }

    return _loadedWidget ?? const SizedBox.shrink();
  }
}

/// Mixin for screens that support lazy loading
mixin LazyLoadableMixin<T extends StatefulWidget> on State<T> {
  bool _isLazyLoaded = false;
  
  /// Override this to implement lazy loading logic
  Future<void> onLazyLoad() async {}
  
  /// Call this when the screen becomes visible
  Future<void> triggerLazyLoad() async {
    if (!_isLazyLoaded) {
      _isLazyLoaded = true;
      await onLazyLoad();
    }
  }
  
  bool get isLazyLoaded => _isLazyLoaded;
}

/// Route generator with lazy loading support
class LazyRouteGenerator {
  static final LazyRouteService _lazyService = LazyRouteService();
  
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _createRoute(
          () => _lazyService.getRoute('splash'),
          settings,
        );
      case '/login':
        return _createRoute(
          () => _lazyService.getRoute('login'),
          settings,
        );
      case '/register':
        return _createRoute(
          () => _lazyService.getRoute('register'),
          settings,
        );
      case '/student-dashboard':
        return _createRoute(
          () => _lazyService.getRoute('student-dashboard'),
          settings,
          preloadRoutes: ['student-progress', 'student-profile'],
        );
      case '/student-progress':
        return _createRoute(
          () => _lazyService.getRoute('student-progress'),
          settings,
        );
      case '/instructor-dashboard':
        return _createRoute(
          () => _lazyService.getRoute('instructor-dashboard'),
          settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
        );
    }
  }
  
  static PageRoute _createRoute(
    Widget Function() builder,
    RouteSettings settings, {
    List<String>? preloadRoutes,
  }) {
    // Preload related routes in the background
    if (preloadRoutes != null) {
      for (final route in preloadRoutes) {
        _lazyService.preloadRoute(route);
      }
    }
    
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Widget for preloading routes based on user behavior
class RoutePreloader extends StatefulWidget {
  final Widget child;
  final List<String> routesToPreload;
  final Duration delay;

  const RoutePreloader({
    Key? key,
    required this.child,
    required this.routesToPreload,
    this.delay = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<RoutePreloader> createState() => _RoutePreloaderState();
}

class _RoutePreloaderState extends State<RoutePreloader> {
  @override
  void initState() {
    super.initState();
    _schedulePreloading();
  }

  void _schedulePreloading() {
    Future.delayed(widget.delay, () {
      if (mounted) {
        final lazyService = LazyRouteService();
        for (final route in widget.routesToPreload) {
          lazyService.preloadRoute(route);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}