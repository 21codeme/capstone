import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic pagination service for handling large data sets
class PaginationService<T> {
  final int pageSize;
  final Future<List<T>> Function(int page, int limit, {DocumentSnapshot? lastDocument}) fetchData;
  final T Function(Map<String, dynamic>) fromJson;
  
  List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  DocumentSnapshot? _lastDocument;
  String? _lastError;

  PaginationService({
    required this.fetchData,
    required this.fromJson,
    this.pageSize = 20,
  });

  List<T> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get lastError => _lastError;
  int get totalItems => _items.length;

  /// Load the first page
  Future<void> loadInitial() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _lastError = null;
    _currentPage = 0;
    _items.clear();
    _lastDocument = null;
    _hasMore = true;
    
    try {
      final newItems = await fetchData(0, pageSize);
      _items.addAll(newItems);
      _currentPage = 1;
      _hasMore = newItems.length == pageSize;
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  /// Load the next page
  Future<void> loadNext() async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    _lastError = null;
    
    try {
      final newItems = await fetchData(
        _currentPage, 
        pageSize, 
        lastDocument: _lastDocument,
      );
      
      _items.addAll(newItems);
      _currentPage++;
      _hasMore = newItems.length == pageSize;
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadInitial();
  }

  /// Add a new item to the beginning of the list
  void addItem(T item) {
    _items.insert(0, item);
  }

  /// Remove an item from the list
  void removeItem(T item) {
    _items.remove(item);
  }

  /// Update an item in the list
  void updateItem(T oldItem, T newItem) {
    final index = _items.indexOf(oldItem);
    if (index != -1) {
      _items[index] = newItem;
    }
  }

  /// Clear all data
  void clear() {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    _lastDocument = null;
    _lastError = null;
  }
}

/// Firestore-specific pagination service
class FirestorePaginationService<T> extends PaginationService<T> {
  final Query query;
  final String? orderByField;
  final bool descending;

  FirestorePaginationService({
    required this.query,
    required T Function(Map<String, dynamic>) fromJson,
    this.orderByField,
    this.descending = false,
    int pageSize = 20,
  }) : super(
          fetchData: (page, limit, {lastDocument}) => _fetchFirestoreData<T>(
            query,
            limit,
            lastDocument,
            fromJson,
            orderByField,
            descending,
          ),
          fromJson: fromJson,
          pageSize: pageSize,
        );

  static Future<List<T>> _fetchFirestoreData<T>(
    Query query,
    int limit,
    DocumentSnapshot? lastDocument,
    T Function(Map<String, dynamic>) fromJson,
    String? orderByField,
    bool descending,
  ) async {
    Query paginatedQuery = query;
    
    if (orderByField != null) {
      paginatedQuery = paginatedQuery.orderBy(orderByField, descending: descending);
    }
    
    if (lastDocument != null) {
      paginatedQuery = paginatedQuery.startAfterDocument(lastDocument);
    }
    
    paginatedQuery = paginatedQuery.limit(limit);
    
    final snapshot = await paginatedQuery.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return fromJson(data);
    }).toList();
  }
}

/// Widget for infinite scroll list with pagination
class InfiniteScrollList<T> extends StatefulWidget {
  final PaginationService<T> paginationService;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final RefreshCallback? onRefresh;
  final double loadMoreThreshold;

  const InfiniteScrollList({
    Key? key,
    required this.paginationService,
    required this.itemBuilder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.padding,
    this.scrollController,
    this.onRefresh,
    this.loadMoreThreshold = 200.0,
  }) : super(key: key);

  @override
  State<InfiniteScrollList<T>> createState() => _InfiniteScrollListState<T>();
}

class _InfiniteScrollListState<T> extends State<InfiniteScrollList<T>> {
  late ScrollController _scrollController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await widget.paginationService.loadInitial();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - widget.loadMoreThreshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (widget.paginationService.hasMore && !widget.paginationService.isLoading) {
      await widget.paginationService.loadNext();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _onRefresh() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else {
      await widget.paginationService.refresh();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return widget.loadingWidget ?? 
        const Center(child: CircularProgressIndicator());
    }

    if (widget.paginationService.lastError != null && 
        widget.paginationService.items.isEmpty) {
      return widget.errorWidget ?? 
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${widget.paginationService.lastError}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
    }

    if (widget.paginationService.items.isEmpty) {
      return widget.emptyWidget ?? 
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No items found'),
            ],
          ),
        );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: widget.paginationService.items.length + 
          (widget.paginationService.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.paginationService.items.length) {
            // Loading indicator at the bottom
            return Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: widget.paginationService.isLoading
                ? const CircularProgressIndicator()
                : const SizedBox.shrink(),
            );
          }

          final item = widget.paginationService.items[index];
          return widget.itemBuilder(context, item, index);
        },
      ),
    );
  }
}

/// Grid version of infinite scroll
class InfiniteScrollGrid<T> extends StatefulWidget {
  final PaginationService<T> paginationService;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final RefreshCallback? onRefresh;

  const InfiniteScrollGrid({
    Key? key,
    required this.paginationService,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.padding,
    this.scrollController,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<InfiniteScrollGrid<T>> createState() => _InfiniteScrollGridState<T>();
}

class _InfiniteScrollGridState<T> extends State<InfiniteScrollGrid<T>> {
  late ScrollController _scrollController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await widget.paginationService.loadInitial();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (widget.paginationService.hasMore && !widget.paginationService.isLoading) {
      await widget.paginationService.loadNext();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _onRefresh() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else {
      await widget.paginationService.refresh();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return widget.loadingWidget ?? 
        const Center(child: CircularProgressIndicator());
    }

    if (widget.paginationService.lastError != null && 
        widget.paginationService.items.isEmpty) {
      return widget.errorWidget ?? 
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${widget.paginationService.lastError}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialData,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
    }

    if (widget.paginationService.items.isEmpty) {
      return widget.emptyWidget ?? 
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No items found'),
            ],
          ),
        );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: GridView.builder(
        controller: _scrollController,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          mainAxisSpacing: widget.mainAxisSpacing,
          crossAxisSpacing: widget.crossAxisSpacing,
          childAspectRatio: widget.childAspectRatio,
        ),
        itemCount: widget.paginationService.items.length + 
          (widget.paginationService.hasMore ? widget.crossAxisCount : 0),
        itemBuilder: (context, index) {
          if (index >= widget.paginationService.items.length) {
            // Loading indicators at the bottom
            return Container(
              alignment: Alignment.center,
              child: widget.paginationService.isLoading
                ? const CircularProgressIndicator()
                : const SizedBox.shrink(),
            );
          }

          final item = widget.paginationService.items[index];
          return widget.itemBuilder(context, item, index);
        },
      ),
    );
  }
}