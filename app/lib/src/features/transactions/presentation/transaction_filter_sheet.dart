import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/models/member.dart';
import '../../../core/models/tag.dart';
import '../../../core/models/transaction_filter.dart';
import '../../groups/presentation/groups_providers.dart';
import 'transactions_providers.dart';

class TransactionFilterSheet extends ConsumerStatefulWidget {
  final String groupId;

  const TransactionFilterSheet({super.key, required this.groupId});

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  late TransactionFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = ref.read(transactionFilterProvider(widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final tagsAsync = ref.watch(tagsProvider(widget.groupId));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            AppBar(
              title: const Text('Filter Transactions'),
              automaticallyImplyLeading: false,
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = const TransactionFilter();
                    });
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () {
                    ref
                            .read(
                              transactionFilterProvider(
                                widget.groupId,
                              ).notifier,
                            )
                            .state =
                        _filter;
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Members',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  membersAsync.when(
                    data: (List<Member> members) {
                      return Wrap(
                        spacing: 8,
                        children: members.map((member) {
                          final isSelected =
                              _filter.memberIds?.contains(member.id) ?? false;
                          return FilterChip(
                            label: Text(member.displayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                final memberIds = Set<String>.from(
                                  _filter.memberIds ?? {},
                                );
                                if (selected) {
                                  memberIds.add(member.id);
                                } else {
                                  memberIds.remove(member.id);
                                }
                                _filter = _filter.copyWith(
                                  memberIds: memberIds,
                                );
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Error: $error'),
                  ),
                  const SizedBox(height: 24),
                  Text('Tags', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  tagsAsync.when(
                    data: (List<Tag> tags) {
                      return Wrap(
                        spacing: 8,
                        children: tags.map((tag) {
                          final isSelected =
                              _filter.tagIds?.contains(tag.id) ?? false;
                          return FilterChip(
                            label: Text(tag.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                final tagIds = Set<String>.from(
                                  _filter.tagIds ?? {},
                                );
                                if (selected) {
                                  tagIds.add(tag.id);
                                } else {
                                  tagIds.remove(tag.id);
                                }
                                _filter = _filter.copyWith(tagIds: tagIds);
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Error: $error'),
                  ),
                  const SizedBox(height: 24),
                  Text('Date', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(
                      _filter.startDate != null
                          ? _filter.startDate!.toString().split(' ')[0]
                          : 'Not set',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _filter.startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _filter = _filter.copyWith(startDate: date);
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(
                      _filter.endDate != null
                          ? _filter.endDate!.toString().split(' ')[0]
                          : 'Not set',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _filter.endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _filter = _filter.copyWith(endDate: date);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
