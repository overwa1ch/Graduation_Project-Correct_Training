import 'package:aiwa_core/fit_application/fit_application.dart';

class FixedIdGenerator implements IdGenerator {
  int _counter = 0;
  final String prefix;

  FixedIdGenerator({this.prefix = 'id'});

  @override
  String newId() {
    _counter += 1;
    return '$prefix-$_counter';
  }
}
