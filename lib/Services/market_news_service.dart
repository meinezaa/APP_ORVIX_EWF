import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MarketNewsArticle {
  final String slug;
  final String title;
  final String category;
  final String summary;
  final List<String> contentParagraphs;
  final String? imageUrl;
  final DateTime? publishedAt;
  final Uri articleUri;
  final String source;

  const MarketNewsArticle({
    required this.slug,
    required this.title,
    required this.category,
    required this.summary,
    required this.contentParagraphs,
    required this.imageUrl,
    required this.publishedAt,
    required this.articleUri,
    required this.source,
  });
}

abstract final class MarketNewsService {
  static const _ewfWebsite = 'https://www.equityworld-futures.com';
  static const _newsMakerWebsite = 'https://www.newsmaker.id';

  static Future<List<MarketNewsArticle>> fetchLatest({
    required String languageCode,
  }) async {
    final responses = await Future.wait([
      _tryFetch(() => _fetchEwfArticles(languageCode)),
      _tryFetch(() => _fetchNewsMakerArticles(languageCode)),
    ]);
    final ewfArticles = responses[0].articles;
    final newsMakerArticles = responses[1].articles;

    if (ewfArticles == null && newsMakerArticles == null) {
      throw Exception(
        'Unable to load news from EWF (${responses[0].error}) or NewsMaker (${responses[1].error}).',
      );
    }

    final newsMakerBySlug = {
      for (final article in newsMakerArticles ?? <MarketNewsArticle>[])
        article.slug: article,
    };
    final merged = <MarketNewsArticle>[];
    final includedSlugs = <String>{};

    for (final article in ewfArticles ?? <MarketNewsArticle>[]) {
      final localizedArticle = newsMakerBySlug[article.slug];
      merged.add(
        MarketNewsArticle(
          slug: article.slug,
          title: localizedArticle?.title ?? article.title,
          category: localizedArticle?.category ?? article.category,
          summary: languageCode == 'en'
              ? localizedArticle?.summary.ifEmpty(article.summary) ??
                    article.summary
              : localizedArticle?.summary ?? '',
          contentParagraphs:
              languageCode == 'en' && article.contentParagraphs.isNotEmpty
              ? article.contentParagraphs
              : const [],
          imageUrl: article.imageUrl ?? localizedArticle?.imageUrl,
          publishedAt: article.publishedAt ?? localizedArticle?.publishedAt,
          articleUri:
              localizedArticle?.articleUri ??
              _localizedArticleUri(article.articleUri, languageCode),
          source: 'EWF',
        ),
      );
      includedSlugs.add(article.slug);
    }

    for (final article in newsMakerArticles ?? <MarketNewsArticle>[]) {
      if (includedSlugs.add(article.slug)) {
        merged.add(article);
      }
    }
    if (languageCode == 'en') return merged;
    return Future.wait(merged.map(_addLocalizedSummary));
  }

  static Future<MarketNewsArticle> fetchArticleDetails(
    MarketNewsArticle article, {
    required String languageCode,
  }) async {
    final localizedUri = _localizedArticleUri(article.articleUri, languageCode);
    try {
      final page = await _getText(localizedUri);
      final paragraphs = _newsMakerPageParagraphs(page);
      if (paragraphs.isNotEmpty) {
        return MarketNewsArticle(
          slug: article.slug,
          title: article.title,
          category: article.category,
          summary: paragraphs.first,
          contentParagraphs: paragraphs,
          imageUrl: article.imageUrl,
          publishedAt: article.publishedAt,
          articleUri: localizedUri,
          source: article.source,
        );
      }
    } on Exception {
      if (languageCode != 'en' && article.contentParagraphs.isEmpty) rethrow;
    }

    if (article.contentParagraphs.isNotEmpty) {
      return article;
    }
    if (languageCode != 'en') {
      throw const FormatException(
        'Localized article text is not available from the news source.',
      );
    }

    final uri = Uri.https(
      'www.equityworld-futures.com',
      '/api/portalnews/${Uri.encodeComponent(article.slug)}',
    );
    final payload = await _getJson(uri);
    final row = _map(payload['data']);
    if (row.isEmpty) {
      throw const FormatException(
        'Article detail is missing from the response.',
      );
    }

    final titleMap = _map(row['titles']);
    final translatedTitle = languageCode == 'en'
        ? _string(row['title_en']).ifEmpty(_string(titleMap['en']))
        : _string(row['title_id']).ifEmpty(_string(titleMap['id']));
    final paragraphs = _htmlParagraphs(_string(row['content']));
    final images = row['images'] is List
        ? row['images'] as List
        : const <dynamic>[];
    final imageUrl = _string(
      row['image'],
    ).ifEmpty(images.isEmpty ? '' : _string(images.first));
    final category = _string(
      row['category'],
    ).ifEmpty(_string(_map(row['kategori'])['name']));

    return MarketNewsArticle(
      slug: article.slug,
      title: translatedTitle
          .ifEmpty(article.title)
          .ifEmpty(_string(row['title'])),
      category: category.ifEmpty(article.category),
      summary: article.summary.isNotEmpty
          ? article.summary
          : paragraphs.isNotEmpty
          ? paragraphs.first
          : '',
      contentParagraphs: paragraphs,
      imageUrl: article.imageUrl ?? (imageUrl.isEmpty ? null : imageUrl),
      publishedAt:
          article.publishedAt ??
          DateTime.tryParse(_string(row['created_at']))?.toLocal(),
      articleUri: localizedUri,
      source: article.source,
    );
  }

