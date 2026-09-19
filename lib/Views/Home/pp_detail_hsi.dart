import 'package:flutter/material.dart';

import 'pivot_point_live_view.dart';
import 'pp_detail_lgd.dart';

class PivotPointHsiScreen extends StatelessWidget {
  const PivotPointHsiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PivotPointLiveView(
      category: 'HSI',
      onLgd: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const PivotPointListScreen()),
      ),
      onHsi: () {},
    );
  }
}
