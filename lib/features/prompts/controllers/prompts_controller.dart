import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/prompt_repository.dart';
import '../../../models/prompt.dart';

class PromptsController extends ChangeNotifier {
  PromptsController(this._repository);

  static const Duration _searchDebounce = Duration(milliseconds: 180);

  final PromptRepository _repository;

  List<Prompt> _prompts = const <Prompt>[];
  String _query = '';
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _debounce;
  int _requestId = 0;

  List<Prompt> get prompts => _prompts;

  String get query => _query;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isSearching => _query.trim().isNotEmpty;

  bool get hasPrompts => _prompts.isNotEmpty;

  Future<void> load() async {
    final int requestId = ++_requestId;
    try {
      final List<Prompt> result = await _repository.fetchAll(query: _query);
      if (requestId != _requestId) {
        return;
      }
      _prompts = result;
      _errorMessage = null;
    } on PromptRepositoryException catch (error) {
      if (requestId != _requestId) {
        return;
      }
      _errorMessage = error.message;
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void search(String query) {
    if (query == _query) {
      return;
    }
    _query = query;
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, load);
  }

  void clearSearch() => search('');

  Future<Prompt?> findById(String id) => _repository.findById(id);

  Future<void> save(Prompt prompt) async {
    await _repository.save(prompt);
    await load();
  }

  Future<void> delete(Prompt prompt) async {
    await _repository.delete(prompt);
    await load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
