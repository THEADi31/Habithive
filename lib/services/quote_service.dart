import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Quote {
  const Quote({
    required this.text,
    required this.author,
    this.offline = false,
  });

  final String text;
  final String author;

  /// True when the quote came from the built-in list instead of the API.
  final bool offline;

  Map<String, dynamic> toJson() => {
        'text': text,
        'author': author,
        'offline': offline,
      };

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        text: json['text'] as String,
        author: json['author'] as String,
        offline: json['offline'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quote &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          author == other.author;

  @override
  int get hashCode => text.hashCode ^ author.hashCode;
}

/// Calls a public REST API (dummyjson.com), caches quotes locally, and provides offline fallbacks.
class QuoteService {
  static const _cachedQuoteKey = 'cached_quote_v1';

  static const _fallbacks = [
    Quote(
      text: 'Small steps, repeated daily, beat big plans left alone.',
      author: 'HabitHive',
      offline: true,
    ),
    Quote(
      text: 'Do it today so future you has less to carry.',
      author: 'HabitHive',
      offline: true,
    ),
    Quote(
      text: 'Consistency is just showing up when you do not feel like it.',
      author: 'HabitHive',
      offline: true,
    ),
    Quote(
      text: 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
      author: 'Will Durant',
      offline: true,
    ),
    Quote(
      text: 'You do not rise to the level of your goals. You fall to the level of your systems.',
      author: 'James Clear',
      offline: true,
    ),
  ];

  /// Loads the last successfully cached quote from SharedPreferences.
  static Future<Quote?> getCachedQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedQuoteKey);
      if (raw != null) {
        return Quote.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[QuoteService] Failed to load cached quote: $e');
    }
    return null;
  }

  /// Caches the given quote in SharedPreferences.
  static Future<void> cacheQuote(Quote quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedQuoteKey, jsonEncode(quote.toJson()));
    } catch (e) {
      debugPrint('[QuoteService] Failed to cache quote: $e');
    }
  }

  /// Returns a fallback quote that is distinct from the [current] quote if possible.
  static Quote getDifferentFallback(Quote? current) {
    final available = _fallbacks.where((q) => q.text != current?.text).toList();
    final list = available.isNotEmpty ? available : _fallbacks;
    return list[DateTime.now().millisecond % list.length];
  }

  /// Fetches a new quote from the API with cache-busting.
  /// Throws an exception if the network call fails.
  static Future<Quote> fetch({Quote? excludeQuote}) async {
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        final uri = Uri.parse(
          'https://dummyjson.com/quotes/random?_cb=${DateTime.now().microsecondsSinceEpoch}',
        );
        final res = await http.get(uri, headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        }).timeout(const Duration(seconds: 8));

        if (res.statusCode != 200) {
          throw Exception('HTTP error ${res.statusCode}');
        }

        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final quote = Quote(
          text: data['quote'] as String,
          author: data['author'] as String,
          offline: false,
        );

        // If it's different from the current quote or second attempt, return it
        if (excludeQuote == null || quote.text != excludeQuote.text || attempt > 0) {
          await cacheQuote(quote);
          return quote;
        }
      }

      // If loop exited, return fallback
      return getDifferentFallback(excludeQuote);
    } catch (e) {
      debugPrint('[QuoteService] Error fetching quote: $e');
      rethrow;
    }
  }
}
