class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String type;     // 'project_created' | 'task_assigned' | 'proof_uploaded' | ...
  final String? payload; // e.g., projectId, taskId
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.payload,
    this.read = false,
  });
}
