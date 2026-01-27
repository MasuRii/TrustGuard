import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/providers.dart';
import '../../../core/models/member.dart';
import '../../../core/models/transaction_filter.dart';
import '../../../core/services/undoable_action_service.dart';
import '../../../ui/components/undo_snackbar.dart';
import '../../../ui/theme/app_theme.dart';
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
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: membersAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: AppTheme.space32),
                          child: Text('No members found'),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    key: const PageStorageKey('members_list'),
                    itemCount: members.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isRemoved = member.removedAt != null;

                      return ListTile(
                        key: ValueKey(member.id),
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
