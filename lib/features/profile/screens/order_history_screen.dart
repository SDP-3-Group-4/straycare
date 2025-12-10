import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../marketplace/services/marketplace_service.dart';
import '../../marketplace/models/marketplace_model.dart';
import '../../marketplace/models/marketplace_category.dart';
import '../../../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
  }

  Future<List<Order>> _fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final service = Provider.of<MarketplaceService>(context, listen: false);
        return await service.getOrderHistory();
      } catch (e) {
        debugPrint('Error fetching orders: $e');
        return [];
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('order_history')),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return OrderCard(order: orders[index]);
            },
          );
        },
      ),
    );
  }
}

class OrderCard extends StatefulWidget {
  final Order order;

  const OrderCard({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  double _rating = 0;

  @override
  void initState() {
    super.initState();
    _rating = 0;
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      date = date.toDate();
    }
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return date.toString();
  }

  String _formatTime(dynamic time, BuildContext context) {
    if (time is TimeOfDay) {
      return time.format(context);
    }
    return time.toString();
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cashOnDelivery:
        return 'Pay at Clinic / COD';
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDonation = widget.order.items.any(
      (item) => item.item.category == MarketplaceCategory.donation,
    );
    final isAppointment = widget.order.items.any(
      (item) => item.item.category == MarketplaceCategory.healthcare,
    );
    final firstItem = widget.order.items.first.item;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // Use theme card color or fallback
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      widget.order.status,
                    ).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDonation
                        ? Icons.volunteer_activism
                        : (isAppointment
                              ? Icons.calendar_today
                              : Icons.shopping_bag),
                    color: _getStatusColor(widget.order.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDonation
                            ? 'Donation'
                            : (isAppointment ? 'Appointment' : 'Order'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${widget.order.id}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.grey[400]
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      widget.order.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(
                        widget.order.status,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    widget.order.status
                        .toString()
                        .split('.')
                        .last
                        .toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(widget.order.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Item Preview (Image + Title)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: firstItem.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: isDark ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItem.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.order.items.length > 1)
                        Text(
                          '+ ${widget.order.items.length - 1} more items',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Amount',
                    'BDT ${widget.order.total.toStringAsFixed(2)}',
                  ),
                  _buildDetailRow(
                    context,
                    'Payment',
                    _formatPaymentMethod(widget.order.paymentMethod),
                  ),
                  if (isAppointment && widget.order.items.isNotEmpty) ...[
                    const Divider(height: 16),
                    if (widget.order.items.first.metadata != null) ...[
                      _buildDetailRow(
                        context,
                        'Date',
                        _formatDate(widget.order.items.first.metadata!['date']),
                      ),
                      _buildDetailRow(
                        context,
                        'Time',
                        _formatTime(
                          widget.order.items.first.metadata!['time'],
                          context,
                        ),
                      ),
                    ],
                    if (widget.order.items.first.item.location != null)
                      _buildDetailRow(
                        context,
                        'Location',
                        widget.order.items.first.item.location!,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rating
            if (!isDonation) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rate Experience:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _rating = index + 1.0;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'You rated this order ${index + 1} stars!',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 28,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.indigo;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
