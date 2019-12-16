import 'package:collection_diff/collection_diff.dart';

/// Looks for empty lists, which may signal an easier diff operation
Diffs<T> preprocess<T>(DiffArguments<T> args) {
  final oldIsEmpty = args.oldList.isEmpty;
  final newIsEmpty = args.newList.isEmpty;

  if (oldIsEmpty && newIsEmpty) {
    return Diffs<T>.empty(args);
  }

  if (oldIsEmpty) {
    return args.result([InsertDiff(args, 0, args.newList.length, args.newList)]);
  }

  if (newIsEmpty) {
    return args.result([DeleteDiff(args, 0, args.oldList.length)]);
  }

  return null;
}
