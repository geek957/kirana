import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onRatingChanged;
  final double size;
  final bool isInteractive;

  const StarRating({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.size = 32.0,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: isInteractive && onRatingChanged != null
              ? () => onRatingChanged!(starValue)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starValue <= rating ? Icons.star : Icons.star_border,
              color: starValue <= rating
                  ? Colors.amber
                  : Colors.grey[400],
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
