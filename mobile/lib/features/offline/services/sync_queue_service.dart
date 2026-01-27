import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages offline data synchronization queue
class SyncQueueService {
  static const String _queueKey = 'offline_sync_queue';

  final SharedPreferences _prefs;

  SyncQueueService(this._prefs);

  /// Add an operation to the sync queue
  Future<void> addToQueue(SyncOperation operation) async {
    final queue = await getQueue();
    queue.add(operation);
    await _saveQueue(queue);
    debugPrint(
      '📥 Added to sync queue: ${operation.type} (${queue.length} items)',
    );
  }

  /// Get all pending operations
  Future<List<SyncOperation>> getQueue() async {
    final jsonString = _prefs.getString(_queueKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => SyncOperation.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Error parsing sync queue: $e');
      return [];
    }
  }

  /// Remove an operation from queue (after successful sync)
  Future<void> removeFromQueue(String operationId) async {
    final queue = await getQueue();
    queue.removeWhere((op) => op.id == operationId);
    await _saveQueue(queue);
  }

  /// Clear all operations from queue
  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    final queue = await getQueue();
    return queue.length;
  }

  Future<void> _saveQueue(List<SyncOperation> queue) async {
    final jsonString = json.encode(queue.map((e) => e.toJson()).toList());
    await _prefs.setString(_queueKey, jsonString);
  }
}

/// Represents an operation to be synced when online
class SyncOperation {
  final String id;
  final SyncOperationType type;
  final String endpoint;
  final String method;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final int retryCount;

  SyncOperation({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.method,
    this.data,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.byName(json['type'] as String),
      endpoint: json['endpoint'] as String,
      method: json['method'] as String,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'endpoint': endpoint,
    'method': method,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  SyncOperation copyWith({int? retryCount}) {
    return SyncOperation(
      id: id,
      type: type,
      endpoint: endpoint,
      method: method,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

enum SyncOperationType {
  createParcelle,
  updateParcelle,
  deleteParcelle,
  createDiagnostic,
  createMesure,
  updateProfile,
  createMessage,
  other,
}
