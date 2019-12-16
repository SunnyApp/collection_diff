import 'package:collection/collection.dart';
import 'package:collection_diff/diff_algorithm.dart';
import 'package:collection_diff/diff_equality.dart';

abstract class DiffVisitor<E> {
  void visitInsertDiff(InsertDiff<E> diff);

  void visitDeleteDiff(DeleteDiff<E> diff);

  void visitReplaceDiff(ReplaceDiff<E> diff);
}

enum ListDiffType { delete, replace, insert }

abstract class ListDiff<E> implements Comparable<ListDiff<E>> {
  final int index;
  final int size;

  final DiffArguments<E> args;

  const ListDiff(this.args, this.index, this.size);

  @override
  String toString() {
    return "${this.runtimeType.toString()} index: $index, size: $size";
  }

  @override
  int compareTo(ListDiff other) => index - other.index;

  void accept(DiffVisitor<E> visitor);

  ListDiffType get type;
}

class InsertDiff<E> extends ListDiff<E> {
  final List<E> items;

  InsertDiff(DiffArguments<E> args, int index, int size, this.items) : super(args, index, size);

  E get item => items.firstWhere((_) => true, orElse: () => null);

  @override
  void accept(DiffVisitor visitor) => visitor.visitInsertDiff(this);

  @override
  ListDiffType get type => ListDiffType.insert;
}

class DeleteDiff<E> extends ListDiff<E> {
  DeleteDiff(DiffArguments<E> args, int index, int size) : super(args, index, size);

  @override
  void accept(DiffVisitor<E> visitor) => visitor.visitDeleteDiff(this);

  @override
  ListDiffType get type => ListDiffType.insert;
}

class ReplaceDiff<E> extends ListDiff<E> {
  final List<E> items;

  ReplaceDiff(DiffArguments<E> args, int index, int size, this.items) : super(args, index, size);

  @override
  void accept(DiffVisitor<E> visitor) => visitor.visitReplaceDiff(this);

  @override
  ListDiffType get type => ListDiffType.insert;
}

class DiffArguments<E> {
  final List<E> oldList;
  final List<E> newList;
  final DiffEquality<E> equals;
  final DiffAlgorithm algorithm;

  DiffArguments(Iterable<E> oldList, Iterable<E> newList, {this.algorithm, DiffEquality<E> equals})
      : oldList = oldList.toList(growable: false),
        newList = newList.toList(growable: false),
        equals = equals ?? DiffEquality.defaults(),
        assert(oldList != null),
        assert(newList != null);

  Diffs<E> result(List<ListDiff<E>> operations) => Diffs<E>.ofOperations(operations, this);

  bool areEqual(E first, E second) => equals.areEqual(first, second);
}

class Diffs<E> extends DelegatingList<ListDiff<E>> {
  final DiffArguments<E> args;
  final List<ListDiff<E>> operations;

  Diffs.empty(this.args)
      : operations = const [],
        super(const []);

  Diffs.ofOperations(this.operations, this.args) : super(operations);
  Diffs.builder(DiffArguments<E> args) : this.ofOperations(<ListDiff<E>>[], args);

  List<E> get oldList => args.oldList;
  List<E> get newList => args.newList;
}
