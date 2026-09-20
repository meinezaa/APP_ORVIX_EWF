// ignore_for_file: file_names

import 'package:flutter/material.dart';

import 'pivot_point_live_view.dart';
import 'pp_detailHSI.dart';

class PivotPointListScreen extends StatelessWidget {
  const PivotPointListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PivotPointLiveView(
      category: 'LGD',
      onLgd: () {},
      onHsi: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const PivotPointHsiScreen()),
      ),
    );
  }
}
