import 'package:flutter/material.dart';

class DetailPivotPoint extends StatelessWidget {
  final double pp, r1, r2, r3, r4, s1, s2, s3, s4;
  final VoidCallback onReset;
  final VoidCallback onDownload;
  final bool showActions;
  final bool showBranding;

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
    this.showActions = true,
    this.showBranding = false,
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
        if (showBranding) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/ewf_logo.png',
                  width: 72,
                  height: 64,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 18),
                Image.asset(
                  'assets/kepompong-logo.png',
                  width: 72,
                  height: 64,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            children: [
              _card(
                'R4',
                r4,
                _midpoint(r4, r3),
                const Color(0xFF174A9C),
                const Color(0xFF8B2500),
              ),
              _card(
                'R3',
                r3,
                _midpoint(r3, r2),
                const Color(0xFF174A9C),
                const Color(0xFF8B2500),
              ),
              _card(
                'R2',
                r2,
                _midpoint(r2, r1),
                const Color(0xFF174A9C),
                const Color(0xFF8B2500),
              ),
              _card(
                'R1',
                r1,
                _midpoint(r1, pp),
                const Color(0xFF174A9C),
                const Color(0xFF8B2500),
              ),
              _card(
                'PP',
                pp,
                _midpoint(pp, s1),
                const Color(0xFFA83232),
                const Color(0xFFD85A63),
              ),
              _card(
                'S1',
                s1,
                _midpoint(s1, s2),
                const Color(0xFF16823A),
                const Color(0xFFFF7A00),
              ),
              _card(
                'S2',
                s2,
                _midpoint(s2, s3),
                const Color(0xFF16823A),
                const Color(0xFFFF7A00),
              ),
              _card(
                'S3',
                s3,
                _midpoint(s3, s4),
                const Color(0xFF16823A),
                const Color(0xFFFF7A00),
              ),
              _card(
                'S4',
                s4,
                _midpoint(s4, s3),
                const Color(0xFF16823A),
                const Color(0xFFFF7A00),
                showMidpoint: false,
              ),
            ],
          ),
        ),
        if (showActions) ...[
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
      ],
    );
  }

  Widget _card(
    String label,
    double value,
    double midpoint,
    Color levelColor,
    Color midpointColor, {
    bool showMidpoint = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  label,
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFF888888)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    _format(value),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF6E2016),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showMidpoint) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    'midpoint',
                    style: TextStyle(color: midpointColor, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Text(
                    _format(midpoint),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: const Color(0xFF6E2016),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
