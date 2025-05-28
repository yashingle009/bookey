import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'animated_home.dart';
import 'animated_buy.dart';
import 'sell.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  static const routeName = '/main';
  
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Controller to handle bottom bar and page view animations
  final _notchBottomBarController = NotchBottomBarController(index: 0);

  final List<Widget> _screens = [
    const AnimatedHome(),
    const AnimatedBuy(),
    const Sell(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _notchBottomBarController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notchBottomBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_notchBottomBarController.index],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to book selection screen
          Navigator.of(context).pushNamed('/book-selection');
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        tooltip: 'Add Multiple Books',
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: Listenable.merge([_notchBottomBarController]),
        builder: (context, _) {
          return AnimatedNotchBottomBar(
            notchBottomBarController: _notchBottomBarController,
            color: Colors.white,
            showLabel: true,
            notchColor: Theme.of(context).colorScheme.primary,
            removeMargins: false,
            bottomBarWidth: 500,
            durationInMilliSeconds: 300,
            kIconSize: 24.0,
            kBottomRadius: 30.0,
            bottomBarItems: const [
              BottomBarItem(
                inActiveItem: Icon(
                  Icons.home_outlined,
                  color: Colors.blueGrey,
                ),
                activeItem: Icon(
                  Icons.home_filled,
                  color: Colors.white,
                ),
                itemLabel: 'Home',
              ),
              BottomBarItem(
                inActiveItem: Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.blueGrey,
                ),
                activeItem: Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                ),
                itemLabel: 'Buy',
              ),
              BottomBarItem(
                inActiveItem: Icon(
                  Icons.sell_outlined,
                  color: Colors.blueGrey,
                ),
                activeItem: Icon(
                  Icons.sell,
                  color: Colors.white,
                ),
                itemLabel: 'Sell',
              ),
              BottomBarItem(
                inActiveItem: Icon(
                  Icons.person_outline,
                  color: Colors.blueGrey,
                ),
                activeItem: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
                itemLabel: 'Profile',
              ),
            ],
            onTap: (index) {
              setState(() {});
            },
          ).animate().fadeIn(duration: const Duration(milliseconds: 500));
        },

      ),
    );
  }
}
