import 'package:collection/collection.dart';
import 'package:collection_diff/diff_equality.dart';
import 'package:uuid/uuid.dart';

enum MapDiffType { unset, change, set }

class MapDiff<K, V> {
  final K key;
  final V value;
  final V oldValue;
  final MapDiffType type;
  final MapDiffArguments<K, V> args;

  const MapDiff(this.args, this.type, this.key, this.value, this.oldValue)
      : assert(type != null),
        assert(args != null),
        assert(key != null);

  const MapDiff.set(this.args, this.key, this.value)
      : type = MapDiffType.set,
        oldValue = null,
        assert(args != null),
        assert(key != null);

  const MapDiff.unset(this.args, this.key, this.oldValue)
      : type = MapDiffType.unset,
        value = null,
        assert(args != null),
        assert(key != null);

  const MapDiff.change(this.args, this.key, this.value, this.oldValue)
      : type = MapDiffType.change,
        assert(args != null),
        assert(key != null);

  @override
  String toString() {
    return "${this.runtimeType} type: $type, key: $key, value: $value";
  }

  MapDiff<KK, VV> recast<KK, VV>(MapDiffArguments<KK, VV> args) {
    return MapDiff(args, this.type, key as KK, value as VV, oldValue as VV);
  }
}

class MapDiffArguments<K, V> {
  final Map<K, V> original;
  final Map<K, V> replacement;
  final DiffEquality keyEquality;
  final DiffEquality valueEquality;
  final bool checkValues;
  final String debugName;
  final String id;

  MapDiffArguments(this.original, this.replacement,
      {bool checkValues,
      DiffEquality keyEquality,
      DiffEquality valueEquality,
      this.debugName,
      String id})
      : id = id ?? Uuid().v4(),
        assert(original != null),
        assert(replacement != null),
        checkValues = checkValues ?? true,
        keyEquality = keyEquality ?? DiffEquality(),
        valueEquality = valueEquality ?? DiffEquality();

  /// Performs a defensive copy of the input maps in case they are not safe for crossing isolate boundaries
  MapDiffArguments.copied(Map<K, V> original, Map<K, V> replacement,
      {String debugName,
      String id,
      bool checkValues = true,
      DiffEquality keyEquality,
      DiffEquality valueEquality})
      : this({...?original}, {...?replacement},
            checkValues: checkValues,
            keyEquality: keyEquality,
            valueEquality: valueEquality,
            id: id,
            debugName: debugName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapDiffArguments &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MapDiffs<K, V> extends DelegatingList<MapDiff<K, V>> {
  final MapDiffArguments<K, V> args;
  final List<MapDiff<K, V>> operations;

  MapDiffs.empty(this.args)
      : operations = const [],
        super(const []);

  MapDiffs.ofOperations(this.operations, this.args) : super(operations);

  MapDiffs.builder(Map<K, V> source,
      {Map<K, V> replacement,
      bool checkValues,
      DiffEquality keyEquality,
      DiffEquality valueEquality})
      : this.ofOperations(
          <MapDiff<K, V>>[],
          MapDiffArguments(source, replacement ?? source,
              checkValues: checkValues,
              keyEquality: keyEquality,
              valueEquality: valueEquality),
        );

  MapDiffs.args(MapDiffArguments<K, V> args)
      : this.ofOperations(<MapDiff<K, V>>[], args);

  Map<K, V> get original => args.original;

  Map<K, V> get replacement => args.replacement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapDiffs &&
          runtimeType == other.runtimeType &&
          args == other.args;

  @override
  int get hashCode => args.hashCode;
}
