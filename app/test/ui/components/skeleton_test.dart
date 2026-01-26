import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trustguard/src/ui/components/skeletons/skeleton_list_item.dart';
import 'package:trustguard/src/ui/components/skeletons/skeleton_list.dart';

void main() {
  group('Skeleton Tests', () {
    testWidgets('SkeletonListItem renders correctly with shimmer', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkeletonListItem())),
      );

      // Verify Shimmer is present
      expect(find.byType(Shimmer), findsOneWidget);

      // Verify ListTile structure is present (even if it's inside Shimmer)
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Verify some Containers (placeholders) are present
      expect(find.byType(Container), findsAtLeastNWidgets(3));
    });

    testWidgets('SkeletonList renders correct number of items', (tester) async {
      const itemCount = 7;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonList(itemCount: itemCount)),
        ),
      );

      // Verify the number of SkeletonListItem widgets
      expect(find.byType(SkeletonListItem), findsNWidgets(itemCount));
    });

    testWidgets('SkeletonList respects shrinkWrap and padding', (tester) async {
      const padding = EdgeInsets.all(16);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonList(
              itemCount: 2,
              shrinkWrap: true,
              padding: padding,
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.shrinkWrap, isTrue);
      expect(listView.padding, padding);
    });
  });
}
