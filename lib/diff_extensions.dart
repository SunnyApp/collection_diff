import 'package:collection_diff/algorithms/myers.dart';
import 'package:collection_diff/diff_algorithm.dart';
import 'package:collection_diff/diff_equality.dart';
import 'package:collection_diff/diff_model.dart';

extension DiffExt<E> on ListDiff<E> {
  InsertDiff<E> get insert => this as InsertDiff<E>;

  DeleteDiff<E> get delete => this as DeleteDiff<E>;

  ReplaceDiff<E> get change => this as ReplaceDiff<E>;
}

extension ListDiffExtensions<E> on List<E> {
  Diffs<E> differences(List<E> other, {DiffEquality<E> equality, DiffAlgorithm algorithm}) {
    algorithm ??= const MyersDiff();
    return algorithm.execute(DiffArguments(this, other, equals: equality, algorithm: algorithm));
  }
}
