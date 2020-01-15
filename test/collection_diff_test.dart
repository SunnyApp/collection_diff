import 'package:collection_diff/collection_diff.dart';
import 'package:collection_diff/list_diff_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_mocks.dart';

void main() {
  group("all", () {
    setUp(() {
      increment = 1;
    });

    test("List diff - insert", () async {
      final list1 = [1, 2, 3, 4, 6, 7];
      final list2 = [1, 2, 3, 4, 5, 6, 7];

      final diff = list1.differences(list2);
      expect(diff.length, equals(1));
      final result = diff.first;
      expect(result is InsertDiff, isTrue);
      expect(result.insert.index, equals(4));
    });

    test("List diff - remove", () async {
      final list1 = [1, 2, 3, 4, 5, 6, 7];
      final list2 = [1, 2, 3, 4, 6, 7];

      final diff = list1.differences(list2);
      expect(diff.length, equals(1));
      expect(diff, hasDelete((delete) => delete.index == 4));
    });

    test("List diff - swapremove", () async {
      final list1 = [1, 2, 3, 4, 6, 7];
      final list2 = [1, 2, 3, 4, 5, 6];

      final diff = list1.differences(list2);
      expect(diff.length, equals(2));
      expect(diff, hasDelete((delete) => delete.index == 5));
      expect(
          diff, hasInsert((insert) => insert.item == 5 && insert.index == 4));
    });

    test("List diff - swap", () async {
      final list1 = [1, 2, 3, 4, 5, 6];
      final list2 = [1, 2, 3, 4, 6, 7];

      final diff = list1.differences(list2);
      expect(diff[0], isA<InsertDiff>());
      expect(diff[1], isA<DeleteDiff>());
      expect(diff,
          hasInsert<int>((insert) => insert.index == 6 && insert.item == 7));
      expect(diff, hasDelete<int>((delete) => delete.index == 4));
    });

    test("List diff - keys - Keyed (identity)", () async {
      final list1 = generateFromNames([
        "Captain America",
        "Captain Marvel",
        "Thor",
      ]);
      final list2 = [list1[0], list1[1].rename("The Binary"), list1[2]];

      final diff = list1.differences(list2);
      expect(diff.length, equals(0));
    });

    test("List diff - keys - Keyed (equality)", () async {
      final list1 = generateFromNames([
        "Captain America",
        "Captain Marvel",
        "Thor",
      ]);

      final list2 = [list1[0], list1[1].rename("The Binary"), list1[2]];
      final diff = list1.differences(list2, identityOnly: false);
      expect(diff.length, equals(1));
    });

    test("List diff - Rename an item - Using toString as keyGenerator",
        () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Richard",
        "James",
      ]);

      final list2 = [...list1]..[2] = list1[2].rename("Dick");

      final diff = list1.differences(list2);
      expect(diff.length, equals(0));
    });

    test(
        "List diff - Rename an item - Using toString as keyGenerator (equality)",
        () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Richard",
        "James",
      ]);

      final list2 = [...list1]..[2] = list1[2].rename("Dick");

      final diff = list1.differences(list2, identityOnly: false);
      expect(diff.length, equals(1));
      expect(diff, hasReplace((replace) => replace.index == 2));
    });

    test("List diff - nokeys - rename the first (identity)", () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Richard",
        "James",
      ]);

      final list2 = [list1[0].rename("Robert"), list1[1], list1[2], list1[3]];

      final diff = list1.differences(list2);
      expect(diff.length, equals(0));
    });

    test("List diff - nokeys - rename the first (equals)", () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Richard",
        "James",
      ]);

      final list2 = [list1[0].rename("Robert"), list1[1], list1[2], list1[3]];

      final diff = list1.differences(list2, identityOnly: false);
      expect(diff.length, equals(1));
      expect(diff, hasReplace((replace) => replace.index == 0));
    });
