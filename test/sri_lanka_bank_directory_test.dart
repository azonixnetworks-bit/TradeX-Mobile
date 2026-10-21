import 'package:flutter_test/flutter_test.dart';
import 'package:tradex_mobile/features/profile/data/sri_lanka_bank_directory.dart';

void main() {
  test('bank suggestions support partial names and abbreviations', () {
    expect(
      SriLankaBankDirectory.bankSuggestions('Com'),
      contains('Commercial Bank of Ceylon PLC'),
    );
    expect(
      SriLankaBankDirectory.bankSuggestions('HNB'),
      contains('Hatton National Bank PLC'),
    );
    expect(
      SriLankaBankDirectory.bankSuggestions('BOC'),
      contains('Bank of Ceylon'),
    );
  });

  test(
    'recognized bank branches are prioritized while global matches remain',
    () {
      final suggestions = SriLankaBankDirectory.branchSuggestions(
        bankName: 'NDB',
        query: 'Kan',
      ).toList();
      expect(suggestions, isNotEmpty);
      expect(suggestions.first, 'Kandy Branch');
    },
  );

  test(
    'unknown manual bank and branch values are not rejected by directory',
    () {
      expect(
        SriLankaBankDirectory.bankSuggestions('Custom Rural Bank'),
        isEmpty,
      );
      expect(
        SriLankaBankDirectory.branchSuggestions(
          bankName: 'Custom Rural Bank',
          query: 'Unlisted',
        ),
        isEmpty,
      );
    },
  );
}
