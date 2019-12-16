import 'package:collection_diff/algorithms/myers.dart';
import 'package:collection_diff/algorithms/wagner_fischer.dart';

import 'diff_model.dart';

abstract class DiffAlgorithm {
  Diffs<E> execute<E>(DiffArguments<E> args);

  static const myers = MyersDiff();
  static const wagnerFischer = WagnerFischerDiff();
}
