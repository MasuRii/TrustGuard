import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/models/group.dart';
import '../../../ui/theme/app_theme.dart';
import 'groups_providers.dart';

class GroupFormScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const GroupFormScreen({super.key, this.groupId});

  @override
  ConsumerState<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCurrency = 'USD';
  bool _isLoading = false;
  bool _isInitialized = false;

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'INR',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(groupRepositoryProvider);

      if (widget.groupId == null) {
        // Create mode
        final group = Group(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          currencyCode: _selectedCurrency,
          createdAt: DateTime.now(),
        );
        await repository.createGroup(group);
      } else {
        // Edit mode
        final groupAsync = ref.read(groupProvider(widget.groupId!));
        final existingGroup = groupAsync.value;

        if (existingGroup != null) {
          final updatedGroup = existingGroup.copyWith(
            name: _nameController.text.trim(),
            currencyCode: _selectedCurrency,
          );
          await repository.updateGroup(updatedGroup);
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving group: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.groupId != null;

    if (isEdit && !_isInitialized) {
      final groupAsync = ref.watch(groupProvider(widget.groupId!));
      groupAsync.whenData((group) {
        if (group != null) {
          _nameController.text = group.name;
          _selectedCurrency = group.currencyCode;
          _isInitialized = true;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Group' : 'New Group'),
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check),
              tooltip: 'Save',
              constraints: const BoxConstraints(
                minWidth: AppTheme.minTouchTarget,
                minHeight: AppTheme.minTouchTarget,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        hintText: 'e.g. Ski Trip 2026',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a group name';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                      autofocus: !isEdit,
                    ),
                    const SizedBox(height: AppTheme.space24),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: _currencies.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCurrency = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppTheme.space32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.space16,
                        ),
                      ),
                      child: Text(isEdit ? 'Update Group' : 'Create Group'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
