import 'package:flutter/material.dart';

class DetailPivotPoint extends StatelessWidget {
  final double pp, r1, r2, r3, r4, s1, s2, s3, s4;
  final VoidCallback onReset;
  final VoidCallback onDownload;

  const DetailPivotPoint({
    super.key,
    required this.pp,
    required this.r1,
    required this.r2,
    required this.r3,
    required this.r4,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.onReset,
    required this.onDownload,
  });

  String _format(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '$integer.${parts[1]}';
  }

  double _midpoint(double firstLevel, double secondLevel) {
    return (firstLevel + secondLevel) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD67236),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Formula & Hasil',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _card(
          'R4',
          'PP + (High - Low) x 3',
          r4,
          _midpoint(r4, r3),
          const Color(0xFFE8833A).withValues(alpha: 0.2),
          const Color(0xFFD85A63),
          const Color(0xFF8B2500),
        ),
        _card(
          'R3',
          'PP + (High - Low) x 2',
          r3,
          _midpoint(r3, r2),
          const Color(0xFFE8833A).withValues(alpha: 0.2),
          const Color(0xFFD85A63),
          const Color(0xFF8B2500),
        ),
        _card(
          'R2',
          'PP + (High - Low)',
          r2,
          _midpoint(r2, r1),
          const Color(0xFFE8833A).withValues(alpha: 0.2),
          const Color(0xFFD85A63),
          const Color(0xFF8B2500),
        ),
        _card(
          'R1',
          '2 x PP - Low',
          r1,
          _midpoint(r1, pp),
          const Color(0xFFE8833A).withValues(alpha: 0.2),
          const Color(0xFFD85A63),
          const Color(0xFF8B2500),
        ),
        _card(
          'PP',
          '(High + Low + Close) / 3',
          pp,
          _midpoint(pp, s1),
          const Color(0xFFD65F68),
          const Color(0xFF7F3F3F),
          const Color(0xFFD85A63),
          isPP: true,
        ),
        _card(
          'S1',
          '2 x PP - High',
          s1,
          _midpoint(s1, s2),
          const Color(0xFFE8833A).withValues(alpha: 0.2),
          const Color(0xFF10A83A),
          const Color(0xFFFF7A00),
        ),
        _card(
          'S2',
          'PP - (High - Low)',
          s2,
          _midpoint(s2, s3),
          const Color(0xFFE8833A).withValues(alpha: 0.2),
          const Color(0xFF10A83A),
          const Color(0xFFFF7A00),
        ),
        _card(
          'S3',
          'PP - (High - Low) x 2',
          s3,
          _midpoint(s3, s4),
          const Color(0xFFE8833A).withValues(alpha: 0.2),
          const Color(0xFF10A83A),
          const Color(0xFFFF7A00),
        ),
        _card(
          'S4',
          'PP - (High - Low) x 3',
          s4,
          _midpoint(s4, s3),
          const Color(0xFFE8833A).withValues(alpha: 0.2),
          const Color(0xFF10A83A),
          const Color(0xFFFF7A00),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_outlined, size: 19),
              label: const Text('Download'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD67236),
                side: const BorderSide(color: Color(0xFFD67236), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD67236),
                side: const BorderSide(color: Color(0xFFD67236), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
              child: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card(
    String label,
    String formula,
    double value,
    double midpoint,
    Color background,
    Color resultColor,
    Color midpointColor, {
    bool isPP = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: const BoxConstraints(minHeight: 148),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8833A).withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _box(
                label,
                width: 54,
                height: 48,
                textColor: isPP ? const Color(0xFFA83232) : Colors.black87,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _box(
                  formula,
                  height: 48,
                  textColor: isPP ? Colors.white : Colors.brown,
                  backgroundColor: isPP
                      ? Colors.white.withValues(alpha: 0.28)
                      : Colors.white,
                  borderColor: isPP
                      ? Colors.white.withValues(alpha: 0.75)
                      : Colors.brown.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _box(
                  _format(value),
                  height: 48,
                  textColor: resultColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 62),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: _box(
                        'midpoint',
                        height: 48,
                        textColor: isPP
                            ? const Color(0xFFEF2020)
                            : midpointColor,
                        fontSize: 14,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 22,
                      child: Icon(
                        Icons.arrow_forward,
                        color: isPP ? Colors.white : midpointColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _box(
                  _format(midpoint),
                  height: 48,
                  textColor: isPP ? const Color(0xFFEF2020) : midpointColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _box(
    String text, {
    double? width,
    double? height,
    required Color textColor,
    Color? backgroundColor,
    Color? borderColor,
    double fontSize = 14,
    int maxLines = 2,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? textColor.withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
