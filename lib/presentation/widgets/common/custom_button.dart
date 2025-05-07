import 'package:flutter/material.dart';

enum ButtonSize { small, medium, large }
enum ButtonType { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null || isLoading;
    
    // Define button styling based on type
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    
    switch (type) {
      case ButtonType.primary:
        backgroundColor = isDisabled ? Colors.grey[300]! : theme.primaryColor;
        textColor = Colors.white;
        borderColor = Colors.transparent;
        break;
      case ButtonType.secondary:
        backgroundColor = isDisabled ? Colors.grey[200]! : theme.primaryColor.withOpacity(0.1);
        textColor = isDisabled ? Colors.grey[500]! : theme.primaryColor;
        borderColor = Colors.transparent;
        break;
      case ButtonType.outlined:
        backgroundColor = Colors.transparent;
        textColor = isDisabled ? Colors.grey[400]! : theme.primaryColor;
        borderColor = isDisabled ? Colors.grey[300]! : theme.primaryColor;
        break;
      case ButtonType.text:
        backgroundColor = Colors.transparent;
        textColor = isDisabled ? Colors.grey[400]! : theme.primaryColor;
        borderColor = Colors.transparent;
        break;
    }
    
    // Button padding based on size
    final buttonPadding = padding ?? _getPaddingForSize();
    
    // Button border radius
    final buttonBorderRadius = borderRadius ?? BorderRadius.circular(8);
    
    // Button content
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null && !isLoading) ...[
          Icon(leadingIcon, size: _getIconSize(), color: textColor),
          SizedBox(width: size == ButtonSize.small ? 4 : 8),
        ],
        if (isLoading) ...[
          SizedBox(
            height: _getLoadingSize(),
            width: _getLoadingSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          SizedBox(width: size == ButtonSize.small ? 6 : 10),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          SizedBox(width: size == ButtonSize.small ? 4 : 8),
          Icon(trailingIcon, size: _getIconSize(), color: textColor),
        ],
      ],
    );
    
    // Button widget based on type
    Widget buttonWidget;
    switch (type) {
      case ButtonType.outlined:
        buttonWidget = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: buttonPadding,
            shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
            side: BorderSide(color: borderColor, width: 1.5),
            backgroundColor: backgroundColor,
          ),
          child: buttonContent,
        );
        break;
      case ButtonType.text:
        buttonWidget = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: buttonPadding,
            shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
            backgroundColor: backgroundColor,
          ),
          child: buttonContent,
        );
        break;
      default:
        buttonWidget = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: buttonPadding,
            shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
            backgroundColor: backgroundColor,
            disabledBackgroundColor: backgroundColor,
            elevation: type == ButtonType.secondary ? 0 : 2,
            shadowColor: Colors.black.withOpacity(0.2),
          ),
          child: buttonContent,
        );
    }
    
    
    
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: buttonWidget,
      );
    }
    
    return buttonWidget;
  }
  
  // Helper methods for sizing elements
  EdgeInsetsGeometry _getPaddingForSize() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }
  
  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }
  
  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }
  
  double _getLoadingSize() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 20;
    }
  }
}