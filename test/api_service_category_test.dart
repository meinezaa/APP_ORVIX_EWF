import 'package:flutter_test/flutter_test.dart';
import 'package:app_pt_ewf/Services/api_services.dart';

void main() {
  group('ApiService category normalization', () {
    test('maps NewsMaker categories to the expected app categories', () {
      expect(ApiService.normalizeCategoryName('LGD Daily'), 'LGD');
      expect(ApiService.normalizeCategoryName('HSI Daily'), 'HSI');
      expect(ApiService.normalizeCategoryName('SNI Daily'), 'SNI');
      expect(ApiService.normalizeCategoryName('USD/JPY'), 'SNI');
    });

    test(
      'parses NewsMaker number formats with comma and decimal separators',
      () {
        expect(ApiService.parseNumber('4,775.22'), 4775.22);
        expect(ApiService.parseNumber('4.775,22'), 4775.22);
        expect(ApiService.parseNumber('4332.30'), 4332.30);
      },
    );
  });
}
