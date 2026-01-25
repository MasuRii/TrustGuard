import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/models/member.dart';
import '../../../ui/theme/app_theme.dart';
import 'groups_providers.dart';

class MembersScreen extends ConsumerStatefulWidget {
  final String groupId;

  const MembersScreen({super.key, required this.groupId});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final repository = ref.read(memberRepositoryProvider);

    try {
      final member = Member(
        id: const Uuid().v4(),
        groupId: widget.groupId,
        displayName: name,
        createdAt: DateTime.now(),
      );
      await repository.createMember(member);
      _nameController.clear();
      setState(() => _isAdding = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding member: $e')));
      }
    }
  }

  Future<void> _removeMember(Member member) async {
    final repository = ref.read(memberRepositoryProvider);
    try {
      await repository.softDeleteMember(member.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.displayName} removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => repository.undoSoftDeleteMember(member.id),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing member: $e')));
      }
    }
  }

  Future<void> _restoreMember(Member member) async {
    final repository = ref.read(memberRepositoryProvider);
    try {
      await repository.undoSoftDeleteMember(member.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error restoring member: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final showRemoved = ref.watch(showRemovedMembersProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: Icon(showRemoved ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              ref
                      .read(showRemovedMembersProvider(widget.groupId).notifier)
                      .state =
                  !showRemoved;
            },
            tooltip: showRemoved ? 'Hide removed' : 'Show removed',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isAdding)
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Member Name',
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                        autofocus: true,
                        onFieldSubmitted: (_) => _addMember(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: _addMember,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _isAdding = false),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Center(child: Text('No members found'));
                }

                return ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isRemoved = member.removedAt != null;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(member.displayName[0].toUpperCase()),
                      ),
                      title: Text(
                        member.displayName,
                        style: TextStyle(
                          decoration: isRemoved
                              ? TextDecoration.lineThrough
                              : null,
                          color: isRemoved ? Colors.grey : null,
                        ),
                      ),
                      trailing: isRemoved
                          ? IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () => _restoreMember(member),
                              tooltip: 'Restore',
                            )
                          : IconButton(
                              icon: const Icon(Icons.person_remove_outlined),
                              onPressed: () => _removeMember(member),
                              tooltip: 'Remove',
                            ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: _isAdding
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => _isAdding = true),
              child: const Icon(Icons.person_add),
            ),
    );
  }
}
