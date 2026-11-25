import 'package:mdosthi_app/welbeing/wellbeing_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeBool handles bool, int, and string values', () {
    expect(WellbeingService.normalizeBool(true), isTrue);
    expect(WellbeingService.normalizeBool(1), isTrue);
    expect(WellbeingService.normalizeBool(0), isFalse);
    expect(WellbeingService.normalizeBool('true'), isTrue);
    expect(WellbeingService.normalizeBool('0'), isFalse);
  });
}
