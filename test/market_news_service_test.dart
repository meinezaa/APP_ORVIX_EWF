import 'package:flutter_test/flutter_test.dart';
import 'package:app_pt_ewf/Services/market_news_service.dart';

void main() {
  group('NewsMaker article page parsing', () {
    test(
      'extracts Indonesian article paragraphs without source-page noise',
      () {
        const page = '''
Title: NewsMaker
Markdown Content:
# Saham Chip Rontok, Nasdaq Anjlok 2,5%

Sumber: Newsmaker.id

Bursa saham Amerika Serikat ditutup melemah pada perdagangan Jumat.

Tekanan terbesar datang dari saham teknologi dan semikonduktor.

Sumber: newsmaker.id

Bagikan
''';

        expect(MarketNewsService.parseNewsMakerPageForTesting(page), [
          'Bursa saham Amerika Serikat ditutup melemah pada perdagangan Jumat.',
          'Tekanan terbesar datang dari saham teknologi dan semikonduktor.',
        ]);
      },
    );

    test('extracts English article paragraphs from its localized page', () {
      const page = '''
Title: NewsMaker
Markdown Content:
# Chip Stocks Plunge

Source: Newsmaker.id

U.S. stock markets closed lower on Friday.

Semiconductor stocks led the decline.

Source: newsmaker.id

Share
''';

      expect(MarketNewsService.parseNewsMakerPageForTesting(page), [
        'U.S. stock markets closed lower on Friday.',
        'Semiconductor stocks led the decline.',
      ]);
    });
  });
}
