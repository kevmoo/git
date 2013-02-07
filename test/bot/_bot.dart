library test_bot;

import 'dart:math' as math;
import 'package:bot/bot.dart';
import 'package:bot/bot_test.dart';
import 'package:unittest/unittest.dart';

part 'test_cloneable.dart';
part 'test_tuple.dart';

part 'events/test_events.dart';

part 'collection/test_collection_util.dart';
part 'collection/test_enumerable.dart';
part 'collection/test_list_base.dart';
part 'collection/test_number_enumerable.dart';
part 'collection/test_array_2d.dart';

part 'test_util.dart';
part 'math/test_coordinate.dart';
part 'math/test_vector.dart';
part 'math/test_affine_transform.dart';
part 'math/test_rect.dart';
part 'graph/test_tarjan.dart';

part 'color/test_rgb_color.dart';
part 'color/test_hsl_color.dart';

part 'attached/test_property_event_integration.dart';
part 'attached/test_properties.dart';

part 'attached/test_attached_events.dart';

void main() {
  group('bot', (){
    TestTuple.run();
    TestEnumerable.run();
    TestListBase.run();
    TestNumberEnumerable.run();
    TestCollectionUtil.run();
    TestArray2d.run();

    TestCoordinate.run();
    TestBox.run();
    TestVector.run();
    TestAffineTransform.run();

    TestUtil.run();
    TestCloneable.run();
    TestEvents.run();

    TestTarjanCycleDetect.run();

    TestRgbColor.run();
    TestHslColor.run();

    test('StringReader', _testStringReader);

    group('attached', (){
      TestAttachedEvents.run();
      TestProperties.run();
      TestPropertyEventIntegration.run();
    });
  });
}


void _testStringReader() {
  _verifyValues('', [''], null);
  _verifyValues('Shanna', ['Shanna'], null);
  _verifyValues('Shanna\n', ['Shanna',''], null);
  _verifyValues('\nShanna\n', ['', 'Shanna',''], null);
  _verifyValues('\r\nShanna\n', ['', 'Shanna',''], null);
  _verifyValues('\r\nShanna\r\n', ['', 'Shanna',''], null);
  _verifyValues('\rShanna\r\n', ['\rShanna',''], null);

  // a bit crazy. \r not before \n is not counted as a newline
  _verifyValues('\r\n\r\n\r\r\n\n', ['','','\r','',''], null);

  _verifyValues('line1\nline2\n\nthis\nis\the\rest\n',
      ['line1','line2',''], 'this\nis\the\rest\n');

}

void _verifyValues(String input, List<String> output, String rest) {
  final sr = new StringLineReader(input);
  for(final value in output) {
    expect(sr.readNextLine(), value);
  }
  expect(sr.readToEnd(), rest, reason: 'rest did not match');
  expect(sr.readNextLine(), null, reason: 'future nextLines should be null');
  expect(sr.readToEnd(), null, reason: 'future readToEnd should be null');
}
