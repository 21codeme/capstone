import 'package:flutter/material.dart';

/// A customizable loading overlay that can be shown during asynchronous operations.
/// 
/// This widget provides a semi-transparent overlay with a loading indicator
/// and optional status message to indicate that an operation is in progress.
class LoadingOverlay extends StatelessWidget {
  /// The child widget that this overlay will be displayed on top of.
  final Widget child;
  
  /// Whether the loading overlay should be visible.
  final bool isLoading;
  
  /// Optional status message to display below the loading indicator.
  final String? statusMessage;
  
  /// The opacity of the background overlay (0.0 - 1.0).
  final double opacity;
  
  /// The color of the background overlay.
  final Color? color;
  
  /// The color of the progress indicator.
  final Color? progressColor;
  
  /// The size of the progress indicator.
  final double progressSize;
  
  /// The style of the text for the status message.
  final TextStyle? textStyle;

  const LoadingOverlay({
    Key? key,
    required this.child,
    required this.isLoading,
    this.statusMessage,
    this.opacity = 0.7,
    this.color,
    this.progressColor,
    this.progressSize = 50.0,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );

    return Stack(
      children: [
        // The main content
        child,
        
        // The loading overlay
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: (color ?? Colors.black).withOpacity(opacity),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Loading indicator
                    SizedBox(
                      width: progressSize,
                      height: progressSize,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor ?? Theme.of(context).primaryColor,
                        ),
                        strokeWidth: 4.0,
                      ),
                    ),
                    
                    // Status message (if provided)
                    if (statusMessage != null) ...[  
                      const SizedBox(height: 16.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          statusMessage!,
                          style: textStyle ?? defaultTextStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}