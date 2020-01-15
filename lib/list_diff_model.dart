import 'package:collection/collection.dart';
import 'package:collection_diff/diff_equality.dart';
import 'package:uuid/uuid.dart';

import 'diff_model.dart';

enum ListDiffType { delete, replace, insert }

abstract class ListDiff<E> implements Diff<E>, Comparable<ListDiff<E>> {
  final int index;
  final int size;

  final ListDiffArguments<E> args;

  const ListDiff(this.args, this.index, this.size);

  @override
  String toString() {
    return "${this.runtimeType.toString()} index: $index, size: $size";
  }

  @override
  int compareTo(ListDiff other) => index - other.index;

  ListDiffType get type;
}

class InsertDiff<E> extends ListDiff<E> {
  final List<E> items;

  InsertDiff(ListDiffArguments<E> args, int index, int size, this.items)
      : super(args, index, size);

  E get item => items.firstWhere((_) => true, orElse: () => null);

  @override
  ListDiffType get type => ListDiffType.insert;
}

class DeleteDiff<E> extends ListDiff<E> {
  DeleteDiff(ListDiffArguments<E> args, int index, int size)
      : super(args, index, size);

  @override
  ListDiffType get type => ListDiffType.delete;
}

class ReplaceDiff<E> extends ListDiff<E> {
  final List<E> items;

  ReplaceDiff(ListDiffArguments<E> args, int index, int size, this.items)
      : super(args, index, size);

  @override
  ListDiffType get type => ListDiffType.replace;
}

class ListDiffArguments<E> extends DiffArguments<E> {
  final List<E> original;
  final List<E> replacement;
  final String debugName;
  final String id;

  ListDiffArguments.empty([String id, this.debugName])
      : id = id ?? Uuid().v4(),
        this.original = const [],
        replacement = const [],
        super.constant(const DiffEquality());

  ListDiffArguments(this.original, this.replacement, DiffEquality<E> equals,
      {String id, this.debugName})
      : id = id ?? Uuid().v4(),
        assert(original != null),
        assert(replacement != null),
        super(diffEquality: equals);

  ListDiffArguments._(this.original, this.replacement, DiffEquality<E> equals,
      this.id, this.debugName)
      : super(diffEquality: equals);

  ListDiffArguments.copied(Iterable<E> original, Iterable<E> replacement,
      DiffEquality<E> diffEquality, {String id, String debugName})
      : this([...?original], [...?replacement], diffEquality,
            debugName: debugName, id: id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListDiffArguments &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  ListDiffArguments<E> withId(String id) {
    return ListDiffArguments._(
        original, replacement, diffEquality, id, debugName);
  }
}

class ListDiffs<E> extends DelegatingList<ListDiff<E>>
    implements Diffs<E, ListDiff<E>> {
  final ListDiffArguments<E> args;
  final List<ListDiff<E>> operations;

  ListDiffs.empty([ListDiffArguments<E> args])
      : args = args ?? ListDiffArguments.empty(),
        operations = const [],
        super(const []);

  ListDiffs.ofOperations(this.operations, this.args) : super(operations);

  ListDiffs.builder(ListDiffArguments<E> args)
      : this.ofOperations(<ListDiff<E>>[], args);

  List<E> get oldList => args.original;

  List<E> get newList => args.replacement;

  String get debugName => args.debugName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListDiffs &&
          runtimeType == other.runtimeType &&
          args == other.args;

  @override
  int get hashCode => args.hashCode;
}
