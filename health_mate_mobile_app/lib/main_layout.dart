import 'package:flutter/material.dart';
import 'package:health_mate_mobile_app/HomeScreen.dart';
import 'package:health_mate_mobile_app/screens/chat/chat_list_screen.dart';
import 'package:health_mate_mobile_app/screens/bmi/bmi_screen.dart';
import 'package:health_mate_mobile_app/screens/consultation/doctor_list_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'package:health_mate_mobile_app/screens/profile/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}


class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const DoctorListScreen(),
    const BmiScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFE2E8F0), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0052CC),
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.local_hospital_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.local_hospital_rounded)),
              label: 'Medical',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.monitor_weight_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.monitor_weight_rounded)),
              label: 'Health Plan',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.chat_bubble_outline_rounded)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.chat_bubble_rounded)),
              label: 'AI Chat',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline_rounded)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
