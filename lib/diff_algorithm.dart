import 'package:collection_diff/algorithms/map_diff.dart';
import 'package:collection_diff/algorithms/myers.dart';
import 'package:collection_diff/algorithms/wagner_fischer.dart';
import 'package:collection_diff/list_diff_model.dart';
import 'package:collection_diff/set_diff_model.dart';

import 'algorithms/set_diff.dart';
import 'map_diff_model.dart';

abstract class ListDiffAlgorithm {
  ListDiffs<E> execute<E>(ListDiffArguments<E> args);

  static const myers = MyersDiff();
  static const wagnerFischer = WagnerFischerDiff();

  ListDiffAlgorithm withIdentityOnly(bool isIdentityOnly);
}

abstract class SetDiffAlgorithm {
  SetDiffs<E> execute<E>(SetDiffArguments<E> args);

  static const sets = DefaultSetDiffAlgorithm();
}

abstract class MapDiffAlgorithm {
  MapDiffs<K, V> execute<K, V>(MapDiffArguments<K, V> args);

  static const sets = DefaultMapDiffAlgorithm();
}
