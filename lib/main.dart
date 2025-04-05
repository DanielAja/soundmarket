import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_data_provider.dart';
import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  // Ensure Flutter bindings are initialized for services like shared_preferences
  WidgetsFlutterBinding.ensureInitialized(); 
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserDataProvider(), // Provide the UserData state
      child: const SoundMarketApp(),
    ),
  );
}

class SoundMarketApp extends StatelessWidget {
  const SoundMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sound Market',
      theme: ThemeData(
        // Define a base theme - mix of Spotify (dark) and Robinhood (green accents)
        brightness: Brightness.dark, // Dark theme base like Spotify
        primaryColor: Colors.green, // Robinhood green for primary elements
        colorScheme: ColorScheme.dark(
          primary: Colors.green,       // Primary color for buttons, etc.
          secondary: Colors.greenAccent, // Accent color
          background: Colors.black,     // Spotify-like black background
          surface: Colors.grey[900]!,   // Slightly lighter surface color
          onPrimary: Colors.black,      // Text on primary color
          onSecondary: Colors.black,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        // Define other theme properties like text themes if needed
      ),
      home: const MainNavigationWrapper(),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0; // Start on the Home tab

  // List of screens for the bottom navigation
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const DiscoverScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary, // Use theme color
        unselectedItemColor: Colors.grey, // Color for inactive tabs
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.surface, // Use theme surface color
      ),
    );
  }
}
