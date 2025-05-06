import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool readOnly;
  final bool enabled;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool autofocus;
  final bool showCursor;
  final AutovalidateMode autovalidateMode;
  final TextCapitalization textCapitalization;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  final bool filled;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final bool isDense;
  final TextStyle? style;

  const CustomTextField({
    Key? key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.focusNode,
    this.onTap,
    this.contentPadding,
    this.autofocus = false,
    this.showCursor = true,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.filled = true,
    this.fillColor,
    this.borderRadius,
    this.isDense = false,
    this.style,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderRadius = widget.borderRadius ?? BorderRadius.circular(8);
    final defaultPadding = widget.contentPadding ?? 
        EdgeInsets.symmetric(
          horizontal: 16, 
          vertical: widget.isDense ? 12 : 16
        );
    
    // Default colors
    final defaultFillColor = widget.fillColor ?? 
        (widget.errorText != null 
            ? theme.colorScheme.error.withOpacity(0.1) 
            : _isFocused 
                ? theme.primaryColor.withOpacity(0.05) 
                : Colors.grey[100]);
    
    // Handle password visibility toggle
    Widget? suffixIconWidget = widget.suffixIcon;
    if (widget.obscureText && suffixIconWidget == null) {
      suffixIconWidget = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.errorText != null ? theme.colorScheme.error : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 6),
        ],
        
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          focusNode: _focusNode,
          onTap: widget.onTap,
          autofocus: widget.autofocus,
          showCursor: widget.showCursor,
          autovalidateMode: widget.autovalidateMode,
          textCapitalization: widget.textCapitalization,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          inputFormatters: widget.inputFormatters,
          style: widget.style ?? TextStyle(fontSize: 16, color: Colors.grey[900]),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: widget.style?.fontSize ?? 16,
            ),
            helperText: widget.helperText,
            helperStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            errorText: widget.errorText,
            errorStyle: const TextStyle(
              fontSize: 12,
            ),
            isDense: widget.isDense,
            filled: widget.filled,
            fillColor: widget.enabled ? defaultFillColor : Colors.grey[200],
            contentPadding: defaultPadding,
            prefixIcon: widget.prefixIcon != null 
                ? Icon(
                    widget.prefixIcon,
                    color: widget.errorText != null 
                        ? theme.colorScheme.error 
                        : _isFocused 
                            ? theme.primaryColor 
                            : Colors.grey[600],
                    size: 20,
                  ) 
                : null,
            prefixIconConstraints: widget.prefixIconConstraints,
            suffixIcon: suffixIconWidget,
            suffixIconConstraints: widget.suffixIconConstraints,
            counterText: "",  // Hide the counter
            border: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide(
                color: widget.errorText != null 
                    ? theme.colorScheme.error 
                    : Colors.grey[300]!,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide(
                color: widget.errorText != null 
                    ? theme.colorScheme.error 
                    : theme.primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: defaultBorderRadius,
              borderSide: BorderSide(
                color: Colors.grey[200]!,
                width: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}