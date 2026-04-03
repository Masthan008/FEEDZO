import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Help & Support screen for customers.
/// Allows users to browse FAQs, submit support tickets, and view ticket history.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'My Tickets'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Ticket',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _FAQTab(),
          _TicketsTab(),
        ],
      ),
    );
  }

  Future<void> _showNewTicketDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Order Issue';

    final categories = [
      'Order Issue',
      'Payment Problem',
      'Delivery Issue',
      'Account & Profile',
      'App Bug / Feedback',
      'Other',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: AppShape.round,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Submit a Ticket',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'We\'ll get back to you within 24 hours',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Category
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: AppShape.small,
                    borderSide: BorderSide.none,
                  ),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setSheetState(() => category = v ?? category),
              ),
              const SizedBox(height: 14),

              // Subject
              TextField(
                controller: subjectCtrl,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Brief summary of your issue',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: AppShape.small,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Description
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell us more about your issue...',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: AppShape.small,
                    borderSide: BorderSide.none,
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (subjectCtrl.text.trim().isEmpty ||
                        descCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please fill subject and description')),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('support_tickets')
                        .add({
                      'userId': auth.user?.id,
                      'userName': auth.user?.name ?? 'Customer',
                      'userEmail': auth.user?.email ?? '',
                      'category': category,
                      'subject': subjectCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'status': 'open',
                      'createdAt': FieldValue.serverTimestamp(),
                      'replies': [],
                    });

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Ticket submitted! We\'ll respond within 24h.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppShape.small),
                  ),
                  child: const Text(
                    'Submit Ticket',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FAQ Tab ──
class _FAQTab extends StatelessWidget {
  final _faqs = const [
    {
      'q': 'How do I track my order?',
      'a':
          'Go to My Orders → Active tab → tap on the order → Track Order. You\'ll see real-time updates and the delivery partner\'s location.',
    },
    {
      'q': 'How do I apply a coupon code?',
      'a':
          'On the cart screen, scroll down to the "Enter coupon code" section, type your code, and tap APPLY. Valid discounts will be applied instantly.',
    },
    {
      'q': 'Can I cancel my order?',
      'a':
          'You can cancel before the restaurant starts preparing. Go to Track Order → Cancel Order. Select a reason and confirm.',
    },
    {
      'q': 'How do refunds work?',
      'a':
          'Refunds are processed within 3-5 business days to your original payment method. For wallet refunds, it\'s instant.',
    },
    {
      'q': 'How do I change my delivery address?',
      'a':
          'Go to Profile → Manage Addresses. You can add, edit, or delete addresses. Select the desired address before checkout.',
    },
    {
      'q': 'What if my order is delayed?',
      'a':
          'Check the Track Order screen for live updates. If it\'s significantly delayed, contact us via a Support Ticket and we\'ll help.',
    },
    {
      'q': 'How do I add items to favorites?',
      'a':
          'Tap the heart icon on any restaurant card to add it to your favorites. Access them anytime from your profile.',
    },
    {
      'q': 'What payment methods are accepted?',
      'a':
          'We accept Cash on Delivery (COD), UPI, credit/debit cards, and net banking. More options coming soon!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _faqs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final faq = _faqs[i];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppShape.medium,
            boxShadow: AppShadows.subtle,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded,
                    color: AppColors.primary, size: 18),
              ),
              title: Text(
                faq['q']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              children: [
                Text(
                  faq['a']!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tickets Tab ──
class _TicketsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id;

    if (userId == null) {
      return const Center(child: Text('Please log in to view tickets'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_tickets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.confirmation_number_outlined,
                    size: 56, color: AppColors.textHint.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text(
                  'No support tickets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap + to create a new ticket',
                  style: TextStyle(color: AppColors.textHint, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'open';
            final statusColor = status == 'open'
                ? AppColors.warning
                : status == 'resolved'
                    ? AppColors.success
                    : AppColors.primary;
            final createdAt =
                (data['createdAt'] as Timestamp?)?.toDate();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppShape.medium,
                boxShadow: AppShadows.subtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: AppShape.small,
                        ),
                        child: Text(
                          status.toString().toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppShape.small,
                        ),
                        child: Text(
                          data['category'] ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (createdAt != null)
                        Text(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['subject'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  // Show replies count
                  if ((data['replies'] as List?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.reply_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${(data['replies'] as List).length} replies',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
