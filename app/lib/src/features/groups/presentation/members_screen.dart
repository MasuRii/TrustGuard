import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/models/member.dart';
import '../../../core/models/transaction_filter.dart';
import '../../../core/services/undoable_action_service.dart';
import '../../../ui/components/undo_snackbar.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/components/empty_state.dart';
import '../../../core/utils/haptics.dart';
import '../../../generated/app_localizations.dart';
import 'groups_providers.dart';

class MembersScreen extends ConsumerStatefulWidget {
  final String groupId;

  const MembersScreen({super.key, required this.groupId});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _nameController = TextEditingController();
  List<Member>? _localMembers;

  Future<void> _onRefresh() async {
    HapticsService.lightTap();
    ref.invalidate(membersByGroupProvider(widget.groupId));
    await ref.read(membersByGroupProvider(widget.groupId).future);
  }

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
    final hasActivity =
        await ref
            .read(transactionRepositoryProvider)
            .getTransactionCountByGroup(
              widget.groupId,
              filter: TransactionFilter(memberIds: {member.id}),
            ) >
        0;

    if (hasActivity && mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Member?'),
          content: Text(
            '${member.displayName} has associated transactions. Removing them will hide them from the list, but their data will remain in the records.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.remove),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    _scheduleMemberRemove(member);
  }

  void _scheduleMemberRemove(Member member) {
    final undoService = ref.read(undoableActionProvider);
    final repository = ref.read(memberRepositoryProvider);
    final l10n = AppLocalizations.of(context)!;

    // Optimistically hide
    ref
        .read(optimisticallyRemovedMemberIdsProvider.notifier)
        .update((state) => {...state, member.id});

    final action = UndoableAction(
      id: 'remove_member_${member.id}',
      description: l10n.memberRemoved,
      executeAction: () async {
        await repository.softDeleteMember(member.id);
        if (mounted) {
          ref
              .read(optimisticallyRemovedMemberIdsProvider.notifier)
              .update((state) => state.where((id) => id != member.id).toSet());
        }
      },
      undoAction: () async {
        if (mounted) {
          ref
              .read(optimisticallyRemovedMemberIdsProvider.notifier)
              .update((state) => state.where((id) => id != member.id).toSet());
        }
      },
    );

    undoService.schedule(action);

    if (mounted) {
      showUndoSnackBar(
        context: context,
        message: l10n.memberRemoved,
        actionId: action.id,
        undoService: undoService,
      );
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

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_localMembers == null) return;

    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _localMembers!.removeAt(oldIndex);
      _localMembers!.insert(newIndex, item);
    });

    HapticsService.lightTap();

    final memberIds = _localMembers!.map((m) => m.id).toList();
    try {
      await ref
          .read(memberRepositoryProvider)
          .updateMemberOrder(widget.groupId, memberIds);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating order: $e')));
        // Re-invalidate to get correct order from DB
        ref.invalidate(membersByGroupProvider(widget.groupId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final showRemoved = ref.watch(showRemovedMembersProvider(widget.groupId));

    ref.listen(membersByGroupProvider(widget.groupId), (prev, next) {
      next.whenData((members) {
        setState(() {
          _localMembers = List.from(members);
        });
      });
    });

    // Initial population
    if (_localMembers == null && membersAsync.hasValue) {
      _localMembers = List.from(membersAsync.value!);
    }

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
              // Reset local members to ensure they are re-fetched/re-sorted correctly
              _localMembers = null;
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
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: membersAsync.when(
                data: (members) {
                  final displayList = _localMembers ?? members;

                  if (displayList.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: const EmptyState(
                          icon: Icons.people_outline,
                          title: 'No members found',
                          message: 'Add members to start tracking expenses.',
                        ),
                      ),
                    );
                  }

                  final canReorder = !showRemoved && displayList.length > 1;

                  if (canReorder) {
                    return ReorderableListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      key: const PageStorageKey('members_reorder_list'),
                      onReorder: _onReorder,
                      buildDefaultDragHandles: false,
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final member = displayList[index];
                        return _buildMemberTile(
                          member,
                          index,
                          canReorder: true,
                          totalCount: displayList.length,
                        );
                      },
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    key: const PageStorageKey('members_list'),
                    itemCount: displayList.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = displayList[index];
                      return _buildMemberTile(
                        member,
                        index,
                        canReorder: false,
                        totalCount: displayList.length,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
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

  Widget _buildMemberTile(
    Member member,
    int index, {
    required bool canReorder,
    required int totalCount,
  }) {
    final isRemoved = member.removedAt != null;

    return ListTile(
      key: ValueKey(member.id),
      leading: CircleAvatar(child: Text(member.displayName[0].toUpperCase())),
      title: Text(
        member.displayName,
        style: TextStyle(
          decoration: isRemoved ? TextDecoration.lineThrough : null,
          color: isRemoved ? Colors.grey : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRemoved)
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () => _restoreMember(member),
              tooltip: 'Restore',
            )
          else
            IconButton(
              icon: const Icon(Icons.person_remove_outlined),
              onPressed: () => _removeMember(member),
              tooltip: 'Remove',
            ),
          if (canReorder)
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.space8),
                child: Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
