import 'package:flutter/material.dart';
import '../constants.dart';
import 'chat_screen.dart';
import 'record_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Keep screens alive when switching tabs
  static const List<Widget> _screens = [
    ChatScreen(),
    RecordScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy_rounded),
              label: 'المساعد',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fiber_manual_record_outlined),
              activeIcon: Icon(Icons.fiber_manual_record_rounded),
              label: 'تسجيل الحصة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_outlined),
              activeIcon: Icon(Icons.history_edu_rounded),
              label: 'السجل',
            ),
          ],
        ),
      ),
    );
  }
}