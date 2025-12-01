import 'package:flutter/material.dart';
import 'package:straycare_demo/features/marketplace/models/marketplace_category.dart';
import '../models/marketplace_model.dart';
import '../services/marketplace_service.dart';

class PaymentScreen extends StatefulWidget {
  final Cart cart;
  final MarketplaceService service;

  const PaymentScreen({Key? key, required this.cart, required this.service})
    : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.creditCard;
  final _addressController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  bool _hasPhysicalProducts() {
    return widget.cart.items.any((item) {
      final category = item.item.category;
      return category != MarketplaceCategory.healthcare &&
          category != MarketplaceCategory.donation;
    });
  }

  bool _isDonationOnly() {
    return widget.cart.items.length == 1 &&
        widget.cart.items.first.item.category == MarketplaceCategory.donation;
  }

  String _getSummaryTitle() {
    if (_isDonationOnly()) {
      return 'Donation Summary';
    } else if (_hasPhysicalProducts()) {
      return 'Order Summary';
    } else {
      return 'Booking Summary';
    }
  }

  void _processPayment() async {
    print('DEBUG: _processPayment started');
    final bool requiresAddress = _hasPhysicalProducts();

    if (requiresAddress && _addressController.text.isEmpty) {
      print('DEBUG: Address required but empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter shipping address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      print('DEBUG: Creating order...');
      // Simulate Payment Gateway
      if (_selectedMethod != PaymentMethod.cashOnDelivery) {
        await Future.delayed(const Duration(seconds: 2));
      }

      final order = await widget.service.createOrder(
        !requiresAddress
            ? 'Vet Appointment / Digital Service'
            : _addressController.text,
        _selectedMethod,
        fromCart: widget.cart,
      );
      print('DEBUG: Order created: ${order.id}');

      if (mounted) {
        print('DEBUG: Showing success dialog');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => OrderSuccessDialog(order: order),
        );
      }
    } catch (e, stack) {
      print('DEBUG: Payment failed: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final requiresAddress = _hasPhysicalProducts();
    final isDonation = _isDonationOnly();
    final donationRecipient = isDonation
        ? widget.cart.items.first.item.seller
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        title: Text('Payment', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: primaryColor.withOpacity(0.05),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getSummaryTitle(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isDonation && donationRecipient != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You are donating to: $donationRecipient',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Display Items
                  ...widget.cart.items.map((item) {
                    final isService =
                        item.item.category == MarketplaceCategory.healthcare;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  isService
                                      ? item.item.title
                                      : '${item.item.title} × ${item.quantity}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                'BDT ${item.totalPrice.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (item.metadata != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${(item.metadata!['date'] as DateTime).day}/${(item.metadata!['date'] as DateTime).month}/${(item.metadata!['date'] as DateTime).year} - Time: ${(item.metadata!['time'] as TimeOfDay).format(context)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Pet: ${item.metadata!['petName']} (${item.metadata!['petType']})',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),

                  Divider(color: Colors.grey.shade300, height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'BDT ${widget.cart.total.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (requiresAddress)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shipping Address',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter delivery address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...PaymentMethod.values
                      .where((method) {
                        if (isDonation) {
                          return method == PaymentMethod.mobileMoney ||
                              method == PaymentMethod.bankTransfer;
                        }
                        return true;
                      })
                      .map(
                        (method) => PaymentMethodTile(
                          method: method,
                          isSelected: _selectedMethod == method,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedMethod = method);
                            }
                          },
                        ),
                      )
                      .toList(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isDonation
                              ? 'Complete Donation'
                              : (requiresAddress
                                    ? 'Place Order'
                                    : 'Confirm Booking'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final Function(bool)? onSelected;

  const PaymentMethodTile({
    Key? key,
    required this.method,
    required this.isSelected,
    this.onSelected,
  }) : super(key: key);

  String _getMethodName(PaymentMethod method) {
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
        return 'Cash on Delivery / Pay at Clinic';
    }
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.cashOnDelivery:
        return Icons.money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTap: () => onSelected?.call(true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? primaryColor.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              _getMethodIcon(method),
              color: isSelected ? primaryColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getMethodName(method),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryColor : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class OrderSuccessDialog extends StatelessWidget {
  final Order order;

  const OrderSuccessDialog({Key? key, required this.order}) : super(key: key);

  String _formatDate(dynamic date) {
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDonation = order.items.any(
      (item) => item.item.category == MarketplaceCategory.donation,
    );
    final isAppointment = order.items.any(
      (item) => item.item.category == MarketplaceCategory.healthcare,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDonation ? Icons.volunteer_activism : Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isDonation ? 'Donation Successful!' : 'Booking Confirmed!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction ID: ${order.id}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Amount Paid',
                    'BDT ${order.total.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    'Payment Method',
                    _formatPaymentMethod(order.paymentMethod),
                  ),

                  if (isAppointment && order.items.isNotEmpty) ...[
                    const Divider(height: 24),
                    if (order.items.first.metadata != null) ...[
                      _buildDetailRow(
                        context,
                        'Date & Time',
                        '${_formatDate(order.items.first.metadata!['date'])} • ${_formatTime(order.items.first.metadata!['time'], context)}',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        'Pet',
                        '${order.items.first.metadata!['petName']} (${order.items.first.metadata!['petType']})',
                      ),
                    ],
                    if (order.items.first.item.location != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        context,
                        'Location',
                        order.items.first.item.location!,
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
