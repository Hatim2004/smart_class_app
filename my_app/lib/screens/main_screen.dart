import 'package:flutter/material.dart';
import '../constants.dart';
import 'chat_screen.dart'; // Teacher's chat screen
import 'student_chat_screen.dart'; // Add this import for the new student screen
import 'record_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  final UserRole role;

  const MainScreen({super.key, required this.role});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isStudent = widget.role == UserRole.student;

    // Conditionally load the chat screen based on the role
    final List<Widget> screens = [
      isStudent ?  StudentChatScreen(role: widget.role,) : ChatScreen(role: widget.role),
      if (!isStudent) RecordScreen(), 
      HistoryScreen(role: widget.role),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.smart_toy_outlined),
        activeIcon: Icon(Icons.smart_toy_rounded),
        label: 'المساعد',
      ),
      if (!isStudent)
        const BottomNavigationBarItem(
          icon: Icon(Icons.fiber_manual_record_outlined),
          activeIcon: Icon(Icons.fiber_manual_record_rounded),
          label: 'تسجيل الحصة',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history_edu_outlined),
        activeIcon: Icon(Icons.history_edu_rounded),
        label: 'السجل',
      ),
    ];

    if (_currentIndex >= screens.length) {
      _currentIndex = screens.length - 1;
    }

    final String currentTitle = navItems[_currentIndex].label ?? 'مساعد المعلم';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
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
            fontWeight: FontWeight.w700, 
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: navItems,
        ),
      ),
    );
  }
}