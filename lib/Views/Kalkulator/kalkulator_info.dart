import 'package:flutter/material.dart';
import '../../Services/app_strings.dart';
import '../../Services/app_theme.dart';

class KalkulatorInfoCard extends StatefulWidget {
  final String title;
  final String summary;
  final String details;

  const KalkulatorInfoCard({
    super.key,
    required this.title,
    required this.summary,
    required this.details,
  });

  @override
  State<KalkulatorInfoCard> createState() => _KalkulatorInfoCardState();
}

class _KalkulatorInfoCardState extends State<KalkulatorInfoCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFD8531D),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.text(context, 'Apa itu ${widget.title}?'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.text(
                    context,
                    _isExpanded ? widget.details : widget.summary,
                  ),
                  style: TextStyle(
                    color: AppTheme.mutedText(context),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                    ),
                    label: Text(
                      AppStrings.text(
                        context,
                        _isExpanded ? 'Tutup' : 'Baca selengkapnya',
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    iconAlignment: IconAlignment.end,
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
