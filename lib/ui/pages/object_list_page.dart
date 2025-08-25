import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/object_controller.dart';
import '../../data/models/object_model.dart';
import 'add_object_page.dart';
import 'object_detail_page.dart';

/// ObjectListPage (View) displays all objects from the API
/// This is the View layer that shows object data managed by ObjectController
class ObjectListPage extends StatefulWidget {
  const ObjectListPage({super.key});

  @override
  State<ObjectListPage> createState() => _ObjectListPageState();
}

class _ObjectListPageState extends State<ObjectListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final controller = Get.find<ObjectController>();
      if (controller.hasMoreData && !controller.isLoadingMore) {
        controller.loadMoreObjects();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ObjectController controller = Get.find<ObjectController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Objects'),
        backgroundColor: Get.theme.colorScheme.primary,
        foregroundColor: Get.theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => const AddObjectPage()),
            tooltip: 'Create Object',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshObjects(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() => _buildBody(controller)),
      // Remove FAB - pagination will be handled at the bottom
    );
  }

  /// Builds the main body based on current state
  Widget _buildBody(ObjectController controller) {
    if (controller.isLoading) {
      return _buildLoadingState();
    }

    if (controller.hasError) {
      return _buildErrorState(controller);
    }

    if (controller.isEmpty) {
      return _buildEmptyState(controller);
    }

    return _buildObjectList(controller);
  }

  /// Loading state with shimmer effect
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Get.theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading objects...',
            style: Get.textTheme.bodyLarge?.copyWith(
              color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Error state with retry button
  Widget _buildErrorState(ObjectController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Get.theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Objects',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Get.theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.fetchObjects(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Get.theme.colorScheme.primary,
                foregroundColor: Get.theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state when no objects are available
  Widget _buildEmptyState(ObjectController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Get.theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Objects Found',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Get.theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no objects in the API yet.\nCreate your first object to get started!',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => const AddObjectPage()),
              icon: const Icon(Icons.add),
              label: const Text('Create First Object'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Get.theme.colorScheme.primary,
                foregroundColor: Get.theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => controller.refreshObjects(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  /// Object list with pull-to-refresh
  Widget _buildObjectList(ObjectController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshObjects(),
      color: Get.theme.colorScheme.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
                  itemCount:
                      controller.objects.length +
                      (controller.hasMoreData ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == controller.objects.length) {
                      // Show load more button or loading indicator
                      return _buildLoadMoreSection(controller);
                    }
                    final object = controller.objects[index];
                    return _buildObjectCard(object);
                  },
                ),
              ),
              // Pagination info at the bottom
              if (controller.objects.isNotEmpty)
                _buildPaginationInfo(controller),
            ],
          ),
        ),
      ),
    );
  }

  /// Load more section with button or loading indicator
  Widget _buildLoadMoreSection(ObjectController controller) {
    if (controller.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Get.theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading more objects...',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.hasMoreData) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ElevatedButton.icon(
            onPressed: () => controller.loadMoreObjects(),
            icon: const Icon(Icons.expand_more),
            label: const Text('Load More'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.primary,
              foregroundColor: Get.theme.colorScheme.onPrimary,
            ),
          ),
        ),
      );
    }

    // End of list indicator
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 32,
              color: Get.theme.colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 8),
            Text(
              'All objects loaded',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You\'ve reached the end of the list',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pagination information display
  Widget _buildPaginationInfo(ObjectController controller) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Get.theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous page (compact)
              IconButton(
                onPressed: controller.currentPage > 1
                    ? () => controller.goToPage(controller.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),

              // Center compact page label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Page ${controller.currentPage}/${controller.totalPages}',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isNarrow && controller.isLoadingMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Get.theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Next page (compact)
              IconButton(
                onPressed: controller.hasMoreData
                    ? () => controller.loadMoreObjects()
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          );
        },
      ),
    );
  }

  /// Individual object card
  Widget _buildObjectCard(ObjectModel object) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => Get.to(() => ObjectDetailPage(initialObject: object)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      object.name,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (object.id != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ID: ${object.id}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Get.theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                object.dataString,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.data_object,
                    size: 16,
                    color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    object.data?.length.toString() ?? '0',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    ' data fields',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Get.theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
