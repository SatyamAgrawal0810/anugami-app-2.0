import 'package:anu_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/review_model.dart';
import '../../../../providers/review_provider.dart';

class AverageRatingWidget extends StatelessWidget {
  final String productSlug;
  final bool isCompact;

  const AverageRatingWidget({
    Key? key,
    required this.productSlug,
    this.isCompact = false,
  }) : super(key: key);

  Map<String, dynamic> _calculateRatingStats(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': [0, 0, 0, 0, 0],
      };
    }

    double totalRating = 0;
    List<int> distribution = [0, 0, 0, 0, 0];

    for (var review in reviews) {
      totalRating += review.rating;
      if (review.rating >= 1 && review.rating <= 5) {
        distribution[review.rating - 1]++;
      }
    }

    double averageRating = totalRating / reviews.length;

    return {
      'averageRating': averageRating,
      'totalReviews': reviews.length,
      'ratingDistribution': distribution,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        final stats = _calculateRatingStats(reviewProvider.reviews);
        final double averageRating = stats['averageRating'];
        final int totalReviews = stats['totalReviews'];
        final List<int> distribution = stats['ratingDistribution'];

        if (isCompact) {
          return _buildCompactRating(averageRating, totalReviews);
        }

        return _buildFullRatingWidget(
            context, averageRating, totalReviews, distribution);
      },
    );
  }

  Widget _buildCompactRating(double averageRating, int totalReviews) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            double starValue = averageRating - index;
            return Icon(
              starValue >= 1
                  ? Icons.star
                  : starValue >= 0.5
                      ? Icons.star_half
                      : Icons.star_border,
              color: Colors.amber,
              size: 16,
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          averageRating > 0
              ? '${averageRating.toStringAsFixed(1)} (${totalReviews})'
              : 'No reviews yet',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFullRatingWidget(BuildContext context, double averageRating,
      int totalReviews, List<int> distribution) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Reviews',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (totalReviews > 0) ...[
            // Use LayoutBuilder so inner children can respond to width constraints
            LayoutBuilder(builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Overall rating (Flexible to avoid forcing overflow)
                  Flexible(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Use FittedBox for the rating number and "out of 5" to avoid overflow
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                averageRating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'out of 5',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Stars row: reduced size so it fits comfortably
                        Row(
                          children: List.generate(5, (index) {
                            double starValue = averageRating - index;
                            return Icon(
                              starValue >= 1
                                  ? Icons.star
                                  : starValue >= 0.5
                                      ? Icons.star_half
                                      : Icons.star_border,
                              color: Colors.amber,
                              size: 20, // reduced from 24 to 20 to be safer
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Based on $totalReviews review${totalReviews == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // horizontal gap - made smaller to save width
                  const SizedBox(width: 12),

                  // Right side - Rating distribution (Flexible so it can shrink)
                  Flexible(
                    flex: 3,
                    child: Column(
                      children: List.generate(5, (index) {
                        int starNumber = 5 - index;
                        int count = distribution[starNumber - 1];
                        double percentage =
                            totalReviews > 0 ? (count / totalReviews) * 100 : 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              // star number
                              SizedBox(
                                width:
                                    18, // tightened width to prevent overflow
                                child: Text(
                                  '$starNumber',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              // bar - allow it to expand and shrink
                              Expanded(
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor:
                                        (percentage / 100).clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _getRatingColor(starNumber),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // count - tightened width
                              SizedBox(
                                width: 26,
                                child: Text(
                                  count.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 20),

            // Summary badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSummaryBadge(
                  'Excellent',
                  distribution[4],
                  totalReviews,
                  const Color(0xFFF96A4C),
                ),
                _buildSummaryBadge(
                  'Good',
                  distribution[3] + distribution[2],
                  totalReviews,
                  Colors.orange,
                ),
                _buildSummaryBadge(
                  'Needs Improvement',
                  distribution[1] + distribution[0],
                  totalReviews,
                  Colors.red,
                ),
              ],
            ),
          ] else ...[
            // No reviews state
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.star_border,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share your thoughts!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBadge(String label, int count, int total, Color color) {
    double percentage = total > 0 ? (count / total) * 100 : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getSummaryIcon(label),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '$label ${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSummaryIcon(String label) {
    switch (label) {
      case 'Excellent':
        return Icons.sentiment_very_satisfied;
      case 'Good':
        return Icons.sentiment_satisfied;
      case 'Needs Improvement':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.star;
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return const Color(0xFFF96A4C);
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
