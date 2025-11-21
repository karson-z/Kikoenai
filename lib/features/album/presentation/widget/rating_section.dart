import 'package:flutter/material.dart';
import 'package:name_app/core/utils/data/time_formatter.dart';
import 'package:name_app/features/album/data/model/rate_count_detail.dart';

class RatingSection extends StatelessWidget {
  final double average;
  final int totalCount;
  final List<RateCountDetail> details;
  final int duration;

  const RatingSection({
    super.key,
    required this.average,
    required this.duration,
    required this.totalCount,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAverageRow(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAverageRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _StarRow(rating: average, size: 20),
        const SizedBox(width: 6),
        Text(
          average.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.comment,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          "($totalCount)",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.timer,
          size: 16,
        ),
        Text(
          "(${TimeFormatter.formatSeconds(duration)})",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),

      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;

  const _StarRow({
    required this.rating,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> stars = [];

    for (int i = 1; i <= 5; i++) {
      double diff = rating - i + 1;

      IconData icon;
      if (diff >= 1) {
        icon = Icons.star;
      } else if (diff > 0) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }

      stars.add(
        Icon(icon, color: Colors.amber, size: size),
      );
    }

    return Row(children: stars);
  }
}
