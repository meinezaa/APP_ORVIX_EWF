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

    test('stops before footer and serialized page scripts', () {
      const page = '''
Title: NewsMaker
Markdown Content:
# Kabar Pasar Hari Ini

Sumber: Newsmaker.id

Pasar bergerak menguat pada perdagangan hari ini.

© 2026 News.Maker23 - Hak cipta dilindungi.

\$RB=[];\$RV=function(a)
''';

      expect(MarketNewsService.parseNewsMakerPageForTesting(page), [
        'Pasar bergerak menguat pada perdagangan hari ini.',
      ]);
    });

    test(
      'extracts article paragraphs from reader output without source labels',
      () {
        const page = '''
Title: News Maker 23 - Analysis

URL Source: https://newsmaker.id/id/analysis/example

Markdown Content:
Harga emas dunia kembali menunjukkan pemulihan pada perdagangan hari ini.

Pergerakan ini didukung oleh melemahnya dolar Amerika Serikat.

© 2026 News.Maker23 - Hak cipta dilindungi.
''';

        expect(MarketNewsService.parseNewsMakerPageForTesting(page), [
          'Harga emas dunia kembali menunjukkan pemulihan pada perdagangan hari ini.',
          'Pergerakan ini didukung oleh melemahnya dolar Amerika Serikat.',
        ]);
      },
    );

    test('does not treat valid prose starting with share as page chrome', () {
      const page = '''
Title: News Maker 23 - Analysis
Markdown Content:
Share prices climbed as investors reacted to the latest market data.

Trading activity remained strong throughout the session.
''';

      expect(MarketNewsService.parseNewsMakerPageForTesting(page), [
        'Share prices climbed as investors reacted to the latest market data.',
        'Trading activity remained strong throughout the session.',
      ]);
    });
  });
}
