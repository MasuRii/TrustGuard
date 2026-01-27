import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/models/group.dart';
import '../../../core/models/member.dart';

/// Provider for the filter state (whether to show archived groups).
final showArchivedGroupsProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Provider for the list of groups with their member counts.
final groupsWithMemberCountProvider =
    StreamProvider.autoDispose<List<GroupWithMemberCount>>((ref) {
      final repository = ref.watch(groupRepositoryProvider);
      final includeArchived = ref.watch(showArchivedGroupsProvider);
      final hiddenIds = ref.watch(optimisticallyHiddenGroupIdsProvider);

      return repository
          .watchGroupsWithMemberCount(includeArchived: includeArchived)
          .map((groups) {
            if (hiddenIds.isEmpty) return groups;
            return groups
                .where((g) => !hiddenIds.contains(g.group.id))
                .toList();
          });
    });

/// Provider for IDs of groups that are optimistically hidden (e.g. during archive undo).
final optimisticallyHiddenGroupIdsProvider =
    StateProvider.autoDispose<Set<String>>((ref) => {});

/// Provider for a single group by its ID.
final groupProvider = FutureProvider.autoDispose.family<Group?, String>((
  ref,
  id,
) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupById(id);
});

/// Provider for a single group by its ID (stream).
final groupStreamProvider = StreamProvider.autoDispose.family<Group?, String>((
  ref,
  id,
) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.watchGroupById(id);
});

/// Provider for the filter state (whether to show removed members).
final showRemovedMembersProvider = StateProvider.autoDispose
    .family<bool, String>((ref, groupId) => false);

/// Provider for the list of members in a group.
final membersByGroupProvider = StreamProvider.autoDispose
    .family<List<Member>, String>((ref, groupId) {
      final repository = ref.watch(memberRepositoryProvider);
      final includeRemoved = ref.watch(showRemovedMembersProvider(groupId));
      return repository.watchMembersByGroup(
        groupId,
        includeRemoved: includeRemoved,
      );
    });
