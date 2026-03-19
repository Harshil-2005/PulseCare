import 'dart:async';

import 'package:flutter/material.dart';

enum AppToastPosition { top, bottom }

OverlayEntry? _activeToastEntry;
Timer? _toastTimer;

void showAppToast(
  BuildContext context,
  String message, {
  AppToastPosition position = AppToastPosition.bottom,
}) {
  _toastTimer?.cancel();
  _activeToastEntry?.remove();
  _activeToastEntry = null;

  final overlay = Overlay.of(context, rootOverlay: true);
  final media = MediaQuery.of(context);
  final keyboardOpen = media.viewInsets.bottom > 0;
  final bottomOffset = keyboardOpen
      ? media.viewInsets.bottom + 16
      : media.padding.bottom + 92;

  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 16,
      right: 16,
      top: position == AppToastPosition.top ? media.padding.top + 12 : null,
      bottom: position == AppToastPosition.bottom ? bottomOffset : null,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1FF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF3F67FD),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  _activeToastEntry = entry;
  _toastTimer = Timer(const Duration(seconds: 2), () {
    if (_activeToastEntry == entry) {
      _activeToastEntry?.remove();
      _activeToastEntry = null;
    }
  });
}
