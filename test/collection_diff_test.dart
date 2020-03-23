import 'package:flutter_test/flutter_test.dart';

import 'list_diff_test.dart';
import 'map_diff_test.dart';
import 'set_diff_test.dart';

void main() {
  group("All Tests", () {
    myersDiffTests();
    wfgerDiffTests();
    mapDiffTests();
    setDiffTests();
  });
}
