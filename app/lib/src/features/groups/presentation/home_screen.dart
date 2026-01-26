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
import '../../dashboard/presentation/widgets/dashboard_card.dart';
import '../../dashboard/presentation/widgets/recent_activity_list.dart';
import 'groups_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsWithMemberCountProvider);
    final showArchived = ref.watch(showArchivedGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: [
          IconButton(
            icon: Icon(showArchived ? Icons.archive : Icons.archive_outlined),
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
          return CustomScrollView(
            key: const PageStorageKey('home_scroll_view'),
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

                      return Semantics(
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
                                fontStyle: isArchived ? FontStyle.italic : null,
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
                                        context.push('/group/${group.id}/edit');
                                        break;
                                      case 'archive':
                                        await ref
                                            .read(groupRepositoryProvider)
                                            .archiveGroup(group.id);
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
                                          leading: const Icon(
                                            Icons.archive_outlined,
                                          ),
                                          title: Text(context.l10n.archive),
                                          contentPadding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      )
                                    else
                                      PopupMenuItem(
                                        value: 'unarchive',
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.unarchive_outlined,
                                          ),
                                          title: Text(context.l10n.unarchive),
                                          contentPadding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
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
                    }, childCount: groups.length),
                  ),
                ),
            ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/group/create'),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newGroup),
      ),
    );
  }
}
