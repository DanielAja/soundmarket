# Optimal Element File Division Plan for SoundMarket

This document outlines an optimal file structure for the SoundMarket Flutter application, designed to improve scalability, maintainability, and separation of concerns.

## Current Structure Overview

The current project has a basic structure with:
- Models (user_profile, song, portfolio_item, transaction)
- Services (song_service, music_data_api_service, storage_service)
- Providers (user_data_provider)
- Screens (home, discover, profile, transaction_history)

## Proposed Architecture

```
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart
│   │   └── environment_config.dart
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── asset_constants.dart
│   │   └── string_constants.dart
│   ├── error/
│   │   ├── error_handler.dart
│   │   └── exceptions.dart
│   ├── navigation/
│   │   ├── app_router.dart
│   │   └── route_constants.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── color_palette.dart
│       └── text_styles.dart
│
├── features/
│   ├── auth/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── widgets/
│   │   └── providers/
│   │
│   ├── market/
│   │   ├── models/
│   │   │   └── market_filter.dart
│   │   ├── screens/
│   │   │   ├── discover_screen.dart
│   │   │   └── song_detail_screen.dart
│   │   ├── services/
│   │   │   └── market_service.dart
│   │   ├── widgets/
│   │   │   ├── song_card.dart
│   │   │   ├── price_chart.dart
│   │   │   └── market_filters.dart
│   │   └── providers/
│   │       └── market_provider.dart
│   │
│   ├── portfolio/
│   │   ├── models/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   └── portfolio_detail_screen.dart
│   │   ├── services/
│   │   │   └── portfolio_service.dart
│   │   ├── widgets/
│   │   │   ├── portfolio_summary.dart
│   │   │   ├── portfolio_item_card.dart
│   │   │   └── performance_chart.dart
│   │   └── providers/
│   │       └── portfolio_provider.dart
│   │
│   ├── profile/
│   │   ├── models/
│   │   ├── screens/
│   │   │   └── profile_screen.dart
│   │   ├── services/
│   │   │   └── profile_service.dart
│   │   ├── widgets/
│   │   │   ├── profile_header.dart
│   │   │   └── settings_list.dart
│   │   └── providers/
│   │       └── profile_provider.dart
│   │
│   └── transactions/
│       ├── models/
│       ├── screens/
│       │   └── transaction_history_screen.dart
│       ├── services/
│       │   └── transaction_service.dart
│       ├── widgets/
│       │   ├── transaction_list.dart
│       │   └── transaction_item.dart
│       └── providers/
│           └── transaction_provider.dart
│
├── shared/
│   ├── models/
│   │   ├── user_profile.dart
│   │   ├── song.dart
│   │   ├── portfolio_item.dart
│   │   └── transaction.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── music_data_api_service.dart
│   │   ├── storage_service.dart
│   │   ├── analytics_service.dart
│   │   └── spotify_api_service.dart
│   ├── widgets/
│   │   ├── app_bar.dart
│   │   ├── loading_indicator.dart
│   │   ├── error_view.dart
│   │   └── empty_state.dart
│   ├── utils/
│   │   ├── formatters.dart
│   │   ├── validators.dart
│   │   └── extensions/
│   │       ├── string_extensions.dart
│   │       ├── date_extensions.dart
│   │       └── number_extensions.dart
│   └── providers/
│       └── user_data_provider.dart
│
└── main.dart
```

## Key Architecture Principles

### 1. Feature-First Organization
- Each major feature has its own directory with dedicated models, screens, services, widgets, and providers
- Promotes modularity and makes it easier to understand each feature's components

### 2. Shared Components
- Common models, services, and widgets used across multiple features are placed in the shared directory
- Prevents code duplication and ensures consistency

### 3. Core Infrastructure
- App-wide configurations, constants, themes, and navigation are centralized in the core directory
- Makes global changes easier to manage

### 4. Clear Separation of Concerns
- Models: Data structures
- Services: Business logic and data operations
- Providers: State management
- Screens: UI composition
- Widgets: Reusable UI components

### 5. Testing and Mocking Strategy
- Unit and widget tests should reside in the `test/` directory, mirroring the `lib/` structure (e.g., `test/features/portfolio/services/portfolio_service_test.dart`).
- Mock data and services used purely for testing should be placed in `test/mocks/`. Mocks needed for development builds can be managed via environment configuration.

