import 'package:collection/collection.dart';
import 'package:collection_diff/diff_equality.dart';
import 'package:uuid/uuid.dart';

import 'diff_model.dart';

enum SetDiffType { remove, update, add }

abstract class SetDiff<E> {
  Set<E> get items;
  final SetDiffType type;
  final SetDiffArguments<E> args;

  SetDiff(this.args, this.type) : assert(type != null, args != null);

  factory SetDiff.add(SetDiffArguments<E> args, Set<E> items) =>
      _SetDiff(args, SetDiffType.add, items);

  factory SetDiff.remove(SetDiffArguments<E> args, Set<E> items) =>
      _SetDiff(args, SetDiffType.remove, items);

  factory SetDiff.update(SetDiffArguments<E> args, E oldValue, E newValue) =>
      UpdateDiff(args, oldValue, newValue);

  @override
  String toString() {
    return "${this.runtimeType} type: $type, item: ${items.length}";
  }

  SetDiff<R> recast<R>(SetDiffArguments<R> args);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetDiff &&
          runtimeType == other.runtimeType &&
          args == other.args;

  @override
  int get hashCode => args.hashCode;
}

class _SetDiff<E> extends SetDiff<E> {
  final Set<E> items;
  _SetDiff(SetDiffArguments<E> args, SetDiffType type, this.items)
      : assert(items?.isNotEmpty == true),
        super(args, type);

  SetDiff<R> recast<R>(SetDiffArguments<R> args) {
    return _SetDiff<R>(args, this.type, items.cast<R>());
  }
}

class UpdateDiff<E> extends SetDiff<E> {
  final E oldValue;
  final E newValue;

  UpdateDiff(SetDiffArguments<E> args, this.oldValue, this.newValue)
      : super(args, SetDiffType.update);

  @override
  Set<E> get items => {newValue};

  UpdateDiff<R> recast<R>(SetDiffArguments<R> args) {
    return UpdateDiff<R>(args, oldValue as R, newValue as R);
  }
}

class SetDiffArguments<E> extends DiffArguments<E> {
  final Iterable<E> original;
  final Iterable<E> replacement;

  final bool checkEquality;
  final String debugName;
  final String id;

  SetDiffArguments(this.original, this.replacement, bool checkEquality,
      DiffEquality<E> diffEquality,
      {String id, this.debugName})
      : id = id ?? Uuid().v4(),
        checkEquality = checkEquality ?? true,
        super(diffEquality: diffEquality ?? DiffEquality());

  SetDiffArguments.copied(Iterable<E> original, Iterable<E> replacement,
      bool checkEquality, DiffEquality<E> diffEquality)
      : this([...?original], [...?replacement], checkEquality, diffEquality);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetDiffArguments &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SetDiffs<E> extends DelegatingList<SetDiff<E>> {
  final SetDiffArguments<E> args;
  final List<SetDiff<E>> operations;
  final Set<E> replacement;

  SetDiffs.empty(this.args)
      : operations = const [],
        replacement = const {},
        super(const []);

  SetDiffs.ofOperations(this.operations, Set<E> replacement, this.args)
      : replacement = {...?replacement},
        super(operations);

  SetDiffs.builder(SetDiffArguments<E> args)
      : this.ofOperations(<SetDiff<E>>[], {}, args);
}
