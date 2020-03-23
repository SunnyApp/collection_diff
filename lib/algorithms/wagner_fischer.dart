import 'dart:math';

import 'package:collection_diff/algorithms/utils.dart';
import 'package:collection_diff/collection_diff.dart';
import 'package:collection_diff/diff_algorithm.dart';
import 'package:collection_diff/list_diff_model.dart';

class WagnerFischerDiff implements ListDiffAlgorithm {
  final bool isIdentityOnly;
  const WagnerFischerDiff({this.isIdentityOnly = true});

  @override
  ListDiffs<E> execute<E extends Object>(final ListDiffArguments<E> args) {
    final original = args.original;
    final replacement = args.replacement;

    final ppResult = preprocessListDiff<E>(args);
    if (ppResult != null) return ppResult;

    final previousRow = Row<E>(args);
    previousRow.seed(replacement);
    final currentRow = Row<E>(args);

    // row in matrix
    var indexInOld = 0;
    original.forEach((oldItem) {
      // reset current row
      currentRow.reset(
        count: previousRow.slots.length,
        indexInOld: indexInOld,
        oldItem: oldItem,
      );

      // column in matrix
      var indexInNew = 0;
      replacement.forEach((newItem) {
        if (args.compare(isIdentityOnly, oldItem, newItem)) {
          currentRow.update(indexInNew: indexInNew, previousRow: previousRow);
        } else {
          currentRow.updateWithMin(
              previousRow: previousRow,
              indexInNew: indexInNew,
              newItem: newItem,
              indexInOld: indexInOld,
              oldItem: oldItem);
        }
        indexInNew++;
      });

      // set previousRow
      previousRow.slots = [...currentRow.slots];
      indexInOld++;
    });

    final changes = currentRow.lastSlot();
    return changes;
  }

  @override
  ListDiffAlgorithm withIdentityOnly(bool isIdentityOnly) {
    return WagnerFischerDiff(isIdentityOnly: isIdentityOnly ?? true);
  }
}

// We can adapt the algorithm to use less space, O(m) instead of O(mn),
// since it only requires that the previous row and current row be stored at any one time
class Row<E extends Object> {
  /// Each slot is a collection of Change
  List<ListDiffs<E>> slots = [];
  ListDiffArguments<E> args;

  List<E> get original => args.original;
  List<E> get replacement => args.replacement;

  Row(this.args);

  /// Seed with .insert from new
  seed(List<E> seedArray) {
    slots = List<ListDiffs<E>>.generate(seedArray.length + 1, (_) => ListDiffs.builder(args));
    // Each slot increases in the number of changes
    var index = 0;
    seedArray.forEach((item) {
      final slotIndex = index + 1;
      slots[slotIndex] = combine(
        slot: slots[slotIndex - 1],
        change: InsertDiff<E>(args, index, 1, [item]),
      );
      index++;
    });
  }

  /// Reset with empty slots
  /// First slot is .delete
  reset({int count, int indexInOld, E oldItem}) {
    if (slots.isNotEmpty != true) {
      slots = <ListDiffs<E>>[];
      for (var x = 0; x < count; x++) {
        /// Add old/new
        slots.add(ListDiffs.builder(args));
      }
    }

    slots[0] = combine(
      slot: slots[0],
      change: DeleteDiff<E>(args, indexInOld, 1),
    );
  }

  /// Use .replace from previousRow
  update({int indexInNew, Row<E> previousRow}) {
    final slotIndex = indexInNew + 1;
    slots[slotIndex] = previousRow.slots[slotIndex - 1];
  }

  /// Choose the min
  updateWithMin({Row<E> previousRow, int indexInNew, E newItem, int indexInOld, E oldItem}) {
    final slotIndex = indexInNew + 1;
    final topSlot = previousRow.slots[slotIndex];
    final leftSlot = slots[slotIndex - 1];
    final topLeftSlot = previousRow.slots[slotIndex - 1];

    final minCount = min(min(topSlot.length, leftSlot.length), topLeftSlot.length);

    // Order of cases does not matter

    if (minCount == topSlot.length) {
      slots[slotIndex] = combine(
        slot: topSlot,
        change: DeleteDiff<E>(args, indexInOld, 1),
      );
    } else if (minCount == leftSlot.length) {
      slots[slotIndex] = combine(
        slot: leftSlot,
        change: InsertDiff<E>(args, indexInNew, 1, [newItem]),
      );
    } else if (minCount == topLeftSlot.length) {
      slots[slotIndex] = combine(
        slot: topLeftSlot,
        change: ReplaceDiff(args, indexInNew, 1, [newItem]),
      );
    } else {
      throw "Bad algorithm.  Please try again";
    }
  }

  /// Add one more change
  ListDiffs<E> combine({ListDiffs<E> slot, ListDiff<E> change}) {
    return ListDiffs<E>.ofOperations([...slot, change].toList(growable: false), args);
  }

  //// Last slot
  ListDiffs<E> lastSlot() {
    return slots.last;
  }
}
