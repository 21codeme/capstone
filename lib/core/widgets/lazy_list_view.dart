import 'package:flutter/material.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'loading_widgets.dart';

/// Lazy loading list view with pagination and infinite scroll
class LazyListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<List<T>> Function(int page)? onLoadMore;
  final VoidCallback? onRefresh;
  final bool hasMore;
  final bool isLoading;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final ScrollController? scrollController;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int loadMoreOffset;
  final Duration refreshIndicatorStrokeWidth;

  const LazyListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.onRefresh,
    this.hasMore = true,
    this.isLoading = false,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.scrollController,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.loadMoreOffset = 100,
    this.refreshIndicatorStrokeWidth = const Duration(milliseconds: 300),
  });

  @override
  State<LazyListView<T>> createState() => _LazyListViewState<T>();
}

class _LazyListViewState<T> extends State<LazyListView<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !widget.hasMore || widget.onLoadMore == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore!(_currentPage + 1);
      _currentPage++;
    } catch (e) {
      // Handle error
      debugPrint('Error loading more items: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    if (widget.onRefresh != null) {
      _currentPage = 1;
      await widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? _buildEmptyWidget();
    }

    Widget listView = LazyLoadScrollView(
      onEndOfPage: _loadMore,
      scrollOffset: widget.loadMoreOffset,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: widget.items.length + (_isLoadingMore || widget.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= widget.items.length) {
            return widget.loadingWidget ?? const ModernLoadingWidget();
          }

          return LazyListItem(
            key: ValueKey('item_$index'),
            child: widget.itemBuilder(context, widget.items[index], index),
          );
        },
      ),
    );

    if (widget.onRefresh != null) {
      listView = RefreshIndicator(
        onRefresh: _onRefresh,
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual list item with visibility detection for lazy loading
class LazyListItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onVisible;
  final VoidCallback? onInvisible;
  final double visibilityFraction;

  const LazyListItem({
    super.key,
    required this.child,
    this.onVisible,
    this.onInvisible,
    this.visibilityFraction = 0.1,
  });

  @override
  State<LazyListItem> createState() => _LazyListItemState();
}

class _LazyListItemState extends State<LazyListItem> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? UniqueKey(),
      onVisibilityChanged: (info) {
        final isVisible = info.visibleFraction >= widget.visibilityFraction;
        
        if (isVisible && !_isVisible) {
          _isVisible = true;
          widget.onVisible?.call();
        } else if (!isVisible && _isVisible) {
          _isVisible = false;
          widget.onInvisible?.call();
        }
      },
      child: widget.child,
    );
  }
}

/// Lazy grid view with staggered loading
class LazyGridView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<List<T>> Function(int page)? onLoadMore;
  final VoidCallback? onRefresh;
  final bool hasMore;
  final bool isLoading;
  final int crossAxisCount;
  final double aspectRatio;
  final double spacing;
  final EdgeInsets? padding;
  final ScrollController? scrollController;

  const LazyGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.onRefresh,
    this.hasMore = true,
    this.isLoading = false,
    this.crossAxisCount = 2,
    this.aspectRatio = 1.0,
    this.spacing = 8.0,
    this.padding,
    this.scrollController,
  });

  @override
  State<LazyGridView<T>> createState() => _LazyGridViewState<T>();
}

class _LazyGridViewState<T> extends State<LazyGridView<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !widget.hasMore || widget.onLoadMore == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore!(_currentPage + 1);
      _currentPage++;
    } catch (e) {
      debugPrint('Error loading more items: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LazyLoadScrollView(
      onEndOfPage: _loadMore,
      child: GridView.builder(
        controller: _scrollController,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          aspectRatio: widget.aspectRatio,
          crossAxisSpacing: widget.spacing,
          mainAxisSpacing: widget.spacing,
        ),
        itemCount: widget.items.length + (_isLoadingMore ? widget.crossAxisCount : 0),
        itemBuilder: (context, index) {
          if (index >= widget.items.length) {
            return const SkeletonCard();
          }

          return LazyListItem(
            key: ValueKey('grid_item_$index'),
            child: widget.itemBuilder(context, widget.items[index], index),
          );
        },
      ),
    );
  }
}

/// Lazy sliver list for use in CustomScrollView
class LazySliverList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<List<T>> Function(int page)? onLoadMore;
  final bool hasMore;
  final bool isLoading;

  const LazySliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = true,
    this.isLoading = false,
  });

  @override
  State<LazySliverList<T>> createState() => _LazySliverListState<T>();
}

class _LazySliverListState<T> extends State<LazySliverList<T>> {
  bool _isLoadingMore = false;
  int _currentPage = 1;

  Future<void> _loadMore() async {
    if (_isLoadingMore || !widget.hasMore || widget.onLoadMore == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore!(_currentPage + 1);
      _currentPage++;
    } catch (e) {
      debugPrint('Error loading more items: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= widget.items.length) {
            if (widget.hasMore && !_isLoadingMore) {
              _loadMore();
            }
            return const ModernLoadingWidget();
          }

          return LazyListItem(
            key: ValueKey('sliver_item_$index'),
            child: widget.itemBuilder(context, widget.items[index], index),
          );
        },
        childCount: widget.items.length + (_isLoadingMore || widget.isLoading ? 1 : 0),
      ),
    );
  }
}

/// Lazy horizontal list view
class LazyHorizontalListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double height;
  final EdgeInsets? padding;
  final double spacing;

  const LazyHorizontalListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.height = 200,
    this.padding,
    this.spacing = 8.0,
  });

  @override
  State<LazyHorizontalListView<T>> createState() => _LazyHorizontalListViewState<T>();
}

class _LazyHorizontalListViewState<T> extends State<LazyHorizontalListView<T>> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        itemCount: widget.items.length,
        separatorBuilder: (context, index) => SizedBox(width: widget.spacing),
        itemBuilder: (context, index) {
          return LazyListItem(
            key: ValueKey('horizontal_item_$index'),
            child: widget.itemBuilder(context, widget.items[index], index),
          );
        },
      ),
    );
  }
}

/// Lazy search list with debounced search
class LazySearchListView<T> extends StatefulWidget {
  final Future<List<T>> Function(String query, int page) onSearch;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String hintText;
  final Duration searchDelay;
  final Widget? emptyWidget;
  final Widget? loadingWidget;

  const LazySearchListView({
    super.key,
    required this.onSearch,
    required this.itemBuilder,
    this.hintText = 'Search...',
    this.searchDelay = const Duration(milliseconds: 500),
    this.emptyWidget,
    this.loadingWidget,
  });

  @override
  State<LazySearchListView<T>> createState() => _LazySearchListViewState<T>();
}

class _LazySearchListViewState<T> extends State<LazySearchListView<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _currentQuery) {
      _currentQuery = query;
      _currentPage = 1;
      _items.clear();
      _hasMore = true;
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await widget.onSearch(_currentQuery, _currentPage);
      setState(() {
        if (_currentPage == 1) {
          _items = results;
        } else {
          _items.addAll(results);
        }
        _hasMore = results.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<T>> _loadMore(int page) async {
    _currentPage = page;
    await _performSearch();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: LazyListView<T>(
            items: _items,
            itemBuilder: widget.itemBuilder,
            onLoadMore: _loadMore,
            hasMore: _hasMore,
            isLoading: _isLoading,
            loadingWidget: widget.loadingWidget,
            emptyWidget: widget.emptyWidget,
          ),
        ),
      ],
    );
  }
}