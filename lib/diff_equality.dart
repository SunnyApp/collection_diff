import 'package:collection/collection.dart';

/// Dart makes it difficult to pass function pointers across isolates.  We use a formal class [DiffEquality].  Keep in
/// mind that Dart won't allow you to create an implementation that delegates to function pointers.
///
/// The library also provides two interfaces that can be applied to the diff sources themselves:
/// [Diffable] can be used when the objects being diffed can be passed across isolate boundaries.
/// [DiffDelegate] can be used when the objects cannot be passed across isolate boundaries.
abstract class DiffEquality<E> {
  const DiffEquality();

  /// The fallback equality
  Equality get dartEquality => defaultEquality;

  factory DiffEquality.defaults() {
    return _DiffEquality();
  }

  bool areIdentical(final E first, final E second) {
    if (first == null || second == null) return false;
    if (first is Diffable) {
      return first.diffIdentical(second);
    } else if (second is Diffable) {
      return second.diffIdentical(first);
    }
    if (dartEquality.hash(first) != dartEquality.hash(second)) return false;
    return dartEquality.equals(first, second);
  }

  bool areEqual(E first, E second) {
    if (first == null || second == null) return false;
    if (first is Diffable) {
      return first.diffEquals(second);
    } else if (second is Diffable) {
      return second.diffEquals(first);
    }
    if (dartEquality.hash(first) != dartEquality.hash(second)) return false;
    return dartEquality.equals(first, second);
  }
}

final defaultEquality = DeepCollectionEquality.unordered();

class _DiffEquality<E> extends DiffEquality<E> {}

abstract class Diffable {
  factory Diffable.ofValues(diffKey, [diffSource]) {
    return _DiffDelegate(diffKey, diffSource);
  }

  bool diffEquals(dynamic other);

  bool diffIdentical(dynamic other);
}

class _DiffDelegate with DiffDelegateMixin {
  final dynamic diffKey;
  final dynamic diffSource;

  _DiffDelegate(this.diffKey, [dynamic diffSource])
      : assert(diffKey != null),
        diffSource = diffSource ?? diffKey;
}

abstract class DiffDelegate implements Diffable {
  const DiffDelegate();
  dynamic get diffKey;

  dynamic get diffSource;

  bool diffEquals(dynamic other) {
    return diffSource == (other as DiffDelegate)?.diffSource;
  }

  bool diffIdentical(dynamic other) {
    return diffKey == (other as DiffDelegate)?.diffKey;
  }
}

mixin DiffDelegateMixin implements DiffDelegate {
  dynamic get diffKey;

  dynamic get diffSource => this;

  bool diffEquals(dynamic other) {
    return diffSource == (other as DiffDelegate)?.diffSource;
  }

  bool diffIdentical(dynamic other) {
    return diffKey == (other as DiffDelegate)?.diffKey;
  }
}

mixin DiffableMixin implements Diffable {
  bool diffEquals(dynamic other) {
    return this == other;
  }

  bool diffIdentical(dynamic other) {
    return this == other;
  }
}
