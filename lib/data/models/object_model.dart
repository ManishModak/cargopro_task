/// Data model representing an object from the REST API
///
/// This model matches the API response structure from https://api.restful-api.dev/objects
/// Example API response:
/// {
///   "id": "object_id",
///   "name": "object name",
///   "data": { "key1": "value1", "key2": "value2", ... }
/// }
class ObjectModel {
  final String? id;
  final String name;
  final Map<String, dynamic>? data;

  ObjectModel({this.id, required this.name, this.data});

  /// Creates an ObjectModel from JSON response
  factory ObjectModel.fromJson(Map<String, dynamic> json) {
    return ObjectModel(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  /// Converts ObjectModel to JSON for API requests
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'name': name};

    if (data != null && data!.isNotEmpty) {
      json['data'] = data;
    }

    // Only include id for updates, not for creation
    if (id != null) {
      json['id'] = id;
    }

    return json;
  }

  /// Creates a copy of this ObjectModel with updated fields
  ObjectModel copyWith({String? id, String? name, Map<String, dynamic>? data}) {
    return ObjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return 'ObjectModel(id: $id, name: $name, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ObjectModel &&
        other.id == id &&
        other.name == name &&
        _mapEquals(other.data, data);
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ data.hashCode;

  /// Helper method to compare maps
  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  /// Gets a formatted string representation of the data field
  String get dataString {
    if (data == null || data!.isEmpty) return 'No additional data';
    return data!.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }

  /// Validates if the object has required fields
  bool get isValid {
    return name.isNotEmpty;
  }
}
