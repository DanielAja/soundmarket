# SoundMarket

SoundMarket is a Flutter application that simulates a music investment platform where users can buy and sell shares of songs, track their portfolio performance, and discover trending music.

## Features

### Portfolio Management
- **Portfolio Overview**: View all songs in your portfolio with detailed information
- **Buy/Sell Songs**: Trade shares of songs at current market prices
- **Performance Tracking**: Monitor profit/loss for each song in your portfolio
- **Transaction History**: View a complete history of all your trades

### Market Discovery
- **Top Songs**: Browse the most valuable songs on the platform
- **Top Movers**: Find songs with the biggest price changes
- **Genre Exploration**: Discover songs by genre
- **Artist Profiles**: View all songs by specific artists

### User Profile
- **Portfolio Statistics**: See key metrics about your investment performance
- **Balance Management**: Track your cash balance and total portfolio value
- **User Settings**: Customize your profile and app preferences

## Technical Details

### Architecture
- **Provider Pattern**: State management using the Provider package
- **Service Layer**: Separation of concerns with dedicated service classes
- **Repository Pattern**: Data access abstraction
- **Clean Architecture**: Organized code structure with feature-based modules

### Key Components
- **Models**: Data structures for songs, portfolio items, transactions, and user profiles
- **Services**: Business logic for song data, storage, and API interactions
- **Providers**: State management and data flow
- **Screens**: UI components for different app sections
- **Widgets**: Reusable UI elements

### Data Flow
1. **API Service**: Simulates real-time price updates and stream counts
2. **Song Service**: Manages song data and provides access to the app
3. **User Data Provider**: Centralizes user portfolio and transaction data
4. **UI Components**: Display data and handle user interactions

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio or VS Code with Flutter extensions

### Installation
1. Clone the repository:
   ```
   git clone https://github.com/yourusername/soundmarket.git
   ```

2. Navigate to the project directory:
   ```
   cd soundmarket
   ```

3. Set up API keys:
   - Copy `lib/core/config/api_keys.template.dart` to `lib/core/config/api_keys.dart`
   - Replace the placeholder values with your actual Spotify API credentials:
     ```dart
     static const String spotifyClientId = 'YOUR_SPOTIFY_CLIENT_ID';
     static const String spotifyClientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
     static const String spotifyRedirectUri = 'YOUR_SPOTIFY_REDIRECT_URI';
     ```
   - Note: The `api_keys.dart` file is ignored by git to keep your credentials secure

4. Install dependencies:
   ```
   flutter pub get
   ```

5. Run the app:
   ```
   flutter run
   ```

### Development
- **Run in Debug Mode**:
  ```
  flutter run
  ```

- **Build Release Version**:
  ```
  flutter build apk  # For Android
  flutter build ios  # For iOS
  ```

## Project Structure

```
lib/
├── core/                 # Core functionality and constants
│   ├── config/           # App configuration
│   ├── constants/        # App-wide constants
│   ├── error/            # Error handling
│   ├── navigation/       # Routing and navigation
│   └── theme/            # App theming
├── features/             # Feature-based modules
│   ├── auth/             # Authentication
│   ├── market/           # Market discovery
│   ├── portfolio/        # Portfolio management
│   ├── profile/          # User profile
│   └── transactions/     # Transaction history
├── models/               # Data models
├── providers/            # State management
├── screens/              # UI screens
├── services/             # Business logic and API services
└── shared/               # Shared utilities and widgets
    ├── services/         # Common services
    ├── utils/            # Utility functions
    └── widgets/          # Reusable widgets
```

## Portfolio Detail Screen

The Portfolio Detail Screen provides comprehensive information about all songs in the user's portfolio, including:

- **Portfolio Summary**: Total portfolio value, cash balance, and total balance
- **Song Details**: For each song in the portfolio:
  - Basic information (name, artist, genre)
  - Financial data (purchase price, current price, profit/loss)
  - Performance metrics (price change percentage)
  - Stream count data
  - Buy/sell functionality

This screen is accessible from the Profile screen via the "View Full Portfolio" button.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All contributors to the project
