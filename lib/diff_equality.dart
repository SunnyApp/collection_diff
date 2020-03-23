import 'package:collection/collection.dart';

/// Dart makes it difficult to pass function pointers across isolates.  [DiffEquality] provides a concrete implementation
/// of equality comparators that can be used safely across isolate boundaries.
///
/// Keep in mind that any implementation of [DiffDelegate] cannot itself have any member properties or sub-properties
/// that are function pointers.
///
/// This library also provides two interfaces that can be applied to the diff inputs themselves:
/// [Diffable] can be used when the objects being diffed can be passed across isolate boundaries.
/// [DiffDelegate] can be used when the objects cannot be passed across isolate boundaries.
///
abstract class DiffEquality {
  const factory DiffEquality() = DiffableEquality;
  const factory DiffEquality.ofEquality(
      [Equality _identity, Equality _equality]) = _DiffEquality;
  const factory DiffEquality.diffable(
      {Equality fallbackIdentity, Equality fallbackEquals}) = DiffableEquality;

  /// Whether the two items being compared have the same identity, for example two records with the same primary
  /// key.  This check is used to determine if an item should be removed or added to a list, rather than updated.
  ///
  /// The [areEqual] check is used to determine if the item has changed.
  bool areIdentical(a, b);

  /// Determines whether two records have the same state.  See [areIdentical] for a check that two records represent
  /// the same resource.
  bool areEqual(a, b);

  int hash(a);
}

enum DiffComparison { equal, identicalNotEqual, notIdentical }

/// Default implementation that uses [Equality] instance behind the scenes.
class _DiffEquality implements DiffEquality {
  const _DiffEquality([Equality identity, Equality equality])
      : _identity = identity ?? DiffableEquality.identityEquality,
        _equality = equality ?? identity ?? DiffableEquality.equality;

  final Equality _identity;
  final Equality _equality;

  @override
  bool areEqual(a, b) => (_equality ?? _identity).equals(a, b);

  @override
  bool areIdentical(a, b) => _identity.equals(a, b);

  @override
  int hash(a) => _identity.hash(a);
}

/// Used when the objects being compared can pass safely across isolate boundaries.  If the object being
/// compared cannot safely cross isolate boundaries, then use [DiffDelegate] instead.
abstract class Diffable {
  factory Diffable.ofValues(diffKey, [diffSource]) {
    return _DiffDelegate(diffKey, diffSource);
  }

  bool diffEquals(dynamic other);

  bool diffIdentical(dynamic other);

  int get diffHashCode;
}

class _DiffDelegate implements DiffDelegate {
  final dynamic diffKey;
  final dynamic diffSource;

  const _DiffDelegate(this.diffKey, [dynamic diffSource])
      : assert(diffKey != null),
        diffSource = diffSource ?? diffKey;

  @override
  bool diffEquals(dynamic other) {
    return diffSource == (other as DiffDelegate).diffSource;
  }

  @override
  bool diffIdentical(dynamic other) {
    return diffKey == (other as DiffDelegate).diffKey;
  }

  @override
  int get diffHashCode => diffKey?.hashCode ?? 0;
}

abstract class DiffDelegate implements Diffable {
  const DiffDelegate();

  const factory DiffDelegate.of(dynamic diffKey, [dynamic diffSource]) =
      _DiffDelegate;

  dynamic get diffKey;

  dynamic get diffSource;

  bool diffEquals(dynamic other) {
    return diffSource == (other as DiffDelegate).diffSource;
  }

  bool diffIdentical(dynamic other) {
    return diffKey == (other as DiffDelegate).diffKey;
  }

  @override
  int get diffHashCode => diffKey?.hashCode ?? 0;
}

/// Mixin that converts an entity to DiffDelegate by using the existing hashCode and equals methods
mixin DiffDelegateMixin implements DiffDelegate {
  dynamic get diffKey;

  dynamic get diffSource => this;

  @override
  bool diffEquals(dynamic other) {
    return diffSource == (other as DiffDelegate).diffSource;
  }

  @override
  bool diffIdentical(dynamic other) {
    return diffKey == (other as DiffDelegate).diffKey;
  }

  @override
  int get diffHashCode => diffKey?.hashCode ?? 0;
}

/// Mixin that converts an entity to diffable by using the existing hashCode and equals methods
mixin DiffableMixin implements Diffable {
  @override
  bool diffEquals(dynamic other) {
    return this == other;
  }

  @override
  bool diffIdentical(dynamic other) {
    return this == other;
  }

  @override
  int get diffHashCode => hashCode;
}

/// A specialized [DiffEquality] implementation that checks whether either object is `Diffable` and uses the delegate
/// check.  If neither instance is [Diffable], a fallback [Equality] is used
class DiffableEquality implements DiffEquality {
  final Equality fallbackEquals;
  final Equality fallbackIdentity;

  const DiffableEquality(
      {this.fallbackEquals = const Equality(),
      this.fallbackIdentity = const Equality()})
      : assert(fallbackEquals != null),
        assert(fallbackIdentity != null);

  @override
  int hash(e) {
    if (e is Diffable) {
      return e.diffHashCode;
    } else {
      return e?.hashCode ?? 0;
    }
  }

  @override
  bool areEqual(a, b) {
    if (a is Diffable) {
      return a.diffEquals(b);
    } else if (b is Diffable) {
      return b.diffEquals(a);
    }
    return fallbackEquals.equals(a, b);
  }

  @override
  bool areIdentical(a, b) {
    if (a is Diffable) {
      return a.diffIdentical(b);
    } else if (b is Diffable) {
      return b.diffIdentical(a);
    }
    return fallbackIdentity.equals(a, b);
  }

  static const identityEquality = EqualityFromDiffable.identity();
  static const equality = EqualityFromDiffable.equals();
}

extension DiffEqualityExtension on DiffEquality {
  Equality asEquality() => EqualityFromDiffable.equals(this);
  Equality asIdentityEquality() => EqualityFromDiffable.identity(this);

  DiffComparison diffCompare(a, b) {
    if (!areIdentical(a, b)) {
      return DiffComparison.notIdentical;
    } else if (areEqual(a, b)) {
      return DiffComparison.equal;
    } else {
      return DiffComparison.identicalNotEqual;
    }
  }
}

extension DiffableExtension on DiffDelegate {
  /// A complex class might implement DiffDelegate, this copies values into a simple implementation so it
  /// can more easily cross isolate boundaries
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

/// Equality implementation based on diffables.
class EqualityFromDiffable implements Equality {
  final DiffEquality diffEquality;
  final bool isIdentity;

  const EqualityFromDiffable.equals([this.diffEquality = const DiffEquality()])
      : isIdentity = false;

  const EqualityFromDiffable.identity(
      [this.diffEquality = const DiffEquality()])
      : isIdentity = true;

  @override
  bool equals(e1, e2) => isIdentity
      ? diffEquality.areIdentical(e1, e2)
      : diffEquality.areEqual(e1, e2);

  @override
  int hash(e) => diffEquality.hash(e);

  @override
  bool isValidKey(Object e) => true;
}
