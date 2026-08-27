import 'package:flutter/material.dart';

class NotifikasiModel {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final String group;
  bool isRead;

  NotifikasiModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.isRead,
    required this.group,
  });
}
