import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../models/custom_input.dart';
import '../../../shared/widgets/bouncing_wrapper.dart';

Future<CustomInput?> showCustomInputSheet(
  BuildContext context, {
  CustomInput? initial,
}) {
  return showModalBottomSheet<CustomInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) => _CustomInputSheet(initial: initial),
  );
}

class _CustomInputSheet extends StatefulWidget {
  const _CustomInputSheet({this.initial});

  final CustomInput? initial;

  @override
  State<_CustomInputSheet> createState() => _CustomInputSheetState();
}

class _CustomInputSheetState extends State<_CustomInputSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _valueController = TextEditingController(text: widget.initial?.value ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      CustomInput(
        name: _nameController.text.trim(),
        value: _valueController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEditing = widget.initial != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Signature Nakama-style warm amber curved header
                Container(
                  color: AppColors.sunnyAmber,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 18, AppSpacing.md, 18),
                  child: Row(
                    children: <Widget>[
                      Text(
                        isEditing ? 'Edit Input' : 'Add Input',
                        style: const TextStyle(
                          color: Color(0xFF1E1400),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      BouncingWrapper(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF1E1400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Name',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofocus: !isEditing,
                          decoration: const InputDecoration(hintText: 'e.g. Model'),
                          validator: (String? value) {
                            return (value ?? '').trim().isEmpty
                                ? 'Give this input a name.'
                                : null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Value',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _valueController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Midjourney',
                          ),
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        BouncingWrapper(
                          onTap: _submit,
                          child: FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.sunnyAmber,
                              foregroundColor: const Color(0xFF1E1400),
                              minimumSize: const Size(double.infinity, 52),
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: Text(
                              isEditing ? 'Save' : 'Add',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
