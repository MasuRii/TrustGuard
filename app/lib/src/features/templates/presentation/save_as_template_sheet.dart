import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/models/expense.dart' as model;
import '../../../core/models/expense_template.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/haptics.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/animations/shake_widget.dart';
import '../../transactions/models/expense_form_data.dart';

class SaveAsTemplateSheet extends ConsumerStatefulWidget {
  final String groupId;
  final ExpenseFormData initialData;
  final String? existingTemplateId;

  const SaveAsTemplateSheet({
    super.key,
    required this.groupId,
    required this.initialData,
    this.existingTemplateId,
  });

  @override
  ConsumerState<SaveAsTemplateSheet> createState() =>
      _SaveAsTemplateSheetState();
}

class _SaveAsTemplateSheetState extends ConsumerState<SaveAsTemplateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _saveButtonKey = GlobalKey<ShakeWidgetState>();

  bool _saveAmount = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.initialData.description;

    if (widget.existingTemplateId != null) {
      _nameController.text = widget.initialData.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _saveButtonKey.currentState?.shake();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(templateRepositoryProvider);
      final existingTemplates = await repository.getTemplatesByGroup(
        widget.groupId,
      );

      final name = _nameController.text.trim();

      final duplicate = existingTemplates.any(
        (t) =>
            t.name.toLowerCase() == name.toLowerCase() &&
            t.id != widget.existingTemplateId,
      );

      if (duplicate) {
        _saveButtonKey.currentState?.shake();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A template with this name already exists'),
            ),
          );
        }
        return;
      }

      final now = DateTime.now();
      final totalAmountMinor = MoneyUtils.toMinorUnits(
        widget.initialData.amount,
      );

      final Map<String, int> participantData = {};
      if (widget.initialData.splitType == model.SplitType.custom &&
          widget.initialData.customAmounts != null) {
        widget.initialData.customAmounts!.forEach((key, value) {
          participantData[key] = MoneyUtils.toMinorUnits(value);
        });
      }

      SplitType templateSplitType;
      switch (widget.initialData.splitType) {
        case model.SplitType.equal:
          templateSplitType = SplitType.equal;
          break;
        case model.SplitType.custom:
          if (widget.initialData.customSplitMode ==
              CustomSplitMode.percentage) {
            templateSplitType = SplitType.percentage;
          } else {
            templateSplitType = SplitType.custom;
          }
          break;
      }

      final template = ExpenseTemplate(
        id: widget.existingTemplateId ?? const Uuid().v4(),
        groupId: widget.groupId,
        name: name,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        amountMinor: _saveAmount ? totalAmountMinor : null,
        currencyCode: widget.initialData.currencyCode,
        payerId: widget.initialData.payerId ?? '',
        splitType: templateSplitType,
        participantData: participantData.isNotEmpty ? participantData : null,
        tagIds: widget.initialData.tagIds,
        orderIndex: 0,
        createdAt: now,
        usageCount: 0,
      );

      if (widget.existingTemplateId != null) {
        await repository.updateTemplate(template);
      } else {
        await repository.createTemplate(template);
      }

      HapticsService.success();
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingTemplateId != null
                  ? 'Template updated'
                  : 'Template saved',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving template: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Text(
                    widget.existingTemplateId != null
                        ? 'Edit Template'
                        : 'Save as Template',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),
              Semantics(
                label: 'Template Name',
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Template Name',
                    hintText: 'e.g., Grocery Run, Rent',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Semantics(
                label: 'Default Description',
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Default Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              SwitchListTile(
                title: const Text('Save Amount'),
                subtitle: Text(
                  _saveAmount
                      ? 'Amount will be pre-filled (${widget.initialData.currencyCode} ${widget.initialData.amount.toStringAsFixed(2)})'
                      : 'You will be prompted for amount each time',
                ),
                value: _saveAmount,
                onChanged: (value) => setState(() => _saveAmount = value),
              ),
              const SizedBox(height: AppTheme.space24),
              Text('Preview', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppTheme.space8),
              _buildPreviewCard(context),
              const SizedBox(height: AppTheme.space32),
              ShakeWidget(
                key: _saveButtonKey,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Template'),
                ),
              ),
              const SizedBox(height: AppTheme.space16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final participantsCount = widget.initialData.participantIds.length;
    final tagsCount = widget.initialData.tagIds.length;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _saveAmount
                        ? '${widget.initialData.currencyCode} ${widget.initialData.amount.toStringAsFixed(2)}'
                        : 'Variable Amount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '$participantsCount participant${participantsCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.label_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '$tagsCount tag${tagsCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.call_split,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.initialData.splitType == model.SplitType.equal
                      ? 'Split Equally'
                      : 'Custom Split',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
