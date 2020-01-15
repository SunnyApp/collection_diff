import 'diff_equality.dart';

abstract class Diff<E> {}

abstract class Diffs<E, D extends Diff<E>> implements List<D> {}

abstract class DiffArguments<E> {
  String get debugName;
  String get id;

  Iterable<E> get original;

  Iterable<E> get replacement;

  final DiffEquality<E> diffEquality;

  DiffArguments({DiffEquality<E> diffEquality})
      : diffEquality = diffEquality ?? DiffEquality<E>();
  const DiffArguments.constant(this.diffEquality);
}
