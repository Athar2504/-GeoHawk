import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'shopper_home.dart';
import 'shopper_profile.dart';

class ShopperNavigation extends StatelessWidget {
  final Map<String, dynamic> responseData;

  const ShopperNavigation({Key? key, required this.responseData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShopperNavigationController(responseData: responseData));

    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.selectedIndex.value,
        children: controller.screens,
      )),
      bottomNavigationBar: Obx(
            () => BottomNavigationBar(
          currentIndex: controller.selectedIndex.value,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.black54,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
          onTap: (index) => controller.selectedIndex.value = index,
        ),
      ),
    );
  }
}

class ShopperNavigationController extends GetxController {
  final Map<String, dynamic> responseData;

  ShopperNavigationController({required this.responseData});

  final Rx<int> selectedIndex = 0.obs;

  late final List<Widget> screens = [
    Shopperhome(responseData: responseData),
    ShopperProfile(responseData: responseData),
  ];
}

