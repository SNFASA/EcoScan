import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/points_service.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static const _categoryDetails = <String, (Color, IconData)>{
    'Plastic': (Colors.orange, Icons.local_drink_outlined),
    'Paper': (Colors.blue, Icons.newspaper_outlined),
    'Glass': (Colors.teal, Icons.wine_bar_outlined),
    'Metal': (Colors.blueGrey, Icons.hardware_outlined),
    'Food': (Colors.brown, Icons.compost_outlined),
    'General': (Colors.grey, Icons.delete_outline),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(pointsServiceProvider);
    final entries = stats.categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final largestCount = entries.isEmpty ? 1 : entries.first.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                pinned: true,
                backgroundColor: Colors.green.shade800,
                foregroundColor: Colors.white,
                title: const Text('Your Impact'),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          icon: Icons.recycling_rounded,
                          value: '${stats.totalScans}',
                          label: 'Session scans',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SummaryCard(
                          icon: Icons.stars_rounded,
                          value: '${stats.totalPoints}',
                          label: 'Local points',
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                sliver: const SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waste breakdown',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Stored only for this app session.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              if (entries.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyImpact(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  sliver: SliverList.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final details =
                          _categoryDetails[entry.key] ??
                          (Colors.grey, Icons.delete_outline);
                      return _ImpactBar(
                        label: entry.key,
                        count: entry.value,
                        proportion: entry.value / largestCount,
                        color: details.$1,
                        icon: details.$2,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ImpactBar extends StatelessWidget {
  const _ImpactBar({
    required this.label,
    required this.count,
    required this.proportion,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final double proportion;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text('$count ${count == 1 ? 'item' : 'items'}'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: proportion,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyImpact extends StatelessWidget {
  const _EmptyImpact();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph_rounded, size: 56, color: Colors.black38),
          SizedBox(height: 16),
          Text(
            'Your session is ready',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'Scan an item and its category will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
