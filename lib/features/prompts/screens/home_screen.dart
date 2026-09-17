import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/repositories/prompt_repository.dart';
import '../../../models/prompt.dart';
import '../../../shared/widgets/adaptive_body.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../prompt_editor/widgets/new_group_sheet.dart';
import '../controllers/groups_controller.dart';
import '../controllers/prompts_controller.dart';
import '../widgets/group_filter_bar.dart';
import '../widgets/prompt_card.dart';
import '../widgets/prompt_search_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<PromptsController>().query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<PromptsController>().clearSearch();
  }

  Future<void> _copyPrompt(Prompt prompt) async {
    await HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: prompt.previewVersion?.promptText ?? ''));
    if (mounted) {
      showAppSnackBar(context, 'Prompt copied');
    }
  }

  Future<void> _createGroup() async {
    await showNewGroupSheet(context);
  }

  Future<void> _openPromptDetails(Prompt prompt) async {
    final String? groupId = await AppRouter.openPromptDetails(context, prompt);
    if (groupId != null && mounted) {
      context.read<PromptsController>().filterByGroup(groupId);
    }
  }

  Future<void> _editPrompt(Prompt prompt) async {
    final bool saved = await AppRouter.openPromptEditor(context, prompt: prompt);
    if (saved && mounted) {
      showAppSnackBar(context, 'Prompt updated');
    }
  }

  Future<void> _deletePrompt(Prompt prompt) async {
    final bool confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Prompt?',
      highlight: prompt.title,
      message: 'This prompt and its images will be deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await context.read<PromptsController>().delete(prompt);
      if (mounted) {
        showAppSnackBar(context, 'Prompt deleted');
      }
    } on PromptRepositoryException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.message, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Text(
          'Prompts',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 26,
            color: isDark ? null : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: AdaptiveBody(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: PromptSearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: context.read<PromptsController>().search,
                  onClear: _clearSearch,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Consumer2<GroupsController, PromptsController>(
                  builder: (
                    BuildContext context,
                    GroupsController groupsController,
                    PromptsController promptsController,
                    Widget? child,
                  ) {
                    if (groupsController.groups.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return GroupFilterBar(
                      groups: groupsController.groups,
                      selectedGroupId: promptsController.groupFilter,
                      onSelect: promptsController.filterByGroup,
                      onCreate: _createGroup,
                    );
                  },
                ),
              ),
              Expanded(
                child: Consumer<PromptsController>(
                  builder: (
                    BuildContext context,
                    PromptsController controller,
                    Widget? child,
                  ) {
                    return _PromptsContent(
                      controller: controller,
                      onOpenDetails: _openPromptDetails,
                      onEdit: _editPrompt,
                      onDelete: _deletePrompt,
                      onCopy: _copyPrompt,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptsContent extends StatelessWidget {
  const _PromptsContent({
    required this.controller,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
  });

  final PromptsController controller;
  final ValueChanged<Prompt> onOpenDetails;
  final ValueChanged<Prompt> onEdit;
  final ValueChanged<Prompt> onDelete;
  final ValueChanged<Prompt> onCopy;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.electricBlue,
          strokeWidth: 3,
        ),
      );
    }

    final String? errorMessage = controller.errorMessage;
    if (errorMessage != null) {
      return EmptyStateView(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        message: errorMessage,
        action: FilledButton(
          onPressed: controller.load,
          child: const Text('Try again'),
        ),
      );
    }

    if (!controller.hasPrompts) {
      if (controller.isSearching) {
        return const EmptyStateView(
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: 'No prompts match your search.',
        );
      }
      return EmptyStateView(
        icon: Icons.auto_awesome_rounded,
        title: 'No prompts yet',
        message: 'Save your first prompt and keep your AI creations organized.',
        action: FilledButton.icon(
          onPressed: () => AppRouter.createPrompt(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.sunnyAmber,
            foregroundColor: const Color(0xFF1E1400),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Create Prompt'),
        ),
      );
    }

    final List<Prompt> prompts = controller.prompts;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: prompts.length,
      itemBuilder: (BuildContext context, int index) {
        final Prompt prompt = prompts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: PromptCard(
            key: ValueKey<String>(prompt.id),
            prompt: prompt,
            onOpen: () => onOpenDetails(prompt),
            onEdit: () => onEdit(prompt),
            onDelete: () => onDelete(prompt),
            onCopy: () => onCopy(prompt),
          ),
        );
      },
    );
  }
}
