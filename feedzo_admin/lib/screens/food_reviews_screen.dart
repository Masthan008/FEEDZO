import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../widgets/topbar.dart';

class FoodReviewsScreen extends StatefulWidget {
  const FoodReviewsScreen({super.key});

  @override
  State<FoodReviewsScreen> createState() => _FoodReviewsScreenState();
}

class _FoodReviewsScreenState extends State<FoodReviewsScreen> {
  String _selectedRating = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Food Reviews', subtitle: 'View and manage food reviews'),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Text('Filter by rating: '),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedRating,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: '5', child: Text('5 Stars')),
                  DropdownMenuItem(value: '4', child: Text('4 Stars')),
                  DropdownMenuItem(value: '3', child: Text('3 Stars')),
                  DropdownMenuItem(value: '2', child: Text('2 Stars')),
                  DropdownMenuItem(value: '1', child: Text('1 Star')),
                ],
                onChanged: (value) {
                  setState(() => _selectedRating = value!);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final reviews = snapshot.data?.docs ?? [];

              if (reviews.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No reviews yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index].data() as Map<String, dynamic>;
                  final rating = review['rating'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                review['customerName'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < rating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review['comment'] ?? '',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm').format(
                              (review['createdAt'] as Timestamp).toDate(),
                            ),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
