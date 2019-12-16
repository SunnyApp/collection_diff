import 'package:collection_diff/collection_diff.dart';
import 'package:collection_diff/diff_equality.dart';
import 'package:flutter_test/flutter_test.dart';

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
      expect(diff, hasInsert((insert) => insert.item == 5 && insert.index == 4));
    });

    test("List diff - swap", () async {
      final list1 = [1, 2, 3, 4, 5, 6];
      final list2 = [1, 2, 3, 4, 6, 7];

      final diff = list1.differences(list2);
      expect(diff[0], isA<InsertDiff>());
      expect(diff[1], isA<DeleteDiff>());
      expect(diff, hasInsert<int>((insert) => insert.index == 6 && insert.item == 7));
      expect(diff, hasDelete<int>((delete) => delete.index == 4));
    });

    test("List diff - keys - Keyed", () async {
      final list1 = generateFromNames([
        "Captain America",
        "Captain Marvel",
        "Thor",
      ]);

      final list2 = [list1[0], list1[1].rename("The Binary"), list1[2]];
      final diff = list1.differences(list2);
      expect(diff.length, equals(1));
    });

    test("List diff - Rename an item - Using toString as keyGenerator", () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Richard",
        "James",
      ]);

      final list2 = [...list1]..[2] = list1[2].rename("Dick");

      final diff = list1.differences(list2);
      expect(diff.length, equals(1));
      expect(diff, hasReplace((replace) => replace.index == 2));
    });

    test("List diff - nokeys - rename the first", () async {
      final list1 = generateFromNames([
        "Bob",
        "John",
        "Richard",
        "James",
      ]);

      final list2 = [list1[0].rename("Robert"), list1[1], list1[2], list1[3]];

      final diff = list1.differences(list2);
      expect(diff.length, equals(1));
      expect(diff, hasReplace((replace) => replace.index == 0));
    });
//
    test("List diff - longer list - move backwards", () async {
      final list1 = generateFromNames(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);

      final list2 = [...list1]
        ..insert(8, list1[2])
        ..removeAt(2);

      final diff = list1.differences(list2);
      expect(diff.length, equals(2));
      expect(diff, hasDelete((move) => move.delete.index == 2));
      expect(diff, hasInsert((move) => move.insert.index == 8));
    });

    test("List diff - longer list - move element up", () async {
      final list1 = generateFromNames(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);

      final list2 = [...list1]..move(7, 2);

      final diff = list1.differences(list2);

      expect(diff.length, equals(2));
      expect(diff, hasDelete((move) => move.index == 7));
      expect(diff, hasInsert((insert) => insert.index == 2));
    });

    test("List diff - longer list - move 2 elements up", () async {
      final list1 = generateFromNames(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);

      final list2 = [...list1]..move(7, 3)..move(8, 2);
      final diff = list1.differences(list2);

      expect(diff.length, equals(3));
      expect(diff, hasDelete((delete) => delete.size == 2 && delete.index == 7));
      expect(diff, hasInsert((insert) => insert.index == 3));
      expect(diff, hasInsert((insert) => insert.index == 2));
    });

    test("List diff - insert beginning", () async {
      final list1 = generateFromNames(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);
      final list2 = [...list1]..insert(0, Renamable("Kevin"));
      final diff = list1.differences(list2);
      expect(diff.length, equals(1));
      expect(diff, hasInsert((insert) => insert.index == 0));
    });

    test("List diff - insert middle", () async {
      final list1 = generateFromNames(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);

      final list2 = [...list1]..insert(4, Renamable("Kevin"));

      final diff = list1.differences(list2);

      expect(diff.length, equals(1));
      expect(diff, hasInsert((insert) => insert.index == 4));
    });
//
    test("List diff - insert middle big list", () async {
      final list1 = generateFromNames([...Iterable.generate(5000, (i) => "Guy$i")]);

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
      final list1 = generateFromNames(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);

      final list2 = [...list1];
      list2.removeAt(0);

      final diff = list1.differences(list2);

      expect(diff.length, equals(1));
      expect(diff, hasDelete((delete) => delete.index == 0));
    });

    test("List diff - remove middle", () async {
      final list1 = generateFromNames(["Bob", "John", "Eric", "Richard", "James", "Lady", "Tramp", "Randy", "Donald"]);

      final list2 = [...list1];
      list2.removeAt(4);

      final diff = list1.differences(list2);
      expect(diff.length, equals(1));
      expect(diff, hasDelete((delete) => delete.index == 4));
    });

    test("List diff - using equals", () async {
      final list1 = generateFromNames(["Captain America", "Captain Marvel", "Thor"]);
      final list2 = [...list1]..[1] = list1[1].rename("The Binary");

      final diff = list1.differences(list2);
      expect(diff.length, equals(1));
      expect(diff, hasReplace((replace) => replace.index == 1));
    });
  });
}

List<Renamable> generateFromNames(List<String> names) {
  return names.map((name) => Renamable.ofId("${increment++}", name)).toList();
}

int increment = 1;

/// Tests doing diffs based on keys
class Renamable with DiffDelegateMixin {
  final String id;
  String name;

  Renamable.ofId(this.id, this.name);

  Renamable(this.name) : id = "${increment++}";

  Renamable rename(String newName) => Renamable.ofId(id, newName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Renamable && runtimeType == other.runtimeType && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'Renamable{id: $id, name: $name}';

  @override
  dynamic get diffKey => id;
}

hasReplace<E>(Predicate<ListDiff<E>> predicate) =>
    _ChangeMatcher<E, ReplaceDiff<E>>((change) => change is ReplaceDiff<E> && predicate(change.change));

hasDelete<E>(Predicate<DeleteDiff<E>> predicate) =>
    _ChangeMatcher<E, DeleteDiff<E>>((change) => change is DeleteDiff<E> && predicate(change.delete));

hasInsert<E>(Predicate<InsertDiff<E>> predicate) =>
    _ChangeMatcher<E, InsertDiff<E>>((change) => change is InsertDiff<E> && predicate(change.insert));

//hasMove(Predicate<Move> predicate) => _ChangeMatcher<Move>((change) => change is Move && predicate(change.move));

typedef Predicate<T> = bool Function(T input);

class _ChangeMatcher<E, D extends ListDiff<E>> extends Matcher {
  final Predicate<D> changeMatch;

  _ChangeMatcher(this.changeMatch);

  @override
  bool matches(final item, Map matchState) {
    if (item is Diffs<E>) {
      return item.any((final x) => x is D && (changeMatch?.call(x) ?? true));
    }
    return false;
  }

  @override
  Description describe(Description description) => description.add('hasChange<$D>');
}

extension ListExtTest<X> on List<X> {
  void move(int fromIndex, int toIndex) {
    final value = this[fromIndex];
    this.removeAt(fromIndex);
    if (fromIndex > toIndex) {
      this.insert(toIndex, value);
    } else {
      this.insert(toIndex - 1, value);
    }
  }
}
