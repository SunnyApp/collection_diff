import 'dart:math';

import 'package:collection_diff/algorithms/utils.dart';
import 'package:collection_diff/collection_diff.dart';
import 'package:collection_diff/diff_algorithm.dart';

class WagnerFischerDiff implements DiffAlgorithm {
  const WagnerFischerDiff();

  @override
  Diffs<E> execute<E>(final DiffArguments<E> args) {
    final original = args.oldList;
    final replacement = args.newList;

    final ppResult = preprocess<E>(args);
    if (ppResult != null) return ppResult;

    final previousRow = Row<E>(args);
    previousRow.seed(seedArray: replacement);
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
        if (args.areEqual(oldItem, newItem)) {
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
}

// We can adapt the algorithm to use less space, O(m) instead of O(mn),
// since it only requires that the previous row and current row be stored at any one time
class Row<E> {
  /// Each slot is a collection of Change
  List<Diffs<E>> slots = [];
  DiffArguments<E> args;

  List<E> get original => args.oldList;
  List<E> get replacement => args.newList;

  Row(this.args);

  /// Seed with .insert from new
  seed({List<E> seedArray}) {
    slots = List<Diffs<E>>(seedArray.length + 1);
    for (var i = 0; i < (seedArray.length + 1); i++) {
      slots[i] = Diffs.builder(args);
    }
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
    if (slots?.isNotEmpty != true) {
      slots = <Diffs<E>>[];
      for (var x = 0; x < count; x++) {
        /// Add old/new
        slots.add(Diffs.builder(args));
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
        change: DeleteDiff<E>(args, indexInNew, 1),
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
  Diffs<E> combine({Diffs<E> slot, ListDiff<E> change}) {
    return Diffs<E>.ofOperations([...slot, change].toList(growable: false), args);
  }

  //// Last slot
  Diffs<E> lastSlot() {
    return slots.last;
  }
}
