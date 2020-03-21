import 'package:collection_diff/collection_diff.dart';
import 'package:collection_diff/map_diff_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_mocks.dart';

void main() {
  group("all", () {
    setUp(() {
      increment = 1;
    });

    test("Map diff - remove all", () async {
      final map1 = Map.fromEntries(
          generateFromNames(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"])
              .map((name) => MapEntry(name.id, name)));

      final map2 = <String, Renamable>{};

      final diff = map1.differences(map2);

      expect(diff.length, equals(9));
    });

    test("Map diff - add all", () async {
      final map1 = <String, Renamable>{};
      final map2 = testMap(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);

      final diff = map1.differences(map2);

      expect(diff.length, equals(9));
    });

    test("Map diff - add key", () async {
      final map1 = testMap(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);
      final map2 = {...map1}..["23"] = Renamable("Kevin");
      final diff = map1.differences(map2);

      expect(diff, hasSet((add) => add.key == "23" && add.value.name == "Kevin"));
      expect(diff.length, equals(1));
    });

    test("Map diff - remove key", () async {
      final map1 = testMap(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);
      final map2 = {...map1}..removeWhere((_, v) => v.name == "Lady");
      final diff = map1.differences(map2);
      expect(diff, hasUnset((diff) => diff.key == "6" && diff.oldValue.name == "Lady"));
      expect(diff.length, equals(1));
    });

    test("Map diff - update pointer doesn't produce diff", () async {
      final map1 = testMap(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);
      final map2 = {...map1};
      map2["1"].name = "Robert";

      final diff = map1.differences(map2);
      expect(diff.length, equals(0));
    });

    test("Map diff - identical lists", () async {
      final map1 = testMap(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);
      final map2 = map1;
      map1.remove("1");

      final diff = map1.differences(map2);
      expect(diff.length, equals(0));
    });

    test("Map diff - update item", () async {
      final map1 = testMap(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);

      // Because we're adding a new instance altogether, it should work
      final map2 = {...map1}..["1"] = Renamable.ofId("1", "Robert");

      final diff = map1.differences(map2);
      expect(diff.length, equals(1));
      expect(diff, hasChange((diff) => diff.key == "1" && diff.value.name == "Robert" && diff.oldValue.name == "Bob"));
    });

    test("Map diff - update item without value checks", () async {
      final map1 = testMap(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);

      // Because we're adding a new instance altogether, it should work
      final map2 = {...map1}..["1"] = Renamable.ofId("1", "Robert");

      final diff = map1.differences(map2, checkValues: false);
      // Since keys didn't change, the diff should be empty
      expect(diff.length, equals(0));
    });

    test("Map diff - update item with alternate equality", () async {
      final map1 = testMap(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);

      // Because we're adding a new instance altogether, it should work
      final map2 = {...map1}
        ..["1"] = Renamable.ofId("1", "Robert")
        ..["2"] = Renamable("Kevin");

      // Using the identity check instead of equals, so, it shouldn't pick up on name changes, but should pick up id
      // changes (for values)
      final diff = map1.differences(map2, valueEquality: DiffEquality(areEqual: DefaultDiffIdentical()));
      // EVen though we made two changes, only the one where the id changed should be reported
      expect(diff.length, equals(1));
      expect(diff, hasChange((diff) => diff.key == "2" && diff.value.name == "Kevin" && diff.oldValue.name == "John"));
    });
  });
}

Map<String, Renamable> testMap(Iterable<String> names) {
  return Map.fromEntries(
      generateFromNames(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"])
          .map((name) => MapEntry(name.id, name)));
}

hasUnset<K, V>(Predicate<MapDiff<K, V>> predicate) =>
    _MapDiffMatcher<K, V>((change) => change.type == MapDiffType.unset && predicate(change));

hasSet<K, V>(Predicate<MapDiff<K, V>> predicate) =>
    _MapDiffMatcher<K, V>((change) => change.type == MapDiffType.set && predicate(change));

hasChange<K, V>(Predicate<MapDiff<K, V>> predicate) =>
    _MapDiffMatcher<K, V>((change) => change.type == MapDiffType.change && predicate(change));

typedef Predicate<T> = bool Function(T input);

class _MapDiffMatcher<K, V> extends Matcher {
  final Predicate<MapDiff<K, V>> changeMatch;

  _MapDiffMatcher(this.changeMatch);

  @override
  bool matches(final item, Map matchState) {
    if (item is MapDiffs<K, V>) {
      return item.any((final x) => (changeMatch?.call(x) ?? true));
    }
    return false;
  }

  @override
  Description describe(Description description) => description.add('hasMapDiff');
}
