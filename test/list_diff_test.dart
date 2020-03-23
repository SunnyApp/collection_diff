import 'package:collection_diff/collection_diff.dart';
import 'package:collection_diff/diff_algorithm.dart';
import 'package:collection_diff/list_diff.dart';
import 'package:collection_diff/list_diff_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_mocks.dart';

void main() {
  myersDiffTests();
  wfgerDiffTests();
}

void myersDiffTests() {
  _listDiffTests("myers", MyersDiff(), () {
    test("List diff - insert middle big list", () async {
      final list1 =
          generateFromNames([...Iterable.generate(5000, (i) => "Guy$i")]);

      final list2 = [...list1]..insert(100, Renamable("Kevin"));

      final start = DateTime.now();
      final diff = list1.differences(list2, algorithm: MyersDiff());
      final duration = start.difference(DateTime.now());
      print("Duration: $duration ${diff.summary}");
      expect(duration.inMicroseconds, lessThan(1000));
      expect(diff.length, 1);
      expect(diff, hasInsert((insert) => insert.index == 100));
    });
  });
}

void wfgerDiffTests() {
  _listDiffTests("wagnerFischer", WagnerFischerDiff());
}

void _listDiffTests(String algorithmName, ListDiffAlgorithm algorithm,
    [void moreTests()]) {
  group("listDiff - $algorithmName", () {
    setUp(() {
      increment = 1;
    });

    moreTests?.call();

    test("List diff - insert - $algorithmName", () async {
      final list1 = [1, 2, 3, 4, 6, 7];
      final list2 = [1, 2, 3, 4, 5, 6, 7];

      final diff = list1.differences(list2, algorithm: algorithm);
      expect(diff.length, equals(1));
      final result = diff.first;
      expect(result is InsertDiff, isTrue);
      expect(result.insert.index, equals(4));
    });

    test("List diff - remove - $algorithmName", () async {
      final list1 = [1, 2, 3, 4, 5, 6, 7];
      final list2 = [1, 2, 3, 4, 6, 7];

      final diff = list1.differences(list2, algorithm: algorithm);
      expect(diff.length, equals(1));
      expect(diff, hasDelete((delete) => delete.index == 4));
    });

    test("List diff - swapremove - $algorithmName", () async {
      final list1 = [1, 2, 3, 4, 6, 7];
      final list2 = [1, 2, 3, 4, 5, 6];

      final diff = list1.differences(list2, algorithm: algorithm);
      expect(diff.length, equals(2));
      expect(diff, hasDelete((delete) => delete.index == 5));
      expect(
          diff, hasInsert((insert) => insert.item == 5 && insert.index == 4));
    });

    test("List diff - swap - $algorithmName", () async {
      final list1 = [1, 2, 3, 4, 5, 6];
      final list2 = [1, 2, 3, 4, 6, 7];

      final diff = list1.differences(list2, algorithm: algorithm);
      if (diff[0] is InsertDiff) {
        expect(diff[0], isA<InsertDiff>());
        expect(diff[1], isA<DeleteDiff>());
        expect(diff,
            hasInsert<int>((insert) => insert.index == 6 && insert.item == 7));
        expect(diff, hasDelete<int>((delete) => delete.index == 4));
      } else {
        expect(diff[0], isA<DeleteDiff>());
        expect(diff[1], isA<InsertDiff>());
        expect(diff,
            hasInsert<int>((insert) => insert.index == 5 && insert.item == 7));
        expect(diff, hasDelete<int>((delete) => delete.index == 4));
      }
    });

    test("List diff - keys - Keyed (identity) - $algorithmName", () async {
      final list1 = generateFromNames([
        "Captain America",
        "Captain Marvel",
        "Thor",
      ]);
      final list2 = [list1[0], list1[1].rename("The Binary"), list1[2]];

      final diff = list1.differences(list2, algorithm: algorithm);
      expect(diff.length, equals(0));
    });

    test("List diff - keys - Keyed (equality) - $algorithmName", () async {
      final list1 = generateFromNames([
        "Captain America",
        "Captain Marvel",
        "Thor",
      ]);

      final list2 = [list1[0], list1[1].rename("The Binary"), list1[2]];
      final diff = list1.differences(list2,
          identityOnly: false, algorithm: algorithm.withIdentityOnly(false));
      expect(diff.length, equals(1));
    });

    test(
        "List diff - Rename an item - Using toString as keyGenerator - $algorithmName",
        () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Richard",
        "James",
      ]);

      final list2 = [...list1]..[2] = list1[2].rename("Dick");

      final diff = list1.differences(list2, algorithm: algorithm);
      expect(diff.length, equals(0));
    });

    test(
        "List diff - Rename an item - Using toString as keyGenerator (equality) - $algorithmName",
        () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Richard",
        "James",
      ]);

      final list2 = [...list1]..[2] = list1[2].rename("Dick");

      final diff = list1.differences(list2,
          identityOnly: false, algorithm: algorithm.withIdentityOnly(false));
      expect(diff.length, equals(1));
      expect(diff, hasReplace((replace) => replace.index == 2));
    });

    test("List diff - nokeys - rename the first (identity) - $algorithmName",
        () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Richard",
        "James",
      ]);

      final list2 = [list1[0].rename("Robert"), list1[1], list1[2], list1[3]];

      final diff = list1.differences(list2, algorithm: algorithm);
      expect(diff.length, equals(0));
    });

    test("List diff - nokeys - rename the first (equals) - $algorithmName",
        () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Richard",
        "James",
      ]);

      final list2 = [list1[0].rename("Robert"), list1[1], list1[2], list1[3]];

      final diff = list1.differences(list2,
          identityOnly: false, algorithm: algorithm.withIdentityOnly(false));
      expect(diff.length, equals(1));
      expect(diff, hasReplace((replace) => replace.index == 0));
    });
