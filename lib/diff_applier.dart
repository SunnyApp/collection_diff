import 'package:collection_diff/diff_model.dart';

class DiffApplier<E> {
  final DiffVisitor _visitor;

  DiffApplier(this._visitor) : assert(_visitor != null);

  void applyDiffs(List<ListDiff> diffs) {
    diffs.forEach((diff) => diff.accept(_visitor));
  }
}
