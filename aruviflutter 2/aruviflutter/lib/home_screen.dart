import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'tabs/home_all_tab.dart';
import 'tabs/home_artist_tab.dart';
import 'tabs/home_devotional_tab.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/top_nav_item.dart';
import 'scanner_screen.dart';
import 'color_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  TabController? _tabController;

  List<TopNavItem> _tabs = [
    TopNavItem(topmenuId: 1, topmenuName: 'ALL'),
    TopNavItem(topmenuId: 3, topmenuName: 'ARTIST'),
    TopNavItem(topmenuId: 4, topmenuName: 'DIVOTIONAL'),
  ];
  int _selectedIndex = 0;
  bool _isLoading = false; // We can set this to false initially since we have default tabs, but let's keep it true if we want to show loading indicator for the body.
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController!.index;
        });
      }
    });
    _loadTabs();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? '';
      // Fallback if userName is empty
      if (_userName.isEmpty) {
        _userName = 'User';
      }
    });
  }

  Future<void> _loadTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final topNavJson = prefs.getString('top_navigation');
      
      if (topNavJson != null && topNavJson.isNotEmpty) {
        final List<dynamic> parsed = json.decode(topNavJson);
        final loadedTabs = parsed.map((e) => TopNavItem.fromJson(e)).toList();
        if (loadedTabs.isNotEmpty) {
          setState(() {
            _tabs = loadedTabs;
            // Only reinitialize tab controller if length changed or we want to be safe
            if (_tabController?.length != _tabs.length) {
              _tabController?.dispose();
              _tabController = TabController(length: _tabs.length, vsync: this);
              _tabController!.addListener(() {
                if (!_tabController!.indexIsChanging) {
                  setState(() {
                    _selectedIndex = _tabController!.index;
                  });
                }
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading tabs: $e');
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 60,
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Profile Icon
            GestureDetector(
              onTap: () {
                context.findRootAncestorStateOfType<ScaffoldState>()?.openDrawer();
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: getAvatarColor(_userName),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Tabs List
            Expanded(
              child: SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  itemBuilder: (context, index) {
                    bool isSelected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () {
                        _tabController?.animateTo(index);
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEB1C24) : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _tabs[index].topmenuName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEB1C24)))
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final tabName = tab.topmenuName.toLowerCase();
                if (tabName == 'all') {
                  return const HomeAllTab();
                } else if (tabName == 'artist') {
                  return const HomeArtistTab();
                } else if (tabName == 'divotional' || tabName == 'devotional') {
                  return const HomeDevotionalTab();
                } else {
                  return Center(child: Text('${tab.topmenuName.toUpperCase()} TAB', style: const TextStyle(color: Colors.white)));
                }
              }).toList(),
            ),
    );
  }
}
