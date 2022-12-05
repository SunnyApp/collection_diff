import 'package:collection/collection.dart' show IterableExtension;
import 'package:collection_diff/algorithms/map_diff.dart';
import 'package:collection_diff/algorithms/myers.dart';
import 'package:collection_diff/algorithms/set_diff.dart';
import 'package:collection_diff/diff_algorithm.dart';
import 'package:collection_diff/diff_equality.dart';

import 'diff_model.dart';
import 'list_diff_model.dart';
import 'map_diff_model.dart';
import 'set_diff_model.dart';

void diffExtensions() {}

extension ListDiffExt<E> on ListDiff<E> {
  InsertDiff<E> get insert => this as InsertDiff<E>;

  DeleteDiff<E> get delete => this as DeleteDiff<E>;

  ReplaceDiff<E> get change => this as ReplaceDiff<E>;

  Iterable<int> get indexes sync* {
    for (int i = 0; i < this.size; i++) {
      yield this.index! + i;
    }
  }
}

extension ListDiffsExt<E> on ListDiffs<E> {
  String get summary {
    final counts = <Type, int>{};
    for (final diff in this) {
      int count = counts.putIfAbsent(diff.runtimeType, () => 0);
      counts[diff.runtimeType] = count + 1;
    }
    return counts.entries.map((entry) {
      return "${entry.key}=${entry.value}";
    }).join(", ");
  }
}

extension SetDiffExt<E> on SetDiff<E> {
  E? get item => items.firstWhereOrNull((_) => true);
}

extension ListDiffItemExt<E> on InsertDiff<E> {
  E? get item {
    return items.firstWhereOrNull((_) => true);
  }
}

extension ListDiffExtensions<E> on List<E> {
  ListDiffs<E> differences(List<E> other,
      {bool identityOnly = true,
      DiffEquality? equality,
      ListDiffAlgorithm? algorithm}) {
    algorithm ??= MyersDiff(identityOnly);
    return algorithm.execute(ListDiffArguments(this, other, equality));
  }
}

extension StreamOfListDiffsExtensions<T> on Stream<ListDiffs<T>> {
  /// Returns a stream containing the state of the underlying list of [T]s for each change reported
  Stream<List<T>> replacements() =>
      this.map((ListDiffs<T> diffs) => diffs.args.replacement);
}

extension MapDiffExtensions<K, V> on Map<K, V> {
  MapDiffs<K, V> differences(
    Map<K, V> other, {
    bool checkValues = true,
    DiffEquality? keyEquality,
    DiffEquality? valueEquality,
    MapDiffAlgorithm? algorithm,
  }) {
    algorithm ??= const DefaultMapDiffAlgorithm();
    return algorithm.execute(MapDiffArguments(this, other,
        checkValues: checkValues,
        keyEquality: keyEquality,
        valueEquality: valueEquality));
  }
}

extension SetDiffExtensions<E> on Set<E> {
  SetDiffs<E> differences(Set<E> other,
      {bool checkEquality = true, DiffEquality? equality, String? debugName}) {
    const algorithm = DefaultSetDiffAlgorithm();
    return algorithm
        .execute(SetDiffArguments(this, other, checkEquality, equality));
  }
}

extension DiffArgumentsExtension<E> on DiffArguments<E> {
  bool identical(final E first, final E second) {
    return diffEquality.areIdentical(first, second);
  }

  bool equal(E first, E second) {
    return diffEquality.areEqual(first, second);
  }

  bool compare(bool isIdentityOnly, E first, E second) {
    if (isIdentityOnly == true) {
      return identical(first, second);
    } else {
      return equal(first, second);
    }
  }
}
