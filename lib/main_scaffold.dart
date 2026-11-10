import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'home_page.dart';
import 'quests_page.dart';
import 'notice_page.dart';
import 'culture_page.dart';
import 'profile_page.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String labelKo;

  const _NavItem(this.icon, this.activeIcon, this.label, this.labelKo);
}

// Tab order and labels follow the Figma design: Home / Quests / Campus / Culture / Me.
const List<_NavItem> _navItems = [
  _NavItem(Icons.home_outlined, Icons.home, 'Home', '홈'),
  _NavItem(Icons.flag_outlined, Icons.flag, 'Quests', '퀘스트'),
  _NavItem(Icons.school_outlined, Icons.school, 'Campus', '캠퍼스'),
  _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'Culture', '문화'),
  _NavItem(Icons.person_outline, Icons.person, 'Me', '나'),
];

// From this width up (tablets) the bottom bar becomes a side navigation rail.
const double _tabletBreakpoint = 700;

class MainScaffold extends StatefulWidget {
  final AppLanguage language;
  const MainScaffold({super.key, required this.language});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    HomePage(language: widget.language),
    const QuestsPage(),
    const NoticePage(), // Campus tab: left as it was (used for Notice Explained)
    const CulturePage(),
    const ProfilePage(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: _pages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= _tabletBreakpoint;

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            _buildNavigationRail(),
            const VerticalDivider(width: 1, thickness: 1, color: borderGray),
            Expanded(child: _buildBody()),
          ],
        ),
      );
    }

    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      labelType: NavigationRailLabelType.all,
      minWidth: 96,
      backgroundColor: Colors.white,
      indicatorColor: primaryBlue.withOpacity(0.12),
      selectedIconTheme: const IconThemeData(color: primaryBlue),
      unselectedIconTheme: const IconThemeData(color: Colors.grey),
      selectedLabelTextStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: primaryBlue,
      ),
      unselectedLabelTextStyle: const TextStyle(fontSize: 11, color: Colors.grey),
      destinations: _navItems.map((_NavItem item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.activeIcon),
          label: Text('${item.label}\n${item.labelKo}', textAlign: TextAlign.center),
          padding: const EdgeInsets.symmetric(vertical: 4),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        elevation: 0,
        items: _navItems.map((_NavItem item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: '${item.label} ${item.labelKo}',
          );
        }).toList(),
      ),
    );
  }
}
