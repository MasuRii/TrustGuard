import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/models/tag.dart';
import '../../../ui/components/empty_state.dart';

class TagsScreen extends ConsumerWidget {
  final String groupId;

  const TagsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsWithUsageAsync = ref.watch(tagsWithUsageProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tags')),
      body: tagsWithUsageAsync.when(
        data: (tags) => tags.isEmpty
            ? EmptyState(
                icon: Icons.label_off_outlined,
                title: 'No tags',
                message:
                    'Create tags to categorize your expenses and transfers.',
                actionLabel: 'Add Tag',
                onActionPressed: () => _showTagDialog(context, ref),
              )
            : ListView.separated(
                itemCount: tags.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = tags[index];
                  return ListTile(
                    leading: const Icon(Icons.label_outlined),
                    title: Text(item.tag.name),
                    subtitle: Text('${item.usageCount} transactions'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showTagDialog(
                            context,
                            ref,
                            existingTag: item.tag,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _confirmDelete(context, ref, item.tag),
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTagDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTagDialog(BuildContext context, WidgetRef ref, {Tag? existingTag}) {
    final nameController = TextEditingController(text: existingTag?.name ?? '');
    final isEditing = existingTag != null;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Tag' : 'New Tag'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Tag Name',
            hintText: 'e.g., Food, Travel',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final repo = ref.read(tagRepositoryProvider);
              try {
                if (existingTag != null) {
                  await repo.updateTag(existingTag.copyWith(name: name));
                } else {
                  await repo.createTag(
                    Tag(id: const Uuid().v4(), groupId: groupId, name: name),
                  );
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Tag tag) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag?'),
        content: Text(
          'Are you sure you want to delete "${tag.name}"? '
          'It will be removed from all transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(tagRepositoryProvider).deleteTag(tag.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
