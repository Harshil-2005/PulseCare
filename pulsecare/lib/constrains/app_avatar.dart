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
    final accentColor = _seedColor(name);

    if (provider != null) {
      return CircleAvatar(radius: radius, backgroundImage: provider);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFDDE8FF),
      child: initials.isEmpty
          ? Icon(Icons.person_rounded, size: radius, color: accentColor)
          : Text(
              initials,
              style: TextStyle(
                color: accentColor,
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
      const Color(0xFF4F7EDB),
      const Color(0xFF6D87D8),
      const Color(0xFF5C9DBE),
      const Color(0xFF7E94C7),
      const Color(0xFF5B9E95),
      const Color(0xFF8A84C8),
      const Color(0xFFC184A8),
      const Color(0xFFA389C9),
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
