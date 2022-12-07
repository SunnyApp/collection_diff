import 'package:collection_diff/list_diff_model.dart';
import 'package:collection_diff/set_diff_model.dart';

/// Looks for empty lists, which may signal an easier diff operation
ListDiffs<T>? preprocessListDiff<T>(ListDiffArguments<T> args) {
  final oldIsEmpty = args.original.isEmpty;
  final newIsEmpty = args.replacement.isEmpty;

  if (oldIsEmpty && newIsEmpty) {
    return ListDiffs<T>.empty(args);
  }

  if (oldIsEmpty) {
    return ListDiffs.ofOperations(
        [InsertDiff(args, 0, args.original.length, args.replacement)], args);
  }

  if (newIsEmpty) {
    return ListDiffs.ofOperations(
        [DeleteDiff(args, 0, args.original.length)], args);
  }

  return null;
}

SetDiffs<T>? preprocessSetDiff<T>(SetDiffArguments<T> args) {
  final oldIsEmpty = args.original.isEmpty;
  final newIsEmpty = args.replacement.isEmpty;

  if (oldIsEmpty && newIsEmpty) {
    return SetDiffs<T>.empty(args);
  }

  if (oldIsEmpty) {
    final replacement = args.replacement.toSet();
    return SetDiffs.ofOperations(
        [SetDiff.add(args, replacement)], replacement, args);
  }

  if (newIsEmpty) {
    final replacement = args.original.toSet();
    return SetDiffs.ofOperations(
        [SetDiff.remove(args, replacement)], replacement, args);
  }

  return null;
}
