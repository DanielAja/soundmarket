import 'package:flutter/material.dart';
import 'route_constants.dart';
import '../../features/portfolio/screens/home_screen.dart';
import '../../features/market/screens/discover_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/transactions/screens/transaction_history_screen.dart';
import '../../screens/portfolio_detail_screen.dart';

/// Route definitions and navigation logic
class AppRouter {
  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case RouteConstants.discover:
        return MaterialPageRoute(builder: (_) => const DiscoverScreen());
      
      case RouteConstants.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case RouteConstants.transactions:
        return MaterialPageRoute(builder: (_) => const TransactionHistoryScreen());
      
      case RouteConstants.portfolioDetails:
        return MaterialPageRoute(builder: (_) => const PortfolioDetailScreen());
      
      // Add more routes as needed
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
  
  // Navigation methods
  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }
  
  static void navigateToAndRemove(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
  
  static void navigateToAndReplace(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
  }
  
  static void pop(BuildContext context, [dynamic result]) {
    Navigator.of(context).pop(result);
  }
  
  static void popUntil(BuildContext context, String routeName) {
    Navigator.of(context).popUntil(ModalRoute.withName(routeName));
  }
  
  // Custom transitions
  static PageRouteBuilder<dynamic> slideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
  
  static PageRouteBuilder<dynamic> fadeTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
