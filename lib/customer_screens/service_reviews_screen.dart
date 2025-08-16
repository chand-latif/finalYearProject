import 'package:flutter/material.dart';
import '../theme.dart';

class ServiceReviewsScreen extends StatelessWidget {
  final List<dynamic> reviews;
  final double averageRating;
  final int totalRatings;

  const ServiceReviewsScreen({
    Key? key,
    required this.reviews,
    required this.averageRating,
    required this.totalRatings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Rating Summary
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < averageRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$totalRatings ratings',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1),

          // Reviews List
          Expanded(
            child:
                reviews.isEmpty
                    ? Center(child: Text('No reviews yet'))
                    : ListView.separated(
                      itemCount: reviews.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              review['userName']?[0].toUpperCase() ?? '?',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                          title: Text(review['userName'] ?? 'Anonymous'),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(review['comment'] ?? 'No comment'),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
