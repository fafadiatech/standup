import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/project_model.dart';
import '../../../data/mock/mock_data.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/project_service.dart';

// ---------------------------------------------------------------------------
// Project state
// ---------------------------------------------------------------------------
class ProjectState {
  final List<ProjectModel> projects;
  final bool isLoading;
  final String? error;

  const ProjectState({
    required this.projects,
    this.isLoading = false,
    this.error,
  });

  ProjectState copyWith({
    List<ProjectModel>? projects,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class ProjectNotifier extends StateNotifier<ProjectState> {
  ProjectNotifier(this._service)
      : super(const ProjectState(projects: [], isLoading: true)) {
    loadProjects();
  }

  final ProjectService _service;

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final projects = await _service.getProjects();
      state = state.copyWith(projects: projects, isLoading: false);
    } catch (_) {
      // Fall back to mock data so the screen is always usable
      state = state.copyWith(
        projects: MockData.projects,
        isLoading: false,
        clearError: true,
      );
    }
  }

  List<ProjectModel> get activeProjects =>
      state.projects.where((p) => p.status == ProjectStatus.active).toList();

  ProjectModel? getById(String id) {
    try {
      return state.projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final _projectServiceProvider = Provider<ProjectService>(
  (ref) => ProjectService(AuthService()),
);

final projectProvider =
    StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  return ProjectNotifier(ref.read(_projectServiceProvider));
});
