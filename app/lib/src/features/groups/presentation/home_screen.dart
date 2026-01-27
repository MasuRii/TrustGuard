import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../app/app.dart';
import '../../../ui/components/empty_state.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/components/skeletons/skeleton_card.dart';
import '../../../ui/components/skeletons/skeleton_list.dart';
import '../../../ui/components/skeletons/skeleton_list_item.dart';
import '../../../ui/animations/lottie_assets.dart';
import '../../../ui/animations/staggered_list_animation.dart';
import '../../../ui/components/animated_archive_icon.dart';
import '../../dashboard/presentation/widgets/dashboard_card.dart';
import '../../dashboard/presentation/widgets/recent_activity_list.dart';
import '../../../core/utils/haptics.dart';
import '../../../ui/components/speed_dial_fab.dart';
import '../../../core/services/undoable_action_service.dart';
import '../../../ui/components/undo_snackbar.dart';
import '../../../core/models/group.dart';
import 'groups_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  StaggeredListAnimationController? _staggeredController;
  int _lastItemCount = 0;

  @override
  void dispose() {
    _staggeredController?.dispose();
    super.dispose();
  }

  void _updateAnimationController(int count) {
    if (_staggeredController != null && _lastItemCount == count) {
      _staggeredController?.reset();
      _staggeredController?.startAnimation();
      return;
    }

    _staggeredController?.dispose();
    _staggeredController = StaggeredListAnimationController(
      vsync: this,
      itemCount: count,
    );
    _lastItemCount = count;
    _staggeredController!.startAnimation();
  }

  Future<void> _onRefresh() async {
    HapticsService.lightTap();
    ref.invalidate(groupsWithMemberCountProvider);
    await ref.read(groupsWithMemberCountProvider.future);
    // Animation will be restarted via ref.listen or whenData check
  }

  void _scheduleGroupArchive(Group group) {
    final repository = ref.read(groupRepositoryProvider);
    final undoService = ref.read(undoableActionProvider);
    final l10n = context.l10n;

    // Optimistically hide from list
    ref
        .read(optimisticallyHiddenGroupIdsProvider.notifier)
        .update((state) => {...state, group.id});

    final actionId = undoService.schedule(
      UndoableAction(
        id: 'archive_group_${group.id}',
        description: l10n.groupArchived,
        executeAction: () async {
          await repository.archiveGroup(group.id);
          // Remove from optimistic hide once executed
          if (mounted) {
            ref
                .read(optimisticallyHiddenGroupIdsProvider.notifier)
                .update((state) => state.where((id) => id != group.id).toSet());
          }
        },
        undoAction: () async {
          // Just remove from optimistic hide to bring it back
          if (mounted) {
            ref
                .read(optimisticallyHiddenGroupIdsProvider.notifier)
                .update((state) => state.where((id) => id != group.id).toSet());
          }
        },
      ),
    );

    showUndoSnackBar(
      context: context,
      message: l10n.groupArchived,
      actionId: actionId,
      undoService: undoService,
    );
  }

  Future<void> _showGroupSelectionForImport() async {
    final groups = ref.read(groupsWithMemberCountProvider).value ?? [];

    if (groups.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noGroupsImportMessage)),
      );
      return;
    }

    final selectedGroupId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.selectGroup),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index].group;
              return ListTile(
                title: Text(group.name),
                onTap: () => Navigator.pop(context, group.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );

    if (selectedGroupId != null && mounted) {
      context.push('/group/$selectedGroupId/import');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsWithMemberCountProvider);
    final showArchived = ref.watch(showArchivedGroupsProvider);

    // Restart animation when data changes
    ref.listen(groupsWithMemberCountProvider, (previous, next) {
      next.whenData((groups) {
        if (groups.isNotEmpty) {
          _updateAnimationController(groups.length);
        }
      });
    });

    // Initial load check
    groupsAsync.whenData((groups) {
      if (groups.isNotEmpty && _staggeredController == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateAnimationController(groups.length);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: [
          IconButton(
            icon: AnimatedArchiveIcon(isArchived: showArchived),
            onPressed: () =>
                ref.read(showArchivedGroupsProvider.notifier).state =
                    !showArchived,
            tooltip: showArchived
                ? context.l10n.hideArchived
                : context.l10n.showArchived,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: context.l10n.settingsTitle,
          ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: CustomScrollView(
              key: const PageStorageKey('home_scroll_view'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      AppTheme.space16,
                      AppTheme.space16,
                      0,
                    ),
                    child: DashboardCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: AppTheme.space24),
                    child: RecentActivityList(),
                  ),
                ),
                if (groups.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Semantics(
                      label: 'No groups container',
                      child: EmptyState(
                        lottiePath: showArchived
                            ? null
                            : LottieAssets.emptyGroups,
                        svgPath: showArchived
                            ? null
                            : 'assets/illustrations/empty_groups.svg',
                        icon: showArchived
                            ? Icons.archive_outlined
                            : Icons.group_off_outlined,
                        title: showArchived
                            ? context.l10n.noArchivedGroups
                            : context.l10n.noGroupsYet,
                        message: showArchived
                            ? context.l10n.noArchivedGroupsMessage
                            : context.l10n.noGroupsMessage,
                        actionLabel: showArchived
                            ? null
                            : context.l10n.createGroup,
                        onActionPressed: showArchived
                            ? null
                            : () => context.push('/group/create'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = groups[index];
                        final group = item.group;
                        final isArchived = group.archivedAt != null;

                        final card = Semantics(
                          label: 'Group card: ${group.name}',
                          child: Card(
                            key: ValueKey(group.id),
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.only(
                              bottom: AppTheme.space16,
                            ),
                            child: ListTile(
                              title: Text(
                                group.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isArchived
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                '${context.l10n.membersCount(item.memberCount)} • ${group.currencyCode}',
                                style: TextStyle(
                                  fontStyle: isArchived
                                      ? FontStyle.italic
                                      : null,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        context.l10n.balance,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      Text(
                                        context.l10n.settled,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isArchived
                                              ? Colors.grey
                                              : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: AppTheme.space8),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      switch (value) {
                                        case 'edit':
                                          context.push(
                                            '/group/${group.id}/edit',
                                          );
                                          break;
                                        case 'archive':
                                          _scheduleGroupArchive(group);
                                          break;
                                        case 'unarchive':
                                          await ref
                                              .read(groupRepositoryProvider)
                                              .unarchiveGroup(group.id);
                                          break;
                                      }
                                    },

                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.edit_outlined,
                                          ),
                                          title: Text(context.l10n.edit),
                                          contentPadding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      if (!isArchived)
                                        PopupMenuItem(
                                          value: 'archive',
                                          child: ListTile(
                                            leading: const AnimatedArchiveIcon(
                                              isArchived: false,
                                            ),
                                            title: Text(context.l10n.archive),
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        )
                                      else
                                        PopupMenuItem(
                                          value: 'unarchive',
                                          child: ListTile(
                                            leading: const AnimatedArchiveIcon(
                                              isArchived: true,
                                            ),
                                            title: Text(context.l10n.unarchive),
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                    ],
                                    tooltip: context.l10n.groupOptions,
                                  ),
                                ],
                              ),
                              onTap: () => context.push('/group/${group.id}'),
                            ),
                          ),
                        );

                        if (_staggeredController != null) {
                          return StaggeredListItem(
                            animation: _staggeredController!.getAnimation(
                              index,
                            ),
                            child: card,
                          );
                        }

                        return card;
                      }, childCount: groups.length),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  AppTheme.space16,
                  AppTheme.space16,
                  0,
                ),
                child: SkeletonCard(),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: AppTheme.space24),
                child: SkeletonList(
                  itemCount: 3,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.space16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const SkeletonListItem(),
                  childCount: 5,
                ),
              ),
            ),
          ],
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: AppTheme.space16),
              Text(context.l10n.errorLoadingGroups(error.toString())),
              const SizedBox(height: AppTheme.space16),
              ElevatedButton(
                onPressed: () => ref.refresh(groupsWithMemberCountProvider),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SpeedDialFab(
        mainIcon: Icons.add,
        items: [
          SpeedDialItem(
            icon: Icons.group_add,
            label: context.l10n.newGroup,
            onPressed: () => context.push('/group/create'),
          ),
          SpeedDialItem(
            icon: Icons.upload_file,
            label: context.l10n.importData,
            onPressed: _showGroupSelectionForImport,
          ),
        ],
      ),
    );
  }
}
