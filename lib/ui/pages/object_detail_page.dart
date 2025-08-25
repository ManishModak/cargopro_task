import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/object_controller.dart';
import '../../data/models/object_model.dart';
import 'edit_object_page.dart';

/// ObjectDetailPage (View) displays detailed information about an object
/// Shows reactive updates when object is modified
class ObjectDetailPage extends StatelessWidget {
  final ObjectModel initialObject;

  const ObjectDetailPage({super.key, required this.initialObject});

  @override
  Widget build(BuildContext context) {
    final ObjectController controller = Get.find<ObjectController>();

    // Set the selected object when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.setSelectedObject(initialObject);
    });

    return Obx(() {
      // Use reactive selectedObject from controller, fallback to initial object
      final object = controller.selectedObject ?? initialObject;

      return Scaffold(
        appBar: AppBar(
          title: Text(object.name),
          backgroundColor: Get.theme.colorScheme.primary,
          foregroundColor: Get.theme.colorScheme.onPrimary,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'copy_id':
                    _copyToClipboard(object.id ?? '', 'Object ID copied');
                    break;
                  case 'copy_json':
                    _copyToClipboard(
                      controller.formatJsonForDisplay(object.data),
                      'JSON data copied',
                    );
                    break;
                  case 'refresh':
                    if (object.id != null) {
                      controller.selectObject(object.id!);
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                if (object.id != null)
                  const PopupMenuItem(
                    value: 'copy_id',
                    child: Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 8),
                        Text('Copy ID'),
                      ],
                    ),
                  ),
                if (object.data != null && object.data!.isNotEmpty)
                  const PopupMenuItem(
                    value: 'copy_json',
                    child: Row(
                      children: [
                        Icon(Icons.content_copy),
                        SizedBox(width: 8),
                        Text('Copy JSON'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
              children: [
                _buildBasicInfoCard(object),
                const SizedBox(height: 16),
                _buildDataCard(controller, object),
                const SizedBox(height: 16),
                _buildMetadataCard(object),
                const SizedBox(height: 32),
                _buildActionButtons(object, controller),
                SizedBox(height: kIsWeb ? 40 : 20),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Basic information card
  Widget _buildBasicInfoCard(ObjectModel object) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Get.theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', object.name, Icons.label_outline),
            if (object.id != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'ID',
                object.id!,
                Icons.fingerprint,
                copyable: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Data card showing JSON content
  Widget _buildDataCard(ObjectController controller, ObjectModel object) {
    final hasData = object.data != null && object.data!.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.data_object, color: Get.theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'JSON Data',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (hasData)
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
                      '${object.data!.length} fields',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Get.theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasData) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Get.theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formatted JSON:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      controller.formatJsonForDisplay(object.data),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Get.theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(
                        controller.formatJsonForDisplay(object.data),
                        'JSON data copied to clipboard',
                      ),
                      icon: const Icon(Icons.content_copy, size: 18),
                      label: const Text('Copy JSON'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Get.theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.data_array,
                      size: 48,
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No Data',
                      style: Get.textTheme.titleMedium?.copyWith(
                        color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This object does not contain any additional data fields.',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Metadata card showing object statistics
  Widget _buildMetadataCard(ObjectModel object) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Get.theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Object Statistics',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Data Fields',
                    (object.data?.length ?? 0).toString(),
                    Icons.data_object,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Name Length',
                    '${object.name.length} chars',
                    Icons.text_fields,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Individual stat card
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Get.theme.colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Get.theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Get.textTheme.bodySmall?.copyWith(
              color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Action buttons with Edit and Delete functionality
  Widget _buildActionButtons(ObjectModel object, ObjectController controller) {
    final isUserCreated =
        object.id != null && controller.isUserCreated(object.id!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isUserCreated) ...[
              Text(
                'Edit this object or delete it permanently.',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => ElevatedButton.icon(
                        onPressed:
                            controller.isUpdating || controller.isDeleting
                            ? null
                            : () => _editObject(object),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Get.theme.colorScheme.primary,
                          foregroundColor: Get.theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton.icon(
                        onPressed:
                            controller.isUpdating || controller.isDeleting
                            ? null
                            : () => _deleteObject(controller, object),
                        icon: controller.isDeleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.delete),
                        label: Text(
                          controller.isDeleting ? 'Deleting...' : 'Delete',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Get.theme.colorScheme.error,
                          foregroundColor: Get.theme.colorScheme.onError,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.primaryContainer.withOpacity(
                    0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Get.theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Changes are saved immediately to the API.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Get.theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Get.theme.colorScheme.error,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reserved Object',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Get.theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This is a reserved object (ID 1-13) and cannot be modified or deleted. Create your own objects to enable editing.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Get.theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Navigate to edit page
  void _editObject(ObjectModel object) {
    Get.to(() => EditObjectPage(object: object));
  }

  /// Handle object deletion with confirmation
  Future<void> _deleteObject(
    ObjectController controller,
    ObjectModel object,
  ) async {
    final confirmed = await _showDeleteConfirmationDialog(object);

    if (confirmed && object.id != null) {
      final success = await controller.deleteObject(object.id!);

      if (success) {
        // Return to previous screen after successful deletion
        Get.back();

        // Small delay to ensure navigation is complete, then show success message
        await Future.delayed(const Duration(milliseconds: 100));
        Get.snackbar(
          'Deleted! 🗑️',
          '"${object.name}" deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  /// Shows confirmation dialog before deletion
  Future<bool> _showDeleteConfirmationDialog(ObjectModel object) async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Get.theme.colorScheme.error),
                const SizedBox(width: 8),
                const Text('Confirm Deletion'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Are you sure you want to delete this object?'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Get.theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Object: ${object.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (object.id != null) Text('ID: ${object.id}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    color: Get.theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.theme.colorScheme.error,
                  foregroundColor: Get.theme.colorScheme.onError,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Helper to build info rows
  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    bool copyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (copyable)
          IconButton(
            onPressed: () => _copyToClipboard(value, '$label copied'),
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy $label',
          ),
      ],
    );
  }

  /// Helper to copy text to clipboard
  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied!',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 2),
    );
  }
}
