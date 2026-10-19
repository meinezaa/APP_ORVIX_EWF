import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';

class TradingViewChartCarousel extends StatefulWidget {
  const TradingViewChartCarousel({super.key});

  @override
  State<TradingViewChartCarousel> createState() =>
      _TradingViewChartCarouselState();
}

class _TradingViewChartCarouselState extends State<TradingViewChartCarousel> {
  static const _charts = [
    (
      title: 'Emas',
      symbol: 'OANDA:XAUUSD',
      description: 'Gold Spot / U.S. Dollar',
    ),
    (
      title: 'Hang Seng (HSI)',
      symbol: 'TVC:HSI',
      description: 'Hang Seng Index',
    ),
    (
      title: 'Nikkei (SNI)',
      symbol: 'TVC:NI225',
      description: 'Nikkei 225 Index',
    ),
  ];

  static const _timeframes = [
    (label: '1 menit', interval: '1'),
    (label: '5 menit', interval: '5'),
    (label: '15 menit', interval: '15'),
    (label: '30 menit', interval: '30'),
    (label: '1 jam', interval: '60'),
    (label: '4 jam', interval: '240'),
    (label: '1 hari', interval: 'D'),
    (label: '1 minggu', interval: 'W'),
    (label: '1 bulan', interval: 'M'),
  ];

  final PageController _pageController = PageController(viewportFraction: 0.94);
  int _currentPage = 0;
  int _selectedTimeframe = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.show_chart,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.text(context, 'Grafik Harga'),
                style: TextStyle(
                  color: AppTheme.text(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'TradingView',
                style: TextStyle(
                  color: AppTheme.mutedText(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _timeframes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final timeframe = _timeframes[index];
              final selected = _selectedTimeframe == index;
              return ChoiceChip(
                label: Text(AppStrings.text(context, timeframe.label)),
                selected: selected,
                onSelected: (_) => setState(() => _selectedTimeframe = index),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppTheme.text(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppTheme.surface(context),
                selectedColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.border(context),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: MediaQuery.sizeOf(context).width >= 600 ? 420 : 360,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _charts.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final chart = _charts[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _TradingViewChartCard(
                  title: AppStrings.text(context, chart.title),
                  symbol: chart.symbol,
                  description: AppStrings.text(context, chart.description),
                  interval: _timeframes[_selectedTimeframe].interval,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  languageCode: Localizations.localeOf(context).languageCode,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _charts.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFFD95B14)
                    : const Color(0xFFD7B6A2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TradingViewChartCard extends StatefulWidget {
  final String title;
  final String symbol;
  final String description;
  final String interval;
  final bool isDark;
  final String languageCode;

  const _TradingViewChartCard({
    required this.title,
    required this.symbol,
    required this.description,
    required this.interval,
    required this.isDark,
    required this.languageCode,
  });

  @override
  State<_TradingViewChartCard> createState() => _TradingViewChartCardState();
}

class _TradingViewChartCardState extends State<_TradingViewChartCard> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_loadChart());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TradingViewChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval ||
        oldWidget.isDark != widget.isDark ||
        oldWidget.languageCode != widget.languageCode) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
      unawaited(_loadChart());
    }
  }

  Future<void> _openTradingView() async {
    final uri = Uri.https('www.tradingview.com', '/chart/', {
      'symbol': widget.symbol,
      'interval': widget.interval,
      'theme': widget.isDark ? 'dark' : 'light',
      'locale': widget.languageCode,
    });
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka TradingView.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka TradingView: $error')),
        );
      }
    }
  }

  Future<void> _loadChart() async {
    final chartBackground = AppTheme.background(context);
    final connectionError = AppStrings.text(
      context,
      'Grafik gagal dimuat. Periksa koneksi internet.',
    );
    final genericError = AppStrings.text(context, 'Grafik gagal dimuat.');
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setBackgroundColor(chartBackground);
      await _controller.enableZoom(true);
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _loadError = connectionError;
              });
            }
          },
        ),
      );
      final chartUri = Uri.https('www.tradingview.com', '/chart/', {
        'symbol': widget.symbol,
        'interval': widget.interval,
        'theme': widget.isDark ? 'dark' : 'light',
        'locale': widget.languageCode,
      });
      await _controller.loadRequest(chartUri);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = '$genericError: $error';
        });
      }
    }
  }

  String _timeframeLabel(BuildContext context, String interval) {
    return AppStrings.text(context, switch (interval) {
      '1' => '1 menit',
      '5' => '5 menit',
      '15' => '15 menit',
      '30' => '30 menit',
      '60' => '1 jam',
      '240' => '4 jam',
      'D' => '1 hari',
      'W' => '1 minggu',
      'M' => '1 bulan',
      _ => interval,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.32),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D3D22).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.text(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${widget.description} · ${_timeframeLabel(context, widget.interval)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.mutedText(context),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _openTradingView,
                  icon: const Icon(Icons.open_in_new, size: 15),
                  label: Text(AppStrings.text(context, 'Buka')),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  ColoredBox(
                    color: AppTheme.surface(context),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                if (_loadError != null)
                  ColoredBox(
                    color: AppTheme.surface(context),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_off_outlined,
                              color: Color(0xFF9B8B81),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _loadError!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.text(context),
                                fontSize: 11,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _loadError = null;
                                });
                                unawaited(_loadChart());
                              },
                              child: Text(
                                AppStrings.text(context, 'Coba Lagi'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
