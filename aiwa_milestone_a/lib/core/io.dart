// lib/core/io.dart
import 'dart:convert';

String jsonPretty(Map<String, dynamic> data) =>
    const JsonEncoder.withIndent('  ').convert(data);
