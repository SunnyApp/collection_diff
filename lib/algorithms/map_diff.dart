import 'package:collection/collection.dart';
import 'package:collection_diff/diff_algorithm.dart';
import 'package:collection_diff/diff_extensions.dart';
import 'package:collection_diff/map_diff_model.dart';

class DefaultMapDiffAlgorithm implements MapDiffAlgorithm {
  @override
  MapDiffs<K, V> execute<K extends Object, V>(MapDiffArguments<K, V> args) {
    final oldMap = args.original;
    final newMap = args.replacement;

    if (identical(oldMap, newMap)) {
      return MapDiffs.empty(args);
    }

    final oldIsEmpty = args.original.isEmpty;
    final newIsEmpty = args.replacement.isEmpty;

    if (oldIsEmpty && newIsEmpty) {
      return MapDiffs.empty(args);
    }

    if (oldIsEmpty) {
      return MapDiffs.ofOperations([
        for (final entry in args.replacement.entries) MapDiff.set(args, entry.key, entry.value),
      ], args);
    }

    if (newIsEmpty) {
      return MapDiffs.ofOperations([
        for (final entry in args.original.entries) MapDiff.unset(args, entry.key, entry.value),
      ], args);
    }

    final checkValues = args.checkValues;
    final currKeys = EqualitySet.from(args.keyEquality.areEqual, oldMap.keys);
    final newKeys = EqualitySet.from(args.keyEquality.areEqual, newMap.keys);

    final addedKeys = newKeys.difference(currKeys);
    final removedKeys = currKeys.difference(newKeys);
    final sameKeys = newKeys.intersection(currKeys);

    final changes = MapDiffs<K, V>.args(args);

    for (final added in addedKeys) {
      changes.add(MapDiff.set(args, added as K, newMap[added]));
    }

    for (final removed in removedKeys) {
      changes.add(MapDiff.unset(args, removed as K, oldMap[removed]));
    }

    if (checkValues == true) {
      for (final matchingKey in sameKeys) {
        final oldItem = oldMap[matchingKey];
        final newItem = newMap[matchingKey];
        if (!args.valueEquality.equal(oldItem, newItem)) {
          changes.add(MapDiff.change(args, matchingKey as K, newItem, oldItem));
        }
      }
    }
    return changes;
  }

  const DefaultMapDiffAlgorithm();
}
