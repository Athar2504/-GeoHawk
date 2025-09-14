import 'package:flutter/material.dart';

class NotificationPanel extends StatelessWidget {
  final List<String> notifications = [
    "New message from Shopper A",
    "Your order has been confirmed",
    "Shopper B has updated their profile",
    "You have a new review on your profile",
    "Payment successful for Shopper C",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(notifications[index]),
            subtitle: const Text("Just now"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Handle notification click (e.g., navigate to relevant page)
              // For now, just show a Snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Tapped on: ${notifications[index]}")),
              );
            },
          );
        },
      ),
    );
  }
}
