import 'package:cloud_firestore/cloud_firestore.dart';

/// Driver notification model for real-time alerts
class DriverNotification {
  final String id;
  final String driverId;
  final String type; // 'newOrderAssigned', 'orderCancelled', 'alert', etc.
  final String title;
  final String message;
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String priority; // 'high', 'medium', 'low'
  final List<String>? actions; // ['accept', 'view', 'dismiss']
  final String? actionTaken;
  final DateTime? actionTakenAt;

  DriverNotification({
    required this.id,
    required this.driverId,
    required this.type,
    required this.title,
    required this.message,
    this.orderId,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.priority = 'medium',
    this.actions,
    this.actionTaken,
    this.actionTakenAt,
  });

  factory DriverNotification.fromJson(Map<String, dynamic> json) {
    return DriverNotification(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      orderId: json['orderId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      readAt: json['readAt'] != null ? (json['readAt'] as Timestamp).toDate() : null,
      priority: json['priority'] as String? ?? 'medium',
      actions: json['actions'] != null ? List<String>.from(json['actions']) : null,
      actionTaken: json['actionTaken'] as String?,
      actionTakenAt: json['actionTakenAt'] != null 
          ? (json['actionTakenAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'type': type,
      'title': title,
      'message': message,
      'orderId': orderId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'priority': priority,
      'actions': actions,
      'actionTaken': actionTaken,
      'actionTakenAt': actionTakenAt != null ? Timestamp.fromDate(actionTakenAt!) : null,
    };
  }

  DriverNotification copyWith({
    String? id,
    String? driverId,
    String? type,
    String? title,
    String? message,
    String? orderId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? priority,
    List<String>? actions,
    String? actionTaken,
    DateTime? actionTakenAt,
  }) {
    return DriverNotification(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      priority: priority ?? this.priority,
      actions: actions ?? this.actions,
      actionTaken: actionTaken ?? this.actionTaken,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
    );
  }
}
