import 'dart:async';

abstract class AppEvent {}
class ProjectCreated extends AppEvent {
  final String projectName;
  final String courseName;
  final List<String> members;   // usernames to notify
  ProjectCreated(this.projectName, this.courseName, this.members);
}
class TaskAssigned extends AppEvent {
  final String taskName;
  final String projectName;
  final String assignee;        // username
  TaskAssigned(this.taskName, this.projectName, this.assignee);
}
class ProofUploaded extends AppEvent {
  final String subtaskName;
  final String projectName;
  final String uploader;        // username who uploaded
  final List<String> reviewers; // usernames to notify
  ProofUploaded(this.subtaskName, this.projectName, this.uploader, this.reviewers);
}

class AppEventBus {
  AppEventBus._();
  static final AppEventBus instance = AppEventBus._();
  final _controller = StreamController<AppEvent>.broadcast();
  Stream<AppEvent> get stream => _controller.stream;
  void fire(AppEvent e) => _controller.add(e);
}
