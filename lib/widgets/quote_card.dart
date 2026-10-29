import 'package:flutter/material.dart';

import '../services/quote_service.dart';

/// Shows an inspirational quote loaded from an API with offline fallback,
/// caching, smooth animation, and error handling.
class QuoteCard extends StatefulWidget {
  const QuoteCard({super.key});

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  Quote? _quote;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initQuote();
  }

  Future<void> _initQuote() async {
    // 1. Load cached quote immediately so the UI is never blank
    final cached = await QuoteService.getCachedQuote();
    if (mounted) {
      setState(() {
        _quote = cached ?? QuoteService.getDifferentFallback(null);
      });
    }

    // 2. Fetch fresh quote in the background
    _fetchQuote(isInitialLoad: true);
  }

  Future<void> _fetchQuote({bool isInitialLoad = false}) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final newQuote = await QuoteService.fetch(excludeQuote: _quote);
      if (mounted) {
        setState(() {
          _quote = newQuote;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Only show error SnackBar if user explicitly tapped refresh,
      // or if we have no quote at all
      if (!isInitialLoad || _quote == null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not refresh quote. Please try again.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _fetchQuote(isInitialLoad: false),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentQuote = _quote;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              (currentQuote?.offline ?? false)
                  ? Icons.cloud_off
                  : Icons.format_quote,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: currentQuote != null
                    ? Column(
                        key: ValueKey<String>(currentQuote.text),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentQuote.text,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '- ${currentQuote.author}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      )
                    : const SizedBox(
                        key: ValueKey<String>('empty_loading'),
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'New quote',
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isLoading ? null : () => _fetchQuote(),
            ),
          ],
        ),
      ),
    );
  }
}
