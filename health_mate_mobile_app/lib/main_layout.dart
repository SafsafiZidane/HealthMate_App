import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 3; // Default to index 3 (AI Chat) based on your picture mockup

  // The actual screens attached to each specific navigation position
  final List<Widget> _pages = [
    const Center(child: Text("Home Dashboard Screen", style: TextStyle(fontSize: 18))),
    const Center(child: Text("Sport Tracking Screen", style: TextStyle(fontSize: 18))),
    const Center(child: Text("Nutrition Log Screen", style: TextStyle(fontSize: 18))),
    const CentralAIChatMock(), // Your AI Chat Interface view goes here
    const Center(child: Text("Profile Settings Screen", style: TextStyle(fontSize: 18))),
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
          items: [
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.fitness_center_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.fitness_center_rounded)),
              label: 'Sport',
            ),
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.restaurant_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.restaurant_rounded)),
              label: 'Nutrition',
            ),
            // Distinctive Highlighted AI Chat Capsule Button matching your UI
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: _currentIndex == 3 ? const Color(0xFF0052CC) : const Color(0xFFE2E8F0).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: _currentIndex == 3 ? Colors.white : const Color(0xFF64748B)
                ),
              ),
              label: 'AI Chat',
            ),
            const BottomNavigationBarItem(
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

// Quick UI placeholder mirroring your AI Assistant image interface wrapper
class CentralAIChatMock extends StatelessWidget {
  const CentralAIChatMock({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1560250097-0b93528c311a?w=100'), // Temporary mock image profile avatar
          ),
        ),
        title: const Text("HealthMate 2.0", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A)),
            onPressed: () {},
          )
        ],
      ),
      body: const Center(child: Text("💬 Live AI Health Assistant Feed Workspace")),
    );
  }
}