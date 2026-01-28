import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/models/tag.dart';
import '../../../core/models/tag_with_usage.dart';
import '../../../ui/components/empty_state.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';

class TagsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const TagsScreen({super.key, required this.groupId});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  List<TagWithUsage>? _localTags;

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_localTags == null) return;

    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _localTags!.removeAt(oldIndex);
      _localTags!.insert(newIndex, item);
    });

    HapticsService.lightTap();

    final tagIds = _localTags!.map((t) => t.tag.id).toList();
    try {
      await ref
          .read(tagRepositoryProvider)
          .updateTagOrder(widget.groupId, tagIds);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating order: $e')));
        // Re-invalidate to get correct order from DB
        ref.invalidate(tagsWithUsageProvider(widget.groupId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsWithUsageAsync = ref.watch(tagsWithUsageProvider(widget.groupId));

    ref.listen(tagsWithUsageProvider(widget.groupId), (prev, next) {
      next.whenData((tags) {
        setState(() {
          _localTags = List.from(tags);
        });
      });
    });

    // Initial population
    if (_localTags == null && tagsWithUsageAsync.hasValue) {
      _localTags = List.from(tagsWithUsageAsync.value!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tags')),
      body: tagsWithUsageAsync.when(
        data: (tags) {
          final displayList = _localTags ?? tags;

          if (displayList.isEmpty) {
            return EmptyState(
              svgPath: 'assets/illustrations/no_results.svg',
              icon: Icons.label_off_outlined,
              title: 'No tags',
              message: 'Create tags to categorize your expenses and transfers.',
              actionLabel: 'Add Tag',
              onActionPressed: () => _showTagDialog(context),
            );
          }

          final canReorder = displayList.length > 1;

          if (canReorder) {
            return ReorderableListView.builder(
              onReorder: _onReorder,
              buildDefaultDragHandles: false,
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final item = displayList[index];
                return _buildTagTile(item, index, canReorder: true);
              },
            );
          }

          return ListView.builder(
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final item = displayList[index];
              return _buildTagTile(item, index, canReorder: false);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTagDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTagTile(
    TagWithUsage item,
    int index, {
    required bool canReorder,
  }) {
    return ListTile(
      key: ValueKey(item.tag.id),
      leading: const Icon(Icons.label_outlined),
      title: Text(item.tag.name),
      subtitle: Text('${item.usageCount} transactions'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showTagDialog(context, existingTag: item.tag),
            constraints: const BoxConstraints(
              minWidth: AppTheme.minTouchTarget,
              minHeight: AppTheme.minTouchTarget,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, item.tag),
            constraints: const BoxConstraints(
              minWidth: AppTheme.minTouchTarget,
              minHeight: AppTheme.minTouchTarget,
            ),
          ),
          if (canReorder)
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  void _showTagDialog(BuildContext context, {Tag? existingTag}) {
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
                    Tag(
                      id: const Uuid().v4(),
                      groupId: widget.groupId,
                      name: name,
                    ),
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

  void _confirmDelete(BuildContext context, Tag tag) {
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
