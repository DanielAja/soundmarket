import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/user_data_provider.dart';
import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'services/music_data_api_service.dart';

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
        // Cash App inspired theme
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00D632), // Cash App green
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00D632),    // Cash App green
          secondary: const Color(0xFF00C2FF),  // Cash App blue accent
          background: Colors.black,
          surface: const Color(0xFF121212),    // Dark surface
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        // Card theme
        cardTheme: CardTheme(
          color: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
        ),
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D632),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
        // Text theme with Cash App-like font
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          titleLarge: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
        // App bar theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        // Bottom navigation bar theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Color(0xFF00D632),
          unselectedItemColor: Colors.grey,
        ),
        useMaterial3: true,
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
  final MusicDataApiService _musicDataApiService = MusicDataApiService();

  // List of screens for the bottom navigation
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const DiscoverScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initially the discover tab is not active
    _musicDataApiService.setDiscoverTabActive(false);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      
      // Update the discover tab active state
      _musicDataApiService.setDiscoverTabActive(index == 1); // 1 is the index of the Discover tab
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
