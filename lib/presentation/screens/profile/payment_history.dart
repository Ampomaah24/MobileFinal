
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _payments = [];
  
  @override
  void initState() {
    super.initState();
    _loadPayments();
  }
  
  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
    });
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    
    try {
      if (authService.user != null) {
        final payments = await paymentService.getPaymentHistory(authService.user!.uid);
        
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading payment history: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      return _buildPaymentCard(_payments[index]);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No payment history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment transactions will appear here',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final DateTime? createdAt = payment['createdAt'];
    final String status = payment['status'] ?? 'unknown';
    final double amount = (payment['amount'] is double) 
        ? payment['amount'] 
        : double.tryParse(payment['amount'].toString()) ?? 0.0;
    final String reference = payment['reference'] ?? '';
    final String paymentMethod = payment['paymentMethod'] ?? 'PayStack';
    
    // Status color
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
      case 'processing':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'failed':
      case 'error':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'refunded':
        statusColor = Colors.blue;
        statusIcon = Icons.replay;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date
                Text(
                  createdAt != null
                      ? DateFormat('MMM d, yyyy • h:mm a').format(createdAt)
                      : 'Unknown date',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.capitalize(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Payment details
            Row(
              children: [
                // Payment method icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Payment info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paymentMethod,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ref: ${reference.substring(0, min(reference.length, 8))}...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Amount
                Text(
                  'GHS ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

int min(int a, int b) => a < b ? a : b;