// ignore_for_file: always_declare_return_types

import 'package:collection_diff/collection_diff.dart';
import 'package:collection_diff/list_diff_model.dart';
import 'package:flutter_test/flutter_test.dart';

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
      other is Renamable &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'Renamable{id: $id, name: $name}';

  @override
  dynamic get diffKey => id;

  @override
  dynamic get diffSource => this;
}

hasReplace<E>(Predicate<ListDiff<E>> predicate) =>
    _ChangeMatcher<E, ReplaceDiff<E>>(
        (change) => change is ReplaceDiff<E> && predicate(change.change));

hasDelete<E>(Predicate<DeleteDiff<E>> predicate) =>
    _ChangeMatcher<E, DeleteDiff<E>>(
        (change) => change is DeleteDiff<E> && predicate(change.delete));

hasRemove<E>(Predicate<SetDiff<E>> predicate) => _SetDiffMatcher<E>(
    (change) => change.type == SetDiffType.remove && predicate(change));

hasAdd<E>(Predicate<SetDiff<E>> predicate) => _SetDiffMatcher<E>(
    (change) => change.type == SetDiffType.add && predicate(change));

hasUpdate<E>(Predicate<UpdateDiff<E>> predicate) => _SetDiffMatcher<E>(
    (change) => change is UpdateDiff<E> && predicate(change));

hasInsert<E>(Predicate<InsertDiff<E>> predicate) =>
    _ChangeMatcher<E, InsertDiff<E>>(
        (change) => change is InsertDiff<E> && predicate(change.insert));

//hasMove(Predicate<Move> predicate) => _ChangeMatcher<Move>((change) => change is Move && predicate(change.move));

typedef Predicate<T> = bool Function(T input);

class _ChangeMatcher<E, D extends ListDiff<E>> extends Matcher {
  final Predicate<D> changeMatch;

  _ChangeMatcher(this.changeMatch);

  @override
  bool matches(final item, Map matchState) {
    if (item is ListDiffs<E>) {
      return item.any((final x) => x is D && (changeMatch.call(x)));
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('hasChange<$D>');
}

class _SetDiffMatcher<E> extends Matcher {
  final Predicate<SetDiff<E>> changeMatch;

  _SetDiffMatcher(this.changeMatch);

  @override
  bool matches(final item, Map matchState) {
    if (item is SetDiffs<E>) {
      return item.any((final x) => (changeMatch.call(x)));
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('hasSetDiff');
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
