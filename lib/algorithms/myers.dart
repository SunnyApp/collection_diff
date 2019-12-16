import 'package:collection_diff/diff_algorithm.dart';
import 'package:collection_diff/diff_model.dart';

class MyersDiff implements DiffAlgorithm {
  const MyersDiff();

  @override
  Diffs<E> execute<E>(DiffArguments<E> args) {
    final List<E> oldList = args.oldList;
    final List<E> newList = args.newList;

    if (identical(oldList, newList)) return Diffs.empty(args);

    final oldSize = oldList.length;
    final newSize = newList.length;

    if (oldSize == 0) {
      return args.result([InsertDiff(args, 0, newSize, newList)]);
    }

    if (newSize == 0) {
      return Diffs.ofOperations([DeleteDiff(args, 0, oldSize)], args);
    }

    final path = _buildPath(args);
    final diffs = _buildPatch(path, args)..sort();
    return args.result(diffs.reversed.toList(growable: false));
  }
}

PathNode _buildPath<E>(DiffArguments<E> args) {
  final oldList = args.oldList;
  final newList = args.newList;
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
      if ((k == -d) || (k != d && diagonal[kminus].originIndex < diagonal[kplus].originIndex)) {
        i = diagonal[kplus].originIndex;
        prev = diagonal[kplus];
      } else {
        i = diagonal[kminus].originIndex + 1;
        prev = diagonal[kminus];
      }

      diagonal[kminus] = null;

      int j = i - k;

      PathNode node = DiffNode(i, j, prev);

      while (i < oldSize && j < newSize && args.areEqual(oldList[i], newList[j])) {
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

List<ListDiff<E>> _buildPatch<E>(PathNode path, DiffArguments<E> args) {
  final oldList = args.oldList;
  final newList = args.newList;
  if (path == null) throw ArgumentError("path is null");

  final List<ListDiff<E>> diffs = [];
  if (path is Snake) {
    path = path.previousNode;
  }
  while (path != null && path.previousNode != null && path.previousNode.revisedIndex >= 0) {
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
      diffs.add(ReplaceDiff(args, iAnchor, original.length, revised));
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

  PathNode get previousNode;

  bool get isBootStrap => originIndex < 0 || revisedIndex < 0;

  PathNode get previousSnake {
    if (isBootStrap) return null;
    if (this is! Snake && previousNode != null) return previousNode.previousSnake;
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

  DiffNode(this.originIndex, this.revisedIndex, PathNode previousNode) : previousNode = previousNode?.previousSnake;
}