//
    test("List diff - longer list - move backwards", () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Eric",
        "Richard",
        "James",
        "Lady",
        "Tramp",
        "Randy",
        "Donald"
      ]);

      final list2 = [...list1]
        ..insert(8, list1[2])
        ..removeAt(2);

      final diff = list1.differences(list2);
      expect(diff.length, equals(2));
      expect(diff, hasDelete((move) => move.delete.index == 2));
      expect(diff, hasInsert((move) => move.insert.index == 8));
    });

    test("List diff - longer list - move element up", () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Eric",
        "Richard",
        "James",
        "Lady",
        "Tramp",
        "Randy",
        "Donald"
      ]);

      final list2 = [...list1]..move(7, 2);

      final diff = list1.differences(list2);

      expect(diff.length, equals(2));
      expect(diff, hasDelete((move) => move.index == 7));
      expect(diff, hasInsert((insert) => insert.index == 2));
    });

    test("List diff - longer list - move 2 elements up", () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Eric",
        "Richard",
        "James",
        "Lady",
        "Tramp",
        "Randy",
        "Donald"
      ]);

      final list2 = [...list1]..move(7, 3)..move(8, 2);
      final diff = list1.differences(list2);

      expect(diff.length, equals(3));
      expect(
          diff, hasDelete((delete) => delete.size == 2 && delete.index == 7));
      expect(diff, hasInsert((insert) => insert.index == 3));
      expect(diff, hasInsert((insert) => insert.index == 2));
    });

    test("List diff - insert beginning", () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Eric",
        "Richard",
        "James",
        "Lady",
        "Tramp",
        "Randy",
        "Donald"
      ]);
      final list2 = [...list1]..insert(0, Renamable("Kevin"));
      final diff = list1.differences(list2);
      expect(diff.length, equals(1));
      expect(diff, hasInsert((insert) => insert.index == 0));
    });

    test("List diff - insert middle", () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Eric",
        "Richard",
        "James",
        "Lady",
        "Tramp",
        "Randy",
        "Donald"
      ]);

      final list2 = [...list1]..insert(4, Renamable("Kevin"));

      final diff = list1.differences(list2);

      expect(diff.length, equals(1));
      expect(diff, hasInsert((insert) => insert.index == 4));
    });
//
    test("List diff - insert middle big list", () async {
      final list1 =
          generateFromNames([...Iterable.generate(5000, (i) => "Guy$i")]);

      final list2 = [...list1]..insert(100, Renamable("Kevin"));

      final start = DateTime.now();
      final diff = list1.differences(list2);
      final duration = start.difference(DateTime.now());
      print("Duration: $duration");
      expect(duration.inMicroseconds, lessThan(1000));
      expect(diff.length, 1);
      expect(diff, hasInsert((insert) => insert.index == 100));
    });

    test("List diff - remove beginning", () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Eric",
        "Richard",
        "James",
        "Lady",
        "Tramp",
        "Randy",
        "Donald"
      ]);

      final list2 = [...list1];
      list2.removeAt(0);

      final diff = list1.differences(list2);

      expect(diff.length, equals(1));
      expect(diff, hasDelete((delete) => delete.index == 0));
    });

    test("List diff - remove middle", () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Eric",
        "Richard",
        "James",
        "Lady",
        "Tramp",
        "Randy",
        "Donald"
      ]);

      final list2 = [...list1];
      list2.removeAt(4);

      final diff = list1.differences(list2);
      expect(diff.length, equals(1));
      expect(diff, hasDelete((delete) => delete.index == 4));
    });

    test("List diff - using delegate identity", () async {
      final list1 =
          generateFromNames(["Captain America", "Captain Marvel", "Thor"]);
      final list2 = [...list1]..[1] = list1[1].rename("The Binary");

      final diff = list1.differences(list2);
      expect(diff.length, equals(0));
    });

    test("List diff - using delegate equals", () async {
      final list1 =
          generateFromNames(["Captain America", "Captain Marvel", "Thor"]);
      final list2 = [...list1]..[1] = list1[1].rename("The Binary");

      final diff = list1.differences(list2, identityOnly: false);
      expect(diff.length, equals(1));
      expect(diff, hasReplace((replace) => replace.index == 1));
    });
  });
}
