import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/object_controller.dart';
import '../../data/models/object_model.dart';

/// EditObjectPage (View) provides a form to edit existing objects
/// This is the View layer that delegates object updating to ObjectController
class EditObjectPage extends StatefulWidget {
  final ObjectModel object;

  const EditObjectPage({super.key, required this.object});

  @override
  State<EditObjectPage> createState() => _EditObjectPageState();
}

class _EditObjectPageState extends State<EditObjectPage> {
  final ObjectController _controller = Get.find<ObjectController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dataController;

  bool _isDataExpanded = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing object data
    _nameController = TextEditingController(text: widget.object.name);
    _dataController = TextEditingController(
      text: widget.object.data != null
          ? _controller.formatJsonForDisplay(widget.object.data)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Object'),
        backgroundColor: Get.theme.colorScheme.primary,
        foregroundColor: Get.theme.colorScheme.onPrimary,
        actions: [
          Obx(
            () => _controller.isUpdating
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _updateObject,
                    child: const Text(
                      'UPDATE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
              children: [
                _buildObjectInfoCard(),
                const SizedBox(height: 24),
                _buildNameField(),
                const SizedBox(height: 24),
                _buildDataField(),
                const SizedBox(height: 32),
                _buildUpdateButton(),
                const SizedBox(height: 16),
                _buildJsonHelp(),
                SizedBox(height: kIsWeb ? 40 : 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Object information card
  Widget _buildObjectInfoCard() {
    return Card(
      color: Get.theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_outlined, color: Get.theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Editing Object',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Get.theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.object.id != null) ...[
              Text(
                'Object ID: ${widget.object.id}',
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Modify the fields below and click UPDATE to save changes.',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Name input field
  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Object Name *',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Enter object name',
            prefixIcon: const Icon(Icons.label_outline),
            suffixIcon: _nameController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _nameController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an object name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters long';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  /// Data field with JSON validation
  Widget _buildDataField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Data (JSON)',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Optional',
                style: TextStyle(
                  fontSize: 12,
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _isDataExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () =>
                  setState(() => _isDataExpanded = !_isDataExpanded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isDataExpanded ? 250 : 150,
          child: TextFormField(
            controller: _dataController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: _controller.getExampleJsonHint(),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.data_object),
              ),
              suffixIcon: _dataController.text.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _dataController.clear();
                          setState(() {});
                        },
                      ),
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return null; // Optional field
              }

              if (!_controller.isValidJson(value)) {
                return 'Please enter valid JSON format';
              }

              return null;
            },
            onChanged: (value) => setState(() {}),
          ),
        ),
        if (_dataController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _controller.isValidJson(_dataController.text)
                    ? Icons.check_circle
                    : Icons.error,
                size: 16,
                color: _controller.isValidJson(_dataController.text)
                    ? Colors.green
                    : Get.theme.colorScheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                _controller.isValidJson(_dataController.text)
                    ? 'Valid JSON format'
                    : 'Invalid JSON format',
                style: TextStyle(
                  fontSize: 12,
                  color: _controller.isValidJson(_dataController.text)
                      ? Colors.green
                      : Get.theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Update button
  Widget _buildUpdateButton() {
    return Obx(
      () => ElevatedButton(
        onPressed: _controller.isUpdating ? null : _updateObject,
        style: ElevatedButton.styleFrom(
          backgroundColor: Get.theme.colorScheme.primary,
          foregroundColor: Get.theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _controller.isUpdating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Updating...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.update),
                  SizedBox(width: 8),
                  Text(
                    'Update Object',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  /// JSON help section
  Widget _buildJsonHelp() {
    return ExpansionTile(
      leading: Icon(Icons.help_outline, color: Get.theme.colorScheme.primary),
      title: Text(
        'JSON Format Help',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Get.theme.colorScheme.primary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Valid JSON Examples:',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildJsonExample('Simple object', '''{
  "color": "red",
  "size": "large"
}'''),
              _buildJsonExample('With numbers', '''{
  "price": 299.99,
  "quantity": 5
}'''),
              _buildJsonExample('With array', '''{
  "tags": ["electronics", "mobile"],
  "available": true
}'''),
              const SizedBox(height: 8),
              Text(
                'Rules:',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Use double quotes for strings\n• No trailing commas\n• Valid data types: string, number, boolean, array, object',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// JSON example widget
  Widget _buildJsonExample(String title, String json) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Get.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Get.theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Text(
              json,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Get.theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Updates the object
  Future<void> _updateObject() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final name = _nameController.text.trim();
    final jsonData = _dataController.text.trim();

    // Parse JSON data
    final data = jsonData.isNotEmpty
        ? _controller.parseJsonData(jsonData)
        : null;

    final updatedObject = ObjectModel(
      id: widget.object.id,
      name: name,
      data: data,
    );

    if (widget.object.id != null) {
      final success = await _controller.updateObject(
        widget.object.id!,
        updatedObject,
      );

      if (success) {
        // Navigate back first, then show snackbar on destination screen
        Get.back(); // Return to previous screen

        // Small delay to ensure navigation is complete, then show success message
        await Future.delayed(const Duration(milliseconds: 100));
        Get.snackbar(
          'Updated! ✅',
          '"${updatedObject.name}" updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }
}
