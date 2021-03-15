import 'package:collection/collection.dart';
import 'package:collection_diff/collection_diff.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_mocks.dart';

void main() => setDiffTests();
void setDiffTests() {
  group("setDiff", () {
    setUp(() {
      increment = 1;
    });

    test("Set diff - remove beginning", () async {
      final set1 = testSet([
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
      final set2 = {...set1}..removeWhere((r) => r.id == "1");

      final diff = set1.differences(set2) as SetDiffs<Renamable>;

      expect(diff.length, equals(1));
      expect(
          diff, hasRemove<Renamable>((remove) => remove.items.first.id == "1"));
    });

    test("Set diff - remove all", () async {
      final set1 = testSet([
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
      final set2 = <Renamable>{};

      final diff = set1.differences(set2) as SetDiffs<Renamable>;

      expect(diff.length, equals(1));
      expect(diff, hasRemove((remove) => remove.items.length == 9));
    });

    test("Set diff - add all", () async {
      final set1 = <Renamable>{};
      final set2 = testSet([
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

      final diff = set1.differences(set2) as SetDiffs<Renamable>;

      expect(diff.length, equals(1));
      expect(diff, hasAdd((add) => add.items.length == 9));
    });

    test("Set diff - add element", () async {
      final set1 = testSet([
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
      final set2 = {...set1}..add(Renamable("Kevin"));
      final diff = set1.differences(set2) as SetDiffs<Renamable>;

      expect(diff, hasAdd<Renamable>((add) {
        return add.item?.name == "Kevin";
      }));
      expect(diff.length, equals(1));
    });

    test("Set diff - update pointer doesn't produce diff", () async {
      final set1 = testSet([
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
      final set2 = {...set1};
      set2.where((i) => i.id == "1").forEach((i) => i.name = "Robert");

      final diff = set1.differences(set2) as SetDiffs<Renamable>;
      expect(diff.length, equals(0));
    });

    test("Set diff - identical (pointer) lists", () async {
      final set1 = testSet([
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
      final set2 = set1;
      set1.remove(set1.first);

      final diff = set1.differences(set2) as SetDiffs<Renamable>;
      expect(diff.length, equals(0));
    });

    test("Set diff - remove and add same", () async {
      final set1 = testSet([
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

      // Because we're adding a new instance altogether, we won't get false positive on identical(...)
      final set2 = {...set1}
        ..removeWhere((n) => n.id == "1")
        ..add(Renamable.ofId("1", "Robert"));

      final diff = set1.differences(set2) as SetDiffs<Renamable>;
      expect(diff, hasUpdate<Renamable>((diff) {
        return diff.oldValue.id == "1" &&
            diff.oldValue.name == "Bob" &&
            diff.newValue.id == "1" &&
            diff.newValue.name == "Robert";
      }));
      expect(diff.length, equals(1));
    });

    test("Set diff - add item with matching identity", () async {
      final set1 = testSet([
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

      // An odd case - we're using a different equals implementation for the diff than the default set (hashCode and ==)
      // so the target set will have an extra item, even though the diff reports them as being the same...
      final set2 = {...set1}..add(Renamable.ofId("1", "Robert"));

      final diff = set1.differences(set2) as SetDiffs<Renamable>;
      expect(diff.length, equals(1));
      expect(diff, hasUpdate<Renamable>((diff) {
        return diff.newValue.id == "1" && diff.newValue.name == "Robert";
      }));
    });

    test("Model identity sanity checks", () async {
      final defaultEq = DiffEquality();
      expect(
          defaultEq.areIdentical(
            Renamable.ofId("1", "Richard"),
            Renamable.ofId("1", "Dick"),
          ),
          equals(true),
          reason: "ids match");
      expect(
          defaultEq.areIdentical(
            Renamable.ofId("1", "Richard"),
            Renamable.ofId("2", "Richard"),
          ),
          equals(false),
          reason: "names matching doesn't constitute identity");
      expect(
          defaultEq.areIdentical(
            Renamable.ofId("1", "Richard"),
            Renamable.ofId("1", "Richard"),
          ),
          equals(true),
          reason: "full match");

      final rich = Renamable.ofId("1", "Richard");
      expect(defaultEq.areIdentical(rich, rich), equals(true),
          reason: "same identity");

      final set = EqualitySet(defaultEq.asIdentityEquality());
      set.add(Renamable.ofId("1", "Richard"));

      expect(
          defaultEq
              .asIdentityEquality()
              .isValidKey(Renamable.ofId("1", "Richard")),
          equals(true),
          reason: "Diffable is a valid key");

      expect(set.contains(Renamable.ofId("1", "Richard")), equals(true),
          reason: "Should contain equal item");
      expect(set.contains(Renamable.ofId("1", "Dick")), equals(true),
          reason: "Should contain identical item");
    });

    test("Model equality sanity checks", () async {
      final defaultEq = DiffEquality();
      expect(
          defaultEq.areEqual(
            Renamable.ofId("1", "Richard"),
            Renamable.ofId("1", "Dick"),
          ),
          equals(false),
          reason: "ids match but names differ");
      expect(
          defaultEq.areEqual(
            Renamable.ofId("1", "Richard"),
            Renamable.ofId("2", "Richard"),
          ),
          equals(false),
          reason: "ids not equal");
      expect(
          defaultEq.areIdentical(
            Renamable.ofId("1", "Richard"),
            Renamable.ofId("1", "Richard"),
          ),
          equals(true),
          reason: "should be equal");

      final rich = Renamable.ofId("1", "Richard");
      expect(defaultEq.areIdentical(rich, rich), equals(true),
          reason: "same identity");
    });

    test("Set diff - update item with alternate equality", () async {
      final set1 = testSet([
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

      final set2 = {...set1}
        ..add(Renamable.ofId(
            "1", "Robert")) // This one should look like a new item
        ..add(Renamable.ofId(
            "2", "John")); // This one should look like an update (no change)

      // Using a more lenient match - the name and id must match to trigger a diff
      final diff = set1.differences(set2,
              equality: DiffEquality.ofEquality(DiffableEquality.equality))
          as SetDiffs<Renamable>;
      // EVen though we made two changes, only the one where the id changed should be reported
      expect(diff.length, equals(1));
      expect(
          diff,
          hasAdd<Renamable>(
              (diff) => diff.item?.name == "Robert" && diff.item?.id == "1"));
    });
  });
}

Set<Renamable> testSet(Iterable<String> names) {
  return generateFromNames([
    "Bob",
    "John",
    "Eric",
    "Richard",
    "James",
    "Lady",
    "Tramp",
    "Randy",
    "Donald"
  ]).toSet();
}
