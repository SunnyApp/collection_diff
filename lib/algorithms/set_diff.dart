import 'package:collection/collection.dart';
import 'package:collection_diff/algorithms/utils.dart';
import 'package:collection_diff/diff_algorithm.dart';
import 'package:collection_diff/set_diff.dart';
import 'package:collection_diff/set_diff_model.dart';

class DefaultSetDiffAlgorithm implements SetDiffAlgorithm {
  @override
  SetDiffs<E> execute<E>(SetDiffArguments<E> args) {
    if (identical(args.original, args.replacement)) return SetDiffs.empty(args);

    final pp = preprocessSetDiff(args);
    if (pp != null) return pp;

    /// We reverse the source list here because it's possible that the identity algorithm is less strict
    /// than the rules for the originating set, and if there are duplicates, we want to keep the last one
    /// inserted.  Of course, this assumes an ordered insertion set li
    final oldSet = EqualitySet.from(args.diffEquality.asIdentityEquality(),
        args.original.toList().reversed);
    final newSet = EqualitySet.from(args.diffEquality.asIdentityEquality(),
        args.replacement.toList().reversed);

    final removes = oldSet.difference(newSet);
    final adds = newSet.difference(oldSet);

    final updates = <SetDiff<E>>[];
    if (args.isCheckEquality == true) {
      final map = EqualityMap(args.diffEquality.asIdentityEquality());

      // Add the original items to a map, using the identity equality.  This way, we can look them up using their
      // hashes which is more efficient than looping over every element
      oldSet.union(newSet).forEach((item) {
        map[item] = item;
      });
      newSet.union(oldSet).forEach((item) {
        final compared = map[item];
        assert(
            compared != null,
            "Missing a comparison for item $item - which means your identity equality "
            "it not reciprocal.");
        if (!args.diffEquality.areEqual(item, compared)) {
          updates.add(SetDiff.update(args, compared as E, item as E));
        }
      });
    }

    final allOperations = <SetDiff<E>>[
      if (removes.isNotEmpty) SetDiff.remove(args, {...removes.cast()}),
      if (adds.isNotEmpty) SetDiff.add(args, {...adds.cast()}),
      ...updates,
    ];
    return SetDiffs<E>.ofOperations(
        allOperations, {...newSet.toList().reversed.cast()}, args);
  }

  const DefaultSetDiffAlgorithm();
}
