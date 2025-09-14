import 'package:flutter/material.dart';

class UserCategories extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {'name': 'FOOD', 'icon': Icons.fastfood},
    {'name': 'CLOTHING', 'icon': Icons.shopping_bag},
    {'name': 'MEDICINE', 'icon': Icons.medical_services},
    {'name': 'SHOES', 'icon': Icons.directions_run},
    {'name': 'ACCESSORIES', 'icon': Icons.watch},
    {'name': 'ELECTRONICS', 'icon': Icons.devices},
    {'name': 'BEAUTY', 'icon': Icons.brush},
    {'name': 'TOYS', 'icon': Icons.toys},
  ];

  void onCategoryClick(BuildContext context, String categoryName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$categoryName selected")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("All Categories")),
        body: GridView.builder(
            padding: EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 icons per row
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return GestureDetector(
                onTap: () => onCategoryClick(context, category['name']),
                child: Card(
                  elevation: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(category['icon'], size: 50, color: Colors.blueAccent),
                      SizedBox(height: 10),
                      Text(category['name'], style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              );
            },
            ),
        );
    }
}