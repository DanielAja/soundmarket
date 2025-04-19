import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared/providers/user_data_provider.dart'; // Corrected path
import 'features/portfolio/screens/home_screen.dart'; // Corrected path
import 'features/market/screens/discover_screen.dart'; // Corrected path
import 'features/profile/screens/profile_screen.dart'; // Corrected path
// transaction_history_screen was moved but not used directly here, so removing import
import 'shared/services/music_data_api_service.dart'; // Corrected path
import 'shared/services/search_state_service.dart'; // Import for search state
import 'shared/services/portfolio_background_service.dart'; // Import for background service
import 'core/navigation/app_router.dart'; // Import for route generation
import 'core/navigation/route_constants.dart'; // Import for route constants
import 'shared/widgets/app_logo.dart'; // Import AppLogo widget

void main() async {
  // Ensure Flutter bindings are initialized for services like shared_preferences
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the background service for portfolio updates
  await PortfolioBackgroundService.init();

  // Create shared service instances
  final musicDataApiService = MusicDataApiService();
  final searchStateService = SearchStateService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserDataProvider(), // Provide the UserData state
        ),
        Provider<MusicDataApiService>.value(
          value: musicDataApiService, // Provide the music data API service
        ),
        ChangeNotifierProvider.value(
          value: searchStateService, // Provide the search state service
        ),
      ],
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
      // Configure routes using our AppRouter
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
      // Home is defined in the routes in AppRouter now
      theme: ThemeData(
        // Cash App inspired theme
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00D632), // Cash App green
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00D632), // Cash App green
          secondary: const Color(0xFF00C2FF), // Cash App blue accent
          surface:
              Colors
                  .black, // Use background color for surface (replacing deprecated background)
          // surface: const Color(0xFF121212),    // Removed duplicate Dark surface
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface:
              Colors
                  .white, // Use onBackground color for onSurface (replacing deprecated onBackground)
          // onSurface: Colors.white, // Removed duplicate onSurface
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
      // home removed - using initialRoute and onGenerateRoute instead
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
    HomeScreen(), // Removed const
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
      _musicDataApiService.setDiscoverTabActive(
        index == 1,
      ); // 1 is the index of the Discover tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor:
            Theme.of(context).colorScheme.primary, // Use theme color
        unselectedItemColor: Colors.grey, // Color for inactive tabs
        onTap: _onItemTapped,
        backgroundColor:
            Theme.of(context).colorScheme.surface, // Use theme surface color
      ),
    );
  }
}
