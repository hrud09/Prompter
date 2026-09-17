import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/prompt_group_repository.dart';
import '../../../models/prompt_group.dart';

class GroupsController extends ChangeNotifier {
  GroupsController(this._repository);

  final PromptGroupRepository _repository;

  List<PromptGroup> _groups = const <PromptGroup>[];
  bool _isLoading = true;
  String? _errorMessage;

  List<PromptGroup> get groups => _groups;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    try {
      _groups = await _repository.fetchAll();
      _errorMessage = null;
    } on PromptGroupRepositoryException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PromptGroup> create(String name) async {
    final DateTime now = DateTime.now();
    final PromptGroup group = PromptGroup(
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _repository.save(group);
    await load();
    return group;
  }

  Future<void> rename(PromptGroup group, String name) async {
    await _repository.save(group.copyWith(name: name.trim(), updatedAt: DateTime.now()));
    await load();
  }

  Future<void> delete(PromptGroup group) async {
    await _repository.delete(group);
    await load();
  }
}
