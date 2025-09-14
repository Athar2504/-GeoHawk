import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ShopperTransactionHistory extends StatelessWidget {
  final String shopperEmail;

  ShopperTransactionHistory({required this.shopperEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Transaction History",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[200], // Light background

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payment_history')
            .where('shopper_email', isEqualTo: shopperEmail)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("❌ Error loading transactions",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.red)),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No transactions found",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
            );
          }

          var transactions = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(15),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              var data = transactions[index].data() as Map<String, dynamic>;

              return Container(
                margin: EdgeInsets.only(bottom: 15),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: Offset(2, 2),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status Icon
                    Icon(
                      data['status'] == 'success' ? Icons.check_circle : Icons.cancel,
                      color: data['status'] == 'success' ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    SizedBox(width: 12),

                    // Transaction Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "₹${data['amount']}",
                            style: GoogleFonts.poppins(
                                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Payment ID: ${data['payment_id']}",
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Date: ${data['timestamp'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format((data['timestamp'] as Timestamp).toDate()) : 'N/A'}",
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),

                    // Arrow for navigation
                    Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
