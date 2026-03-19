import 'dart:io';

import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.radius, this.name, this.imagePath});

  final double radius;
  final String? name;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final provider = _imageProvider(imagePath);
    final initials = _initials(name);

    if (provider != null) {
      return CircleAvatar(radius: radius, backgroundImage: provider);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _seedColor(name),
      child: initials.isEmpty
          ? Icon(Icons.person_rounded, size: radius, color: Colors.white)
          : Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.7,
              ),
            ),
    );
  }

  ImageProvider<Object>? _imageProvider(String? path) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return NetworkImage(value);
    }

    if (_isAbsoluteFilePath(value)) {
      final file = File(value);
      if (file.existsSync()) {
        return FileImage(file);
      }
      return null;
    }

    return null;
  }

  bool _isAbsoluteFilePath(String value) {
    if (value.startsWith('/')) return true;
    return RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(value);
  }

  String _initials(String? rawName) {
    final parts = _nameParts(rawName);
    final initials = parts.take(2).map((e) => e[0].toUpperCase()).join();
    return initials;
  }

  Color _seedColor(String? seed) {
    final palette = <Color>[
      const Color(0xFF3F67FD),
      const Color(0xFF6C5CE7),
      const Color(0xFF00B894),
      const Color(0xFFE17055),
      const Color(0xFF0984E3),
      const Color(0xFF8E44AD),
    ];
    final normalizedSeed = _nameParts(seed).join(' ').toLowerCase();
    final hash = normalizedSeed.isEmpty ? 0 : normalizedSeed.hashCode;
    final index = hash.abs() % palette.length;
    return palette[index];
  }

  List<String> _nameParts(String? rawName) {
    final cleaned = (rawName ?? '').trim();
    if (cleaned.isEmpty) return const [];

    const ignoredPrefixes = <String>{
      'dr',
      'dr.',
      'mr',
      'mr.',
      'mrs',
      'mrs.',
      'ms',
      'ms.',
    };

    return cleaned
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .where((e) => !ignoredPrefixes.contains(e.toLowerCase()))
        .toList(growable: false);
  }
}
