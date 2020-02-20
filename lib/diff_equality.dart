import 'package:collection/collection.dart';

/// Dart makes it difficult to pass function pointers across isolates.  We use a formal class [DiffEquality].  Keep in
/// mind that Dart won't allow you to create an implementation that delegates to function pointers.
///
/// The library also provides two interfaces that can be applied to the diff sources themselves:
/// [Diffable] can be used when the objects being diffed can be passed across isolate boundaries.
/// [DiffDelegate] can be used when the objects cannot be passed across isolate boundaries.
///
class DiffEquality<E> {
  const DiffEquality({Equality<E> areIdentical, Equality<E> areEqual})
      : areIdentical = areIdentical ?? const DefaultDiffIdentical(),
        areEqual = areEqual ?? const DefaultDiffEquality();

  static DiffEquality<DiffDelegate> ofDiffDelegate() => const DiffEquality(
        areIdentical: DiffDelegateIdentity(),
        areEqual: DiffDelegateEquality(),
      );

  /// The fallback equality
  final Equality<E> areIdentical;
  final Equality<E> areEqual;
}

/// Used when the objects being compared can pass safely across isolate boundaries.  If the object being
/// compared cannot safely cross isolate boundaries, then use [DiffDelegate] instead.
abstract class Diffable {
  factory Diffable.ofValues(diffKey, [diffSource]) {
    return _DiffDelegate(diffKey, diffSource);
  }

  bool diffEquals(dynamic other);

  bool diffIdentical(dynamic other);

  int get equalityHashCode;
  int get identityHashCode;
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

  factory DiffDelegate.of(dynamic diffKey, [dynamic diffSource]) => _DiffDelegate(diffKey, diffSource);
  dynamic get diffKey;

  dynamic get diffSource;

  bool diffEquals(dynamic other) {
    return diffSource == (other as DiffDelegate).diffSource;
  }

  bool diffIdentical(dynamic other) {
    return diffKey == (other as DiffDelegate).diffKey;
  }

  int get identityHashCode => diffKey?.hashCode ?? 0;
  int get equalityHashCode => diffSource?.hashCode ?? 0;
}

mixin DiffDelegateMixin implements DiffDelegate {
  dynamic get diffKey;

  dynamic get diffSource => this;

  bool diffEquals(dynamic other) {
    return diffSource == (other as DiffDelegate).diffSource;
  }

  bool diffIdentical(dynamic other) {
    return diffKey == (other as DiffDelegate).diffKey;
  }

  int get identityHashCode => diffKey?.hashCode ?? 0;
  int get equalityHashCode => diffSource?.hashCode ?? 0;
}

mixin DiffableMixin implements Diffable {
  bool diffEquals(dynamic other) {
    return this == other;
  }

  bool diffIdentical(dynamic other) {
    return this == other;
  }

  int get equalityHashCode => hashCode;
  int get identityHashCode => hashCode;
}

class DiffDelegateEquality implements Equality<DiffDelegate> {
  const DiffDelegateEquality();

  @override
  bool equals(DiffDelegate first, DiffDelegate second) {
    if (first == null || second == null) return false;
    return first.diffSource == second.diffSource;
  }

  @override
  int hash(final DiffDelegate e) => e.diffSource.hashCode;

  @override
  bool isValidKey(Object o) => o is DiffDelegate;
}

class DiffDelegateIdentity implements Equality<DiffDelegate> {
  const DiffDelegateIdentity();

  @override
  bool equals(DiffDelegate first, DiffDelegate second) {
    if (first == null || second == null) return false;
    return first.diffKey == second.diffKey;
  }

  @override
  int hash(final DiffDelegate e) => e.diffKey.hashCode;

  @override
  bool isValidKey(Object o) => o is DiffDelegate;
}

class TypedDelegateEquality<T extends DiffDelegate> implements Equality<T> {
  final bool identityOnly;
  const TypedDelegateEquality.equals() : identityOnly = false;
  const TypedDelegateEquality.identity() : identityOnly = true;

  static DiffEquality<T> diffEquality<T extends DiffDelegate>() {
    return const DiffEquality(areIdentical: TypedDelegateEquality.identity(), areEqual: TypedDelegateEquality.equals());
  }

  static DiffEquality<T> diffIdentity<T extends DiffDelegate>() {
    return const DiffEquality(areIdentical: TypedDelegateEquality.equals(), areEqual: TypedDelegateEquality.equals());
  }

  @override
  bool equals(T first, T second) {
    if (first == null || second == null) return false;
    if (identityOnly) {
      return first.diffKey == second.diffKey;
    } else {
      return first.diffSource == second.diffSource;
    }
  }

  @override
  int hash(final DiffDelegate e) => e.diffKey.hashCode;

  @override
  bool isValidKey(Object o) => o is DiffDelegate;
}

class DefaultDiffEquality<E> implements Equality<E> {
  static const delegate = DeepCollectionEquality.unordered();

  const DefaultDiffEquality();

  @override
  bool equals(dynamic first, dynamic second) {
    if (first == null || second == null) return false;
    if (first is Diffable) {
      return first.diffEquals(second);
    } else if (second is Diffable) {
      return second.diffEquals(first);
    }
    return delegate.equals(first, second);
  }

  @override
  int hash(final dynamic e) => e is Diffable ? e.equalityHashCode : delegate.hash(e as Object);

  @override
  bool isValidKey(Object o) => delegate.isValidKey(o);
}

class DefaultDiffIdentical<E> implements Equality<E> {
  static const delegate = DeepCollectionEquality.unordered();

  const DefaultDiffIdentical();

  @override
  bool equals(dynamic first, dynamic second) {
    if (first == null || second == null) return false;
    if (first is Diffable) {
      return first.diffIdentical(second);
    } else if (second is Diffable) {
      return second.diffIdentical(first);
    }
    return delegate.equals(first, second);
  }

  @override
  int hash(final dynamic e) {
    return e is Diffable ? e.identityHashCode : delegate.hash(e as Object);
  }

  @override
  bool isValidKey(Object o) => o is Diffable || delegate.isValidKey(o);
}

extension DiffableExtension on DiffDelegate {
  /// Produces a simple delegate - this is a better target for crossing isolate boundaries
  DiffDelegate get delegate {
    final self = this;
    if (self == null) {
      return nullDelegate;
    }
    return _DiffDelegate(self.diffKey, self.diffSource);
  }
}

final nullDelegate = DiffDelegate.of(NullKey());

class NullKey {
  static const __ = NullKey._();
  const NullKey._();
  factory NullKey() {
    return __;
  }

  @override
  int get hashCode {
    return 0;
  }

  @override
  bool operator ==(other) {
    return other is NullKey;
  }
}
