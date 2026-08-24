import 'package:flutter/material.dart';
import 'bottom_nav.dart';
import 'tab_item.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.current, required this.body});

  final TabItem current;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(current: current),
      body: SafeArea(child: body),
    );
  }
}
