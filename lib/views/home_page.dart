import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kutuku/tabs/categories_tab.dart';
import 'package:kutuku/tabs/home_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                Row(
                  // center text vertically with image
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage(
                        'assets/image/profile_photo.jpg',
                      ),
                      // backgroundColor: Colors.white,
                    ),
                    const SizedBox(width: 10),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, Callista',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Let’s start shopping',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Icon(Iconsax.search_normal),
                        ),
                        SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {},
                          child: Icon(Iconsax.notification),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                //the shop tabs
                TabBar(tabs: [Tab(text: 'Home'), Tab(text: 'Categories')]),
                //tabBar view
                Expanded(
                  child: TabBarView(children: [HomeTab(), CategoriesTab()]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
