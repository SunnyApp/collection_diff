import 'package:collection_diff/algorithms/map_diff.dart';
import 'package:collection_diff/algorithms/myers.dart';
import 'package:collection_diff/algorithms/set_diff.dart';
import 'package:collection_diff/diff_algorithm.dart';
import 'package:collection_diff/diff_equality.dart';

import 'diff_model.dart';
import 'list_diff_model.dart';
import 'map_diff_model.dart';
import 'set_diff_model.dart';

extension ListDiffExt<E> on ListDiff<E> {
  InsertDiff<E> get insert => this as InsertDiff<E>;

  DeleteDiff<E> get delete => this as DeleteDiff<E>;

  ReplaceDiff<E> get change => this as ReplaceDiff<E>;
}

extension SetDiffExt<E> on SetDiff<E> {
  E get item => items.firstWhere((_) => true, orElse: () => null);
}

extension ListDiffItemExt<E> on InsertDiff<E> {
  E get item {
    return items.firstWhere((_) => true, orElse: () => null);
  }
}

extension ListDiffExtensions<E> on List<E> {
  ListDiffs<E> differences(List<E> other,
      {bool identityOnly = true,
      DiffEquality<E> equality,
      ListDiffAlgorithm algorithm}) {
    algorithm ??= MyersDiff(identityOnly);
    return algorithm.execute(ListDiffArguments(this, other, equality));
  }
}

extension MapDiffExtensions<K, V> on Map<K, V> {
  MapDiffs<K, V> differences(
    Map<K, V> other, {
    bool checkValues = true,
    DiffEquality<K> keyEquality,
    DiffEquality<V> valueEquality,
    MapDiffAlgorithm algorithm,
  }) {
    algorithm ??= const DefaultMapDiffAlgorithm();
    return algorithm.execute(MapDiffArguments(this, other,
        checkValues: checkValues ?? true,
        keyEquality: keyEquality,
        valueEquality: valueEquality));
  }
}

extension SetDiffExtensions<E> on Set<E> {
  SetDiffs<E> differences(Set<E> other,
      {bool checkEquality = true, DiffEquality<E> equality, String debugName}) {
    const algorithm = DefaultSetDiffAlgorithm();
    return algorithm
        .execute(SetDiffArguments(this, other, checkEquality, equality));
  }
}

extension DiffEqualityExt<E> on DiffEquality<E> {
  bool identical(final E first, final E second) {
    return areIdentical.equals(first, second);
  }

  bool equal(E first, E second) {
    return areEqual.equals(first, second);
  }
}

extension DiffArgumentsExtension<E> on DiffArguments<E> {
  bool identical(final E first, final E second) {
    return diffEquality.identical(first, second);
  }

  bool equal(E first, E second) {
    return diffEquality.equal(first, second);
  }
}
