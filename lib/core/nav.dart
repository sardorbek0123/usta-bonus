import 'package:flutter/material.dart';

/// Kirish/chiqishdan keyin barcha ochilgan sahifalarni yopib, birinchi
/// ekranga (RootGate) qaytaradi.
void popToRoot(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

Future<T?> push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

Future<T?> replace<T>(BuildContext context, Widget page) =>
    Navigator.of(context)
        .pushReplacement<T, Object?>(MaterialPageRoute(builder: (_) => page));
