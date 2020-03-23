import 'package:collection_diff/diff_algorithm.dart';
import 'package:collection_diff/diff_extensions.dart';
import 'package:collection_diff/list_diff_model.dart';

class MyersDiff implements ListDiffAlgorithm {
  final bool identityOnly;
  const MyersDiff([this.identityOnly = true]);

  @override
  ListDiffs<E> execute<E>(ListDiffArguments<E> args) {
    final List<E> oldList = args.original;
    final List<E> newList = args.replacement;

    if (identical(oldList, newList)) return ListDiffs<E>.empty(args);

    final oldSize = oldList.length;
    final newSize = newList.length;

    if (oldList.isEmpty && newList.isEmpty) return ListDiffs.empty(args);

    if (oldSize == 0) {
      return ListDiffs<E>.ofOperations(
          [InsertDiff(args, 0, newSize, newList)], args);
    }

    if (newSize == 0) {
      return ListDiffs<E>.ofOperations([DeleteDiff(args, 0, oldSize)], args);
    }

    final path = _buildPath(args, identityOnly);
    final diffs = _buildPatch(path, args)..sort();
    return ListDiffs<E>.ofOperations(
        diffs.reversed.toList(growable: false), args);
  }
}

PathNode _buildPath<E>(ListDiffArguments<E> args, bool identityOnly) {
  final oldList = args.original;
  final newList = args.replacement;
  final oldSize = oldList.length;
  final newSize = newList.length;

  final int max = oldSize + newSize + 1;
  final size = (2 * max) + 1;
  final int middle = size ~/ 2;
  final List<PathNode> diagonal = List(size);

  diagonal[middle + 1] = Snake(0, -1, null);
  for (int d = 0; d < max; d++) {
    for (int k = -d; k <= d; k += 2) {
      final int kmiddle = middle + k;
      final int kplus = kmiddle + 1;
      final int kminus = kmiddle - 1;
      PathNode prev;

      int i;
      if ((k == -d) ||
          (k != d &&
              diagonal[kminus].originIndex < diagonal[kplus].originIndex)) {
        i = diagonal[kplus].originIndex;
        prev = diagonal[kplus];
      } else {
        i = diagonal[kminus].originIndex + 1;
        prev = diagonal[kminus];
      }

      diagonal[kminus] = null;

      int j = i - k;

      PathNode node = DiffNode(i, j, prev);

      while (i < oldSize &&
          j < newSize &&
          (identityOnly
              ? args.identical(oldList[i], newList[j])
              : args.equal(oldList[i], newList[j]))) {
        i++;
        j++;
      }
      if (i > node.originIndex) {
        node = Snake(i, j, node);
      }

      diagonal[kmiddle] = node;

      if (i >= oldSize && j >= newSize) {
        return diagonal[kmiddle];
      }
    }
    diagonal[middle + d - 1] = null;
  }

  throw Exception();
}

List<ListDiff<E>> _buildPatch<E>(PathNode path, ListDiffArguments<E> args) {
  final oldList = args.original;
  final newList = args.replacement;
  if (path == null) throw ArgumentError("path is null");

  final List<ListDiff<E>> diffs = [];
  if (path is Snake) {
    path = path.previousNode;
  }
  while (path != null &&
      path.previousNode != null &&
      path.previousNode.revisedIndex >= 0) {
    if (path is Snake) throw Exception();
    int i = path.originIndex;
    int j = path.revisedIndex;

    path = path.previousNode;
    int iAnchor = path.originIndex;
    int jAnchor = path.revisedIndex;

    final original = oldList.sublist(iAnchor, i);
    final revised = newList.sublist(jAnchor, j);

    if (original.isEmpty && revised.isNotEmpty) {
      diffs.add(InsertDiff(args, iAnchor, revised.length, revised));
    } else if (original.isNotEmpty && revised.isEmpty) {
      diffs.add(DeleteDiff(args, iAnchor, original.length));
    } else {
      diffs.add(ReplaceDiff(args, iAnchor, revised.length, revised));
      final extra = original.length - revised.length;
      if (extra > 0) {
        diffs.add(DeleteDiff(args, iAnchor + revised.length, extra));
      }
//      diffs.add(ReplaceDiff(args, iAnchor, original.length, revised));
    }

    if (path is Snake) {
      path = path.previousNode;
    }
  }

  return diffs;
}

abstract class PathNode {
  int get originIndex;

  int get revisedIndex;

  bool isReplace;

  PathNode get previousNode;

  bool get isBootStrap => originIndex < 0 || revisedIndex < 0;

  PathNode get previousSnake {
    if (isBootStrap) return null;
    if (this is! Snake && previousNode != null) {
      return previousNode.previousSnake;
    }
    return this;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write("[");
    PathNode node = this;
    while (node != null) {
      buffer.write("(");
      buffer.write("${node.originIndex.toString()}");
      buffer.write(",");
      buffer.write("${node.revisedIndex.toString()}");
      buffer.write(")");
      node = node.previousNode;
    }
    buffer.write("]");
    return buffer.toString();
  }
}

class Snake extends PathNode {
  final int originIndex;
  final int revisedIndex;
  final PathNode previousNode;

  Snake(this.originIndex, this.revisedIndex, this.previousNode);
}

class DiffNode extends PathNode {
  final int originIndex;
  final int revisedIndex;
  final PathNode previousNode;

  DiffNode(this.originIndex, this.revisedIndex, PathNode previousNode)
      : previousNode = previousNode?.previousSnake;
}
