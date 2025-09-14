import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'user_home.dart';
import 'categories.dart';
import 'user_profile.dart';

class NavigationMenu extends StatelessWidget {
  final Map<String, dynamic> responseData;

  const NavigationMenu({Key? key, required this.responseData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController(responseData: responseData));

    return Scaffold(
      body: Obx(
            () => IndexedStack(
          index: controller.selectedIndex.value,
          children: controller.screens,
        ),
      ),
      bottomNavigationBar: Obx(
            () => NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: Colors.green, // Green color for selected tab
          ),
          child: NavigationBar(
            height: 50,
            elevation: 0,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) => controller.selectedIndex.value = index,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.category), label: 'Categories'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );

  }
}

class NavigationController extends GetxController {
  final Map<String, dynamic> responseData;

  NavigationController({required this.responseData});

  final Rx<int> selectedIndex = 0.obs;

  late final List<Widget> screens = [
    UserHome(responseData: responseData),
    Category(), // ✅ Removed responseData as it's not needed
    UserProfile(responseData: responseData),
  ];

  void updateScreen(int index) {
    selectedIndex.value = index;
    if (index == 1) {
      screens[1] = Category(); // ✅ Reload UserSaved when switching tabs
    }
  }
}