  static Future<MarketNewsArticle> _addLocalizedSummary(
    MarketNewsArticle article,
  ) async {
    if (article.summary.isNotEmpty) return article;
    try {
      final page = await _getText(article.articleUri);
      final paragraphs = _newsMakerPageParagraphs(page);
      if (paragraphs.isEmpty) return article;
      return MarketNewsArticle(
        slug: article.slug,
        title: article.title,
        category: article.category,
        summary: paragraphs.first,
        contentParagraphs: paragraphs,
        imageUrl: article.imageUrl,
        publishedAt: article.publishedAt,
        articleUri: article.articleUri,
        source: article.source,
      );
    } on Exception catch (error) {
      debugPrint(
        'Unable to load localized summary for ${article.slug}: $error',
      );
      return article;
    }
  }

  static Future<({List<MarketNewsArticle>? articles, Object? error})> _tryFetch(
    Future<List<MarketNewsArticle>> Function() fetch,
  ) async {
    try {
      return (articles: await fetch(), error: null);
    } on Exception catch (error) {
      return (articles: null, error: error);
    }
  }

  static Future<List<MarketNewsArticle>> _fetchEwfArticles(
    String languageCode,
  ) async {
    final uri = Uri.https('www.equityworld-futures.com', '/api/portalnews', {
      'per_page': '5',
      'sort_by': 'created_at',
      'order': 'desc',
    });
    final payload = await _getJson(uri);
    final rows = _dataRows(payload);
    if (rows.isEmpty) throw const FormatException('EWF returned no news.');

    return rows
        .map((row) {
          final slug = _string(row['slug']);
          final titles = _map(row['titles']);
          final title = languageCode == 'en'
              ? _string(row['title_en']).ifEmpty(_string(titles['en']))
              : _string(row['title_id']).ifEmpty(_string(titles['id']));
          final imageList = row['images'];
          final images = imageList is List ? imageList : const <dynamic>[];
          final image = _string(
            row['image'],
          ).ifEmpty(images.isNotEmpty ? _string(images.first) : '');
          final link = _string(row['link']);

          return MarketNewsArticle(
            slug: slug,
            title: title.ifEmpty(_string(row['title'])),
            category: _string(
              row['category'],
            ).ifEmpty(_string(_map(row['kategori'])['name'])),
            summary: _plainSummary(
              _string(
                row['summary'],
              ).ifEmpty(_firstParagraph(_string(row['content']))),
            ),
            contentParagraphs: languageCode == 'en'
                ? _htmlParagraphs(_string(row['content']))
                : const [],
            imageUrl: image.isEmpty ? null : image,
            publishedAt: DateTime.tryParse(
              _string(row['created_at']),
            )?.toLocal(),
            articleUri: _localizedArticleUri(
              _safeArticleUri(link, slug),
              languageCode,
            ),
            source: 'EWF',
          );
        })
        .where((article) => article.slug.isNotEmpty && article.title.isNotEmpty)
        .toList();
  }

  static Future<List<MarketNewsArticle>> _fetchNewsMakerArticles(
    String languageCode,
  ) async {
    final payload = await _getJson(
      Uri.https('www.newsmaker.id', '/api/ticker-news'),
    );
    final rows = _dataRows(payload);
    if (rows.isEmpty) {
      throw const FormatException('NewsMaker returned no news.');
    }

    return rows
        .map((row) {
          final slug = _string(row['slug']);
          final title = languageCode == 'en'
              ? _string(row['title_en'])
              : _string(row['title_id']);
          final categoryMap = _map(row['main_category']);
          final category = _string(
            categoryMap['name'],
          ).ifEmpty(_string(row['category']));

          return MarketNewsArticle(
            slug: slug,
            title: title.ifEmpty(_string(row['title'])),
            category: category,
            summary: languageCode == 'en'
                ? _plainSummary(_string(row['summary']))
                : '',
            contentParagraphs: const [],
            imageUrl:
                _string(row['image']).ifEmpty(_string(row['image_url'])).isEmpty
                ? null
                : _string(row['image']).ifEmpty(_string(row['image_url'])),
            publishedAt: DateTime.tryParse(
              _string(row['created_at']),
            )?.toLocal(),
            articleUri: _localizedArticleUri(
              _safeArticleUri(_string(row['link']), slug, category),
              languageCode,
            ),
            source: 'NewsMaker',
          );
        })
        .where((article) => article.slug.isNotEmpty && article.title.isNotEmpty)
        .toList();
  }

  static Future<Map<String, dynamic>> _getJson(Uri target) async {
    final body = await _getText(target);
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('News response is not a JSON object.');
    }
    return decoded;
  }

  static Future<String> _getText(Uri target) async {
    final uri = kIsWeb ? Uri.parse('https://r.jina.ai/$target') : target;
    final response = await http
        .get(
          uri,
          headers: {'Accept': kIsWeb ? 'text/plain' : 'application/json'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode} from $target');
    }
    var body = response.body;
    if (kIsWeb) {
      const marker = 'Markdown Content:\n';
      final markerIndex = body.indexOf(marker);
      if (markerIndex < 0) {
        throw const FormatException('News proxy returned an invalid response.');
      }
      body = body.substring(markerIndex + marker.length).trim();
    }
    return body;
  }

  static List<Map<String, dynamic>> _dataRows(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is! List) {
      throw const FormatException('News response has no article list.');
    }
    return data
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static String _string(dynamic value) => value?.toString().trim() ?? '';

  static Uri _safeArticleUri(String url, String slug, [String category = '']) {
    final parsed = Uri.tryParse(url);
    final host = parsed?.host.toLowerCase() ?? '';
    if (parsed != null &&
        parsed.scheme == 'https' &&
        (host == 'newsmaker.id' ||
            host.endsWith('.newsmaker.id') ||
            host == 'equityworld-futures.com' ||
            host.endsWith('.equityworld-futures.com'))) {
      return parsed;
    }

    if (slug.isEmpty) {
      return Uri.parse('$_ewfWebsite/analisis/berita');
    }

    final categorySlug = category.toLowerCase().replaceAll(' ', '-');
    final route = switch (categorySlug) {
      'gold' || 'oil' || 'silver' => 'news/commodity/$categorySlug/$slug',
      'market-update' => 'news/index/market-update/$slug',
      _ => 'economic-news/global-economy',
    };
    return Uri.parse('$_newsMakerWebsite/id/$route');
  }

  static Uri _localizedArticleUri(Uri uri, String languageCode) {
    final segments = [...uri.pathSegments];
    if (segments.isEmpty ||
        (segments.first != 'id' && segments.first != 'en')) {
      return uri;
    }
    segments[0] = languageCode == 'en' ? 'en' : 'id';
    return uri.replace(pathSegments: segments);
  }

  @visibleForTesting
  static List<String> parseNewsMakerPageForTesting(String page) =>
      _newsMakerPageParagraphs(page);

  static List<String> _newsMakerPageParagraphs(String page) {
    final normalizedPage = page
        .replaceAll(
          RegExp(r'</(?:p|div|li|h[1-6]|blockquote)\s*>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]*\)'), r'$1')
        .replaceAll(RegExp(r'<[^>]*>'), '');
    final lines = normalizedPage
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final paragraphs = <String>[];
    var readingArticle = false;
    for (final line in lines) {
      if (RegExp(
        r'^(sumber|source)\s*:',
        caseSensitive: false,
      ).hasMatch(line)) {
        if (readingArticle) break;
        readingArticle = true;
        continue;
      }
      if (!readingArticle ||
          line.startsWith('#') ||
          line.startsWith('URL Source:') ||
          line.startsWith('Title:') ||
          line == '* * *') {
        continue;
      }
      final text = _plainSummary(line);
      if (text.isNotEmpty) paragraphs.add(text);
    }
    return paragraphs;
  }

  static String _firstParagraph(String html) =>
      RegExp(
        r'<p\b[^>]*>(.*?)</p>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(html)?.group(1) ??
      '';

  static List<String> _htmlParagraphs(String html) {
    final matches = RegExp(
      r'<(?:p|h[1-6]|li|blockquote)\b[^>]*>(.*?)</(?:p|h[1-6]|li|blockquote)>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);
    final paragraphs = matches
        .map((match) => _plainSummary(match.group(1) ?? ''))
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();
    if (paragraphs.isNotEmpty) return paragraphs;

    final plainText = _plainSummary(html);
    return plainText.isEmpty ? const [] : [plainText];
  }

  static String _plainSummary(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