## Implementation Benefits

1. **Scalability**: Easy to add new features without disrupting existing code
2. **Maintainability**: Related code is grouped together, making it easier to find and modify
3. **Testability**: Clear separation makes unit testing more straightforward
4. **Onboarding**: New developers can understand the project structure more quickly
5. **Isolation**: Issues in one feature are less likely to affect others

## Migration Strategy

1. Create the new directory structure
2. Move existing files to their new locations
3. Update imports across the codebase
4. Refactor any code that doesn't align with the new architecture
5. Implement new features following the established pattern

## Detailed Component Responsibilities

### Core Components

#### Config
- **app_config.dart**: Application-wide configuration settings
- **environment_config.dart**: Environment-specific configurations (dev, staging, prod)

#### Constants
- **api_constants.dart**: API endpoints and keys
- **asset_constants.dart**: Asset paths for images, fonts, etc.
- **string_constants.dart**: Text constants used throughout the app

#### Error
- **error_handler.dart**: Centralized error handling logic
- **exceptions.dart**: Custom exception classes

#### Navigation
- **app_router.dart**: Route definitions and navigation logic
- **route_constants.dart**: Named route constants

#### Theme
- **app_theme.dart**: Theme data and configuration
- **color_palette.dart**: Color definitions
- **text_styles.dart**: Typography styles

### Feature Components

Each feature module should follow a similar structure:

#### Models
- Data structures specific to the feature

#### Screens
- Full pages/screens for the feature

#### Services
- Business logic and data operations for the feature (e.g., `portfolio_service.dart` handles portfolio management including buy/sell logic, `market_service.dart` handles song data retrieval and pricing models).

#### Widgets
- UI components specific to the feature

#### Providers
- State management for the feature

### Shared Components

#### Models
- **user_profile.dart**: User data structure
- **song.dart**: Song data structure
- **portfolio_item.dart**: Portfolio item data structure
- **transaction.dart**: Transaction data structure

#### Services
- **api_service.dart**: Base API service with common functionality
- **music_data_api_service.dart**: Music data API interactions (e.g., fetching song details, charts)
- **storage_service.dart**: Local storage operations (e.g., saving/loading user data, preferences)
- **analytics_service.dart**: Analytics tracking
- **spotify_api_service.dart**: Interactions with the Spotify API (if used directly, e.g., for richer song data or playback features)

#### Widgets
- **app_bar.dart**: Common app bar
- **loading_indicator.dart**: Loading indicators
- **error_view.dart**: Error display components
- **empty_state.dart**: Empty state displays

#### Utils
- **formatters.dart**: Data formatting utilities
- **validators.dart**: Input validation functions
- **extensions/**: Extension methods for common types

#### Providers
- **user_data_provider.dart**: Global user data state management

## File Migration Guide

### Current Files to New Location

| Current Path | New Path |
|--------------|----------|
| lib/models/user_profile.dart | lib/shared/models/user_profile.dart |
| lib/models/song.dart | lib/shared/models/song.dart |
| lib/models/portfolio_item.dart | lib/shared/models/portfolio_item.dart |
| lib/models/transaction.dart | lib/shared/models/transaction.dart |
| lib/services/song_service.dart | lib/features/market/services/market_service.dart |
| lib/services/music_data_api_service.dart | lib/shared/services/music_data_api_service.dart |
| lib/services/storage_service.dart | lib/shared/services/storage_service.dart |
| lib/providers/user_data_provider.dart | lib/shared/providers/user_data_provider.dart |
| lib/screens/home_screen.dart | lib/features/portfolio/screens/home_screen.dart |
| lib/screens/discover_screen.dart | lib/features/market/screens/discover_screen.dart |
| lib/screens/profile_screen.dart | lib/features/profile/screens/profile_screen.dart |
| lib/screens/transaction_history_screen.dart | lib/features/transactions/screens/transaction_history_screen.dart |
| lib/services/spotify_api_service.dart | lib/shared/services/spotify_api_service.dart |
| lib/main.dart | lib/main.dart (unchanged) |

This architecture provides a solid foundation for the SoundMarket app while allowing for future growth and feature additions.
