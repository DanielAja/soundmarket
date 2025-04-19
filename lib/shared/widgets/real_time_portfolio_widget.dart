import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:provider/provider.dart';
import '../models/portfolio_item.dart'; // Corrected path
import '../models/song.dart'; // Corrected path
import '../providers/user_data_provider.dart'; // Corrected path
import '../../features/portfolio/services/portfolio_service.dart'; // Corrected path

class RealTimePortfolioWidget extends StatefulWidget {
  final Function(PortfolioItem, Song)? onItemTap;
  
  const RealTimePortfolioWidget({
    super.key, // Use super parameter
    this.onItemTap,
  });

  @override
  State<RealTimePortfolioWidget> createState() => _RealTimePortfolioWidgetState();
}

class _RealTimePortfolioWidgetState extends State<RealTimePortfolioWidget> with TickerProviderStateMixin {
  // Timer for updating the timestamp
  Timer? _timestampTimer;
  String _lastUpdated = '';
  
  // Animation controllers for price update effects
  late AnimationController _flashAnimationController;
  late Animation<Color?> _flashAnimation;
  
  // Animation controller for pulse effect
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  
  // Map to track which items were recently updated
  final Map<String, bool> _recentlyUpdatedItems = {};
  
  @override
  void initState() {
    super.initState();
    _updateTimestamp();
    
    // Update timestamp every second
    _timestampTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimestamp();
    });
    
    // Initialize flash animation controller
    _flashAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // We'll update this animation dynamically based on price change direction
    _flashAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.blue.withAlpha(60), // Slightly more visible
    ).animate(CurvedAnimation(
      parent: _flashAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _flashAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flashAnimationController.reverse();
      }
    });
    
    // Initialize pulse animation controller
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15, // Scale up by 15%
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _timestampTimer?.cancel();
    _flashAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }
  
  void _updateTimestamp() {
    if (mounted) {
      setState(() {
        final now = DateTime.now();
        _lastUpdated = '${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      });
    }
  }
  
  // Method to trigger animation for an item when its price changes
  void _animateItemUpdate(String songId) {
    // Mark the item as recently updated
    setState(() {
      _recentlyUpdatedItems[songId] = true;
    });
    
    // Flash the animation
    _flashAnimationController.forward(from: 0.0);
    
    // Make sure pulse animator is running
    if (!_pulseAnimationController.isAnimating) {
      _pulseAnimationController.repeat(reverse: true);
    }
    
    // Reset the updated flag after animation completes
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _recentlyUpdatedItems[songId] = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, provider, child) {
        final portfolio = provider.portfolio;
        
        if (portfolio.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Use Flexible to allow text to wrap or shrink
                    const Flexible(
                      child: Text(
                        'Real-Time Portfolio Updates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Add some spacing
                    const SizedBox(width: 8),
                    // Use a more compact timestamp display
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          _lastUpdated,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...portfolio.map((item) => _buildPortfolioItemTile(context, item, provider)),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPortfolioItemTile(
    BuildContext context, 
    PortfolioItem item, 
    UserDataProvider provider
  ) {
    // Get the song to access current price and other details
    final song = provider.allSongs.firstWhere(
      (s) => s.id == item.songId,
      orElse: () => Song(
        id: item.songId,
        name: item.songName,
        artist: item.artistName,
        genre: 'Unknown',
        currentPrice: item.purchasePrice,
      ),
    );
    
    // Calculate values
    final currentValue = item.quantity * song.currentPrice;
    
    // Get price change indicator
    final priceChange = provider.getPriceChangeIndicator(item.songId);
    
    // Determine indicator color
    Color indicatorColor = Colors.transparent;
    IconData indicatorIcon = Icons.remove;
    
    // Use the PriceChange enum from the imported PortfolioService
    if (priceChange == PriceChange.increase) {
      indicatorColor = Colors.green;
      indicatorIcon = Icons.arrow_upward;
    } else if (priceChange == PriceChange.decrease) {
      indicatorColor = Colors.red;
      indicatorIcon = Icons.arrow_downward;
    }
    
    // Check if this item was recently updated
    final isRecentlyUpdated = _recentlyUpdatedItems[item.songId] == true;
    
    return AnimatedBuilder(
      animation: _flashAnimationController,
      builder: (context, child) {
        return InkWell(
          onTap: widget.onItemTap != null ? () => widget.onItemTap!(item, song) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isRecentlyUpdated ? _flashAnimation.value : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isRecentlyUpdated ? Border.all(
                color: (priceChange == PriceChange.increase ? Colors.green : 
                       priceChange == PriceChange.decrease ? Colors.red : 
                       Colors.transparent).withOpacity(0.3),
                width: 0.5,
              ) : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  // Price change indicator with enhanced animation
                  AnimatedBuilder(
                    animation: _pulseAnimationController,
                    builder: (context, child) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isRecentlyUpdated ? 6 : 4, // Wider when updated
                        height: isRecentlyUpdated ? 45 : 40, // Taller when updated
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          borderRadius: BorderRadius.circular(isRecentlyUpdated ? 3 : 2),
                          boxShadow: isRecentlyUpdated ? [
                            BoxShadow(
                              color: indicatorColor.withAlpha(isRecentlyUpdated ? 
                                 (128 + (50 * _pulseAnimation.value).toInt()).clamp(0, 255) : 0), // Pulsing glow
                              blurRadius: isRecentlyUpdated ? 6 * _pulseAnimation.value : 0,
                              spreadRadius: isRecentlyUpdated ? 2 * _pulseAnimation.value : 0,
                            ),
                          ] : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.songName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.artistName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Price and quantity - with constraints to prevent overflow
                  Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Use the PriceChange enum from the imported PortfolioService
                            if (priceChange != PriceChange.none)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  indicatorIcon,
                                  color: indicatorColor,
                                  size: isRecentlyUpdated ? 16 : 14, // Larger when updated
                                ),
                              ),
                            const SizedBox(width: 4),
                            StreamBuilder<List<Song>>(
                              stream: Provider.of<UserDataProvider>(context, listen: false).songUpdatesStream,
                              initialData: const [],
                              builder: (context, snapshot) {
                                // Find the current song in the updates if available
                                Song? updatedSong;
                                if (snapshot.hasData) {
                                  updatedSong = snapshot.data!.firstWhere(
                                    (s) => s.id == song.id,
                                    orElse: () => song,
                                  );
                                  
                                  // Check if price has changed and trigger the animation
                                  if (updatedSong.currentPrice != song.currentPrice &&
                                      !_recentlyUpdatedItems.containsKey(item.songId)) {
                                    // Determine animation color based on price change direction
                                    Color flashColor;
                                    if (updatedSong.currentPrice > song.currentPrice) {
                                      flashColor = Colors.green.withAlpha(50);
                                      HapticFeedback.lightImpact();
                                    } else {
                                      flashColor = Colors.red.withAlpha(50);
                                      HapticFeedback.mediumImpact();
                                    }
                                    
                                    // Use Future.microtask to avoid setState during build
                                    Future.microtask(() {
                                      // Update the animation color
                                      _flashAnimation = ColorTween(
                                        begin: Colors.transparent,
                                        end: flashColor,
                                      ).animate(CurvedAnimation(
                                        parent: _flashAnimationController,
                                        curve: Curves.easeInOut,
                                      ));
                                      
                                      // Trigger the animation
                                      _animateItemUpdate(item.songId);
                                    });
                                  }
                                }
                                
                                // Use updated song data if available, otherwise use original song
                                final displaySong = updatedSong ?? song;
                                
                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300), // Faster animation
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.0, -0.3), // Smaller slide for faster feel
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutQuad, // Faster curve
                                        )),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: AnimatedBuilder(
                                    animation: _pulseAnimationController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: isRecentlyUpdated ? _pulseAnimation.value : 1.0,
                                        child: Text(
                                          '\$${displaySong.currentPrice.toStringAsFixed(2)}',
                                          key: ValueKey<String>(displaySong.currentPrice.toStringAsFixed(2)),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isRecentlyUpdated ? 16 : 14, // Larger when updated
                                            color: priceChange == PriceChange.none
                                                ? Theme.of(context).textTheme.bodyLarge?.color // Use theme color for 'none'
                                                : indicatorColor,
                                            shadows: isRecentlyUpdated ? [
                                              Shadow(
                                                color: indicatorColor.withAlpha(128), // 0.5 opacity equals 128 in alpha (255*0.5)
                                                blurRadius: 4,
                                              ),
                                            ] : null,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        // Total value moved above quantity for prioritization
                        StreamBuilder<List<Song>>(
                          stream: Provider.of<UserDataProvider>(context, listen: false).songUpdatesStream,
                          initialData: const [],
                          builder: (context, snapshot) {
                            // Recalculate the current value with updated prices
                            double updatedValue = currentValue;
                            if (snapshot.hasData) {
                              final updatedSong = snapshot.data!.firstWhere(
                                (s) => s.id == song.id,
                                orElse: () => song,
                              );
                              updatedValue = item.quantity * updatedSong.currentPrice;
                            }
                            
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, -0.3),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutQuad,
                                    )),
                                    child: child,
                                  ),
                                );
                              },
                              child: AnimatedBuilder(
                                animation: _pulseAnimationController,
                                builder: (context, child) {
                                  final valueColor = priceChange == PriceChange.increase ? Colors.green[700] :
                                                    priceChange == PriceChange.decrease ? Colors.red[700] :
                                                    Colors.grey[600];
                                                    
                                  final shadowColor = priceChange == PriceChange.increase ? Colors.green : 
                                                     priceChange == PriceChange.decrease ? Colors.red : 
                                                     Colors.grey;
                                  
                                  return Transform.scale(
                                    scale: isRecentlyUpdated ? _pulseAnimation.value * 0.95 : 1.0, // Slightly less scaling
                                    child: Text(
                                      '\$${updatedValue.toStringAsFixed(2)}',
                                      key: ValueKey<String>(updatedValue.toStringAsFixed(2)),
                                      style: TextStyle(
                                        fontSize: isRecentlyUpdated ? 13 : 12,
                                        fontWeight: isRecentlyUpdated ? FontWeight.bold : FontWeight.w500, // Bolder when updated
                                        color: valueColor,
                                        shadows: isRecentlyUpdated ? [
                                          Shadow(
                                            color: shadowColor.withAlpha(128), // 0.5 opacity equals 128 in alpha (255*0.5)
                                            blurRadius: 3,
                                          ),
                                        ] : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        Text(
                          '${item.quantity} ${item.quantity == 1 ? 'share' : 'shares'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
