import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';


class PaymentPage extends StatefulWidget {
  final String shopperEmail;
  final String shopperName;

  PaymentPage({required this.shopperEmail, required this.shopperName});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  String? _upiId;
  bool _isLoading = true;
  TextEditingController _amountController = TextEditingController(); // For user input amount

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _fetchUpiId();
  }

  // Fetch UPI ID from Firebase
  Future<void> _fetchUpiId() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('hawkers') // Collection where UPI IDs are stored
          .doc(widget.shopperEmail) // Using shopper's email as doc ID
          .get();

      if (snapshot.exists) {
        setState(() {
          _upiId = snapshot['upi_id']; // Save UPI ID from Firestore
          _isLoading = false;
        });
      } else {
        setState(() {
          _upiId = 'No UPI ID available';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _upiId = 'Error fetching UPI ID';
        _isLoading = false;
      });
    }
  }

  // Start UPI Payment Process
  void _startPayment() {
    String amountText = _amountController.text.trim();
    if (amountText.isEmpty || _upiId == null || _upiId == 'No UPI ID available') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Hawker dosen't support UPI payments"),
      ));
      return;
    }

    int amount = int.parse(amountText) * 100; // Convert to paise

    var options = {
      'key': 'rzp_test_dOlScRlQYZMWgg', // Replace with your Razorpay Key
      'amount': amount, // Amount in paise
      'name': widget.shopperName,
      'description': 'Payment for your product',
      'prefill': {
        'contact': '98xxxxxx', // User's phone number
        'email': widget.shopperEmail, // User's email
      },
      'method': {
        'upi': true, // Enable only UPI
        'card': false, // Disable cards
        'netbanking': false, // Disable net banking
        'wallet': false, // Disable wallets
        'paylater': false,  // **Disable Pay Later**
      },
      'upi': {
        'flow': 'intent' // **Forces Razorpay to show installed UPI apps**
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("✅ Payment Successful: ${response.paymentId}"); // Debug log

    FirebaseFirestore.instance
        .collection('payment_history')
        .add({  // 👈 Use `.add()` to create a new unique document each time
      'shopper_name': widget.shopperName,
      'shopper_email': widget.shopperEmail,
      'payment_id': response.paymentId,
      'order_id': response.orderId,
      'status': 'success',
      'amount': int.parse(_amountController.text),
      'timestamp': FieldValue.serverTimestamp(),
    }).then((_) {
      print("✅ New payment record added to Firestore");
    }).catchError((error) {
      print("❌ Firestore Error: $error"); // Log Firestore error
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment Successful!'),
    ));
  }


  // Handle Payment Error
  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment Error: ${response.error?['description']}'),
    ));
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear(); // Always clear instance when no longer needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Payment"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Padding(
          padding: EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.deepPurple[100],
                    child: Icon(Icons.person, size: 40, color: Colors.deepPurple),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.shopperName,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Enter Amount",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee, color: Colors.deepPurple),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    ),
                    child: Text(
                      'Pay via UPI',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
