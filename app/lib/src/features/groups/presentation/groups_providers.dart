import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/models/group.dart';

/// Provider for the filter state (whether to show archived groups).
final showArchivedGroupsProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Provider for the list of groups with their member counts.
final groupsWithMemberCountProvider =
    StreamProvider.autoDispose<List<GroupWithMemberCount>>((ref) {
      final repository = ref.watch(groupRepositoryProvider);
      final includeArchived = ref.watch(showArchivedGroupsProvider);
      return repository.watchGroupsWithMemberCount(
        includeArchived: includeArchived,
      );
    });

/// Provider for a single group by its ID.
final groupProvider = FutureProvider.autoDispose.family<Group?, String>((
  ref,
  id,
) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupById(id);
});
