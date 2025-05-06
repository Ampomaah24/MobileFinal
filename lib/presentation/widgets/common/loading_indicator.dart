import 'package:flutter/material.dart';

enum LoadingSize { tiny, small, medium, large }
enum LoadingType { circular, linear }

class LoadingIndicator extends StatelessWidget {
  final LoadingSize size;
  final LoadingType type;
  final Color? color;
  final String? message;
  final double? value; // For determinate progress
  final bool centered;
  final bool overlay;
  final Color? backgroundColor;
  final double backgroundOpacity;
  final EdgeInsetsGeometry padding;

  const LoadingIndicator({
    Key? key,
    this.size = LoadingSize.medium,
    this.type = LoadingType.circular,
    this.color,
    this.message,
    this.value,
    this.centered = true,
    this.overlay = false,
    this.backgroundColor,
    this.backgroundOpacity = 0.7,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.primaryColor;
    
    // Create indicator widget based on type
    Widget indicator;
    
    switch (type) {
      case LoadingType.circular:
        indicator = SizedBox(
          width: _getSizeValue(),
          height: _getSizeValue(),
          child: CircularProgressIndicator(
            strokeWidth: _getStrokeWidth(),
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            value: value,
          ),
        );
        break;
      
      case LoadingType.linear:
        indicator = LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          backgroundColor: indicatorColor.withOpacity(0.2),
          value: value,
          minHeight: _getLinearHeight(),
        );
        break;
    }
    
    // Add message if provided
    if (message != null) {
      indicator = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              fontSize: _getMessageFontSize(),
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    
    // Apply padding
    if (padding != EdgeInsets.zero) {
      indicator = Padding(
        padding: padding,
        child: indicator,
      );
    }
    
    // Center if requested
    if (centered) {
      indicator = Center(child: indicator);
    }
    
    // Create overlay if requested
    if (overlay) {
      final bgColor = backgroundColor ?? Colors.black;
      
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Opacity(
                opacity: backgroundOpacity,
                child: Container(
                  color: bgColor,
                ),
              ),
            ),
            
            // Loading indicator
            if (type == LoadingType.circular) ...[
              indicator,
            ] else ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: indicator,
              ),
            ],
          ],
        ),
      );
    }
    
    return indicator;
  }

  double _getSizeValue() {
    switch (size) {
      case LoadingSize.tiny:
        return 16.0;
      case LoadingSize.small:
        return 24.0;
      case LoadingSize.medium:
        return 40.0;
      case LoadingSize.large:
        return 56.0;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case LoadingSize.tiny:
        return 1.5;
      case LoadingSize.small:
        return 2.0;
      case LoadingSize.medium:
        return 3.0;
      case LoadingSize.large:
        return 4.0;
    }
  }

  double _getLinearHeight() {
    switch (size) {
      case LoadingSize.tiny:
        return 2.0;
      case LoadingSize.small:
        return 3.0;
      case LoadingSize.medium:
        return 5.0;
      case LoadingSize.large:
        return 8.0;
    }
  }

  double _getMessageFontSize() {
    switch (size) {
      case LoadingSize.tiny:
        return 10.0;
      case LoadingSize.small:
        return 12.0;
      case LoadingSize.medium:
        return 14.0;
      case LoadingSize.large:
        return 16.0;
    }
  }
}

// Full-screen loading overlay with a card container
class FullScreenLoading extends StatelessWidget {
  final String? message;
  final bool dismissible;
  final VoidCallback? onDismiss;

  const FullScreenLoading({
    Key? key,
    this.message,
    this.dismissible = false,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dismissible ? (onDismiss ?? () => Navigator.of(context).pop()) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingIndicator(
                    size: LoadingSize.large,
                    centered: true,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      message!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Utility class to show/hide a loading overlay
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;
  
  // Show a full-screen loading overlay
  static void show(
    BuildContext context, {
    String? message,
    bool dismissible = false,
    VoidCallback? onDismiss,
  }) {
    hide(); // Hide any existing overlay first
    
    _overlayEntry = OverlayEntry(
      builder: (context) => FullScreenLoading(
        message: message,
        dismissible: dismissible,
        onDismiss: onDismiss,
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  // Hide the currently displayed overlay
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}