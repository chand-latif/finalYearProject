import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';

class ServiceReviewScreen extends StatefulWidget {
  final int serviceId;

  const ServiceReviewScreen({Key? key, required this.serviceId})
    : super(key: key);

  @override
  State<ServiceReviewScreen> createState() => _ServiceReviewScreenState();
}

class _ServiceReviewScreenState extends State<ServiceReviewScreen> {
  double rating = 0;
  final commentController = TextEditingController();
  bool isSubmitting = false;

  Future<void> submitRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse('https://fixease.pk/api/Rating/CreateRatingToService'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
        body: jsonEncode({
          'serviceId': widget.serviceId,
          'ratingValue': rating.toInt(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(' ${response.statusCode}Failed to submit rating');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error  submitting rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
      throw e; // Re-throw to handle in the main submit function
    }
  }

  Future<void> submitComment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse('https://fixease.pk/api/Review/CreateReviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
        body: jsonEncode({
          'serviceId': widget.serviceId,
          'comment': commentController.text,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: Colors.red,
        ),
      );
      throw e;
    }
  }

  Future<void> handleSubmission() async {
    setState(() => isSubmitting = true);

    try {
      // Submit rating if provided
      if (rating > 0) {
        await submitRating();
      }

      // Submit review if provided
      if (commentController.text.isNotEmpty) {
        await submitComment();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      // Error handling already done in individual functions
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate & Review'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'How was your experience?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  List.generate(6, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          rating = index.toDouble();
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index <= rating ? Icons.star : Icons.star_border,
                          size: 40,
                          color: Colors.amber,
                        ),
                      ),
                    );
                  }).skip(1).toList(), // Skip 0 to start from 1
            ),
            SizedBox(height: 20),
            Text(
              'Add a comment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us about your experience...',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        isSubmitting
                            ? null
                            : () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Skip'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        isSubmitting ||
                                (rating == 0 && commentController.text.isEmpty)
                            ? null
                            : handleSubmission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        isSubmitting
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                            : Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}