//
    test("List diff - longer list - move backwards - $algorithmName", () async {
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

      final diff = list1.differences(list2, algorithm: algorithm);
      expect(diff.length, equals(2));
      if (diff[0] is DeleteDiff) {
        expect(diff, hasDelete((move) => move.delete.index == 2));
        expect(diff, hasInsert((move) => move.insert.index == 7));
      } else {
        expect(diff, hasDelete((move) => move.delete.index == 2));
        expect(diff, hasInsert((move) => move.insert.index == 8));
      }
    });

    test("List diff - longer list - move element up - $algorithmName",
        () async {
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

      final diff = list1.differences(list2, algorithm: algorithm);

      expect(diff.length, equals(2));
      expect(diff, hasDelete((move) => move.index == 7));
      expect(diff, hasInsert((insert) => insert.index == 2));
    });

    test("Downsizing diff - $algorithmName", () async {
      final list1 = generateFromNames(["Bob", "John"]);

      final list2 = generateFromNames(["Eric"]);

      final diff = list1.differences(list2, algorithm: algorithm);

      expect(diff.length, equals(2));
      expect(diff, hasDelete((delete) => delete.index == 1));
      expect(diff, hasReplace((replace) => replace.index == 0));
    });

    test("Downsizing diff: 3 to 2 - $algorithmName", () async {
      final list1 = generateFromNames(["Bob", "John", "Frank"]);

      final list2 = generateFromNames(["Eric"]);

      final diff = list1.differences(list2, algorithm: algorithm);

      if (diff.length == 2) {
        expect(diff, hasDelete((delete) => delete.index == 1));
        expect(diff, hasReplace((replace) => replace.index == 0));
      } else {
        expect(diff.length, 3);
        expect(diff, hasDelete((delete) => delete.index == 1));
        expect(diff, hasDelete((delete) => delete.index == 2));
        expect(diff, hasReplace((replace) => replace.index == 0));
      }
    });

    test("List diff - longer list - move 2 elements up - $algorithmName",
        () async {
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
      final diff = list1.differences(list2, algorithm: algorithm);

      if (diff.length == 3) {
        expect(diff.length, equals(3));
        expect(
            diff, hasDelete((delete) => delete.size == 2 && delete.index == 7));
        expect(diff, hasInsert((insert) => insert.index == 3));
        expect(diff, hasInsert((insert) => insert.index == 2));
      } else {
        expect(diff.length, equals(4));

        /// The wf diff produces inserts in ascending order, so the last index appears one higher
        expect(diff, hasDelete((delete) => delete.index == 7));
        expect(diff, hasDelete((delete) => delete.index == 8));
        expect(diff, hasInsert((insert) => insert.index == 4));
        expect(diff, hasInsert((insert) => insert.index == 2));
      }
    });

    test("List diff - insert beginning - $algorithmName", () async {
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
      final diff = list1.differences(list2, algorithm: algorithm);
      expect(diff.length, equals(1));
      expect(diff, hasInsert((insert) => insert.index == 0));
    });

    test("List diff - insert middle - $algorithmName", () async {
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

      final diff = list1.differences(list2, algorithm: algorithm);

      expect(diff.length, equals(1));
      expect(diff, hasInsert((insert) => insert.index == 4));
    });
//
    test("List diff - remove beginning - $algorithmName", () async {
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

      final diff = list1.differences(list2, algorithm: algorithm);

      expect(diff.length, equals(1));
      expect(diff, hasDelete((delete) => delete.index == 0));
    });

    test("List diff - remove middle - $algorithmName", () async {
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

      final diff = list1.differences(list2, algorithm: algorithm);
      expect(diff.length, equals(1));
      expect(diff, hasDelete((delete) => delete.index == 4));
    });

    test("List diff - using delegate identity - $algorithmName", () async {
      final list1 =
          generateFromNames(["Captain America", "Captain Marvel", "Thor"]);
      final list2 = [...list1]..[1] = list1[1].rename("The Binary");

      final diff = list1.differences(list2, algorithm: algorithm);
      expect(diff.length, equals(0));
    });

    test("List diff - using delegate equals - $algorithmName", () async {
      final list1 =
          generateFromNames(["Captain America", "Captain Marvel", "Thor"]);
      final list2 = [...list1]..[1] = list1[1].rename("The Binary");

      final diff = list1.differences(list2,
          identityOnly: false, algorithm: algorithm.withIdentityOnly(false));
      expect(diff.length, equals(1));
      expect(diff, hasReplace((replace) => replace.index == 1));
    });
  });
}
