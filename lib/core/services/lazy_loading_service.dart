import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for managing lazy loading operations
class LazyLoadingService {
  static final LazyLoadingService _instance = LazyLoadingService._internal();
  factory LazyLoadingService() => _instance;
  LazyLoadingService._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache duration in minutes
  static const int _cacheDurationMinutes = 30;

  /// Generic lazy loading method with caching
  Future<T> lazyLoad<T>({
    required String key,
    required Future<T> Function() loader,
    Duration? cacheDuration,
    bool forceRefresh = false,
  }) async {
    // Check if we have a pending request for this key
    if (_pendingRequests.containsKey(key)) {
      return await _pendingRequests[key]!.future as T;
    }

    // Check cache if not forcing refresh
    if (!forceRefresh && _isCacheValid(key, cacheDuration)) {
      return _cache[key] as T;
    }

    // Create a completer for this request
    final completer = Completer<T>();
    _pendingRequests[key] = completer as Completer<dynamic>;

    try {
      final result = await loader();
      
      // Cache the result
      _cache[key] = result;
      _cacheTimestamps[key] = DateTime.now();
      
      // Complete the request
      completer.complete(result);
      
      return result;
    } catch (error) {
      completer.completeError(error);
      rethrow;
    } finally {
      // Remove from pending requests
      _pendingRequests.remove(key);
    }
  }

  /// Check if cached data is still valid
  bool _isCacheValid(String key, Duration? customDuration) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[key]!;
    final duration = customDuration ?? const Duration(minutes: _cacheDurationMinutes);
    
    return DateTime.now().difference(cacheTime) < duration;
  }

  /// Get cached data without loading
  T? getCached<T>(String key) {
    if (_isCacheValid(key, null)) {
      return _cache[key] as T?;
    }
    return null;
  }

  /// Clear specific cache entry
  void clearCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Preload data in background
  Future<void> preload<T>({
    required String key,
    required Future<T> Function() loader,
  }) async {
    if (!_isCacheValid(key, null)) {
      // Load in background without waiting
      unawaited(lazyLoad(key: key, loader: loader));
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalEntries': _cache.length,
      'pendingRequests': _pendingRequests.length,
      'cacheKeys': _cache.keys.toList(),
    };
  }
}

/// Mixin for widgets that need lazy loading capabilities
mixin LazyLoadingMixin<T extends StatefulWidget> on State<T> {
  final LazyLoadingService _lazyLoadingService = LazyLoadingService();
  final Map<String, bool> _loadingStates = {};

  /// Check if a specific key is currently loading
  bool isLoading(String key) => _loadingStates[key] ?? false;

  /// Set loading state for a key
  void setLoading(String key, bool loading) {
    if (mounted) {
      setState(() {
        _loadingStates[key] = loading;
      });
    }
  }

  /// Lazy load data with automatic loading state management
  Future<R> lazyLoadWithState<R>({
    required String key,
    required Future<R> Function() loader,
    Duration? cacheDuration,
    bool forceRefresh = false,
  }) async {
    setLoading(key, true);
    
    try {
      final result = await _lazyLoadingService.lazyLoad<R>(
        key: key,
        loader: loader,
        cacheDuration: cacheDuration,
        forceRefresh: forceRefresh,
      );
      
      return result;
    } finally {
      setLoading(key, false);
    }
  }

  /// Get cached data
  R? getCached<R>(String key) => _lazyLoadingService.getCached<R>(key);

  /// Clear cache for this widget
  void clearWidgetCache() {
    for (final key in _loadingStates.keys) {
      _lazyLoadingService.clearCache(key);
    }
  }
}

/// Pagination helper for lazy loading lists
class PaginationHelper<T> {
  final Future<List<T>> Function(int page, int limit) loader;
  final int pageSize;
  
  List<T> _items = [];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _error;

  PaginationHelper({
    required this.loader,
    this.pageSize = 20,
  });

  List<T> get items => _items;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalItems => _items.length;

  /// Load next page
  Future<void> loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;

    try {
      final newItems = await loader(_currentPage, pageSize);
      
      if (newItems.isEmpty || newItems.length < pageSize) {
        _hasMore = false;
      }
      
      _items.addAll(newItems);
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  /// Refresh from beginning
  Future<void> refresh() async {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    _error = null;
    
    await loadNextPage();
  }

  /// Reset pagination
  void reset() {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
    _error = null;
  }
}

/// Debouncer for search and other frequent operations
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}