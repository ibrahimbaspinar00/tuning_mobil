import 'package:flutter/material.dart';

class ProfessionalComponents {
  // Professional App Bar
  static PreferredSizeWidget createAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    Color? backgroundColor,
    Color? foregroundColor,
    double elevation = 0,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      actions: actions,
      leading: leading,
    );
  }

  // Professional Card
  static Widget createCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    double elevation = 2,
    BorderRadius? borderRadius,
    BoxShadow? shadow,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: shadow != null 
            ? [shadow]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  // Professional Button
  static Widget createButton({
    required String text,
    required VoidCallback? onPressed,
    ButtonType type = ButtonType.primary,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    Color backgroundColor;
    Color foregroundColor;
    EdgeInsetsGeometry padding;
    double borderRadius;

    switch (type) {
      case ButtonType.primary:
        backgroundColor = Colors.blue[600]!;
        foregroundColor = Colors.white;
        break;
      case ButtonType.secondary:
        backgroundColor = Colors.grey[200]!;
        foregroundColor = Colors.black87;
        break;
      case ButtonType.success:
        backgroundColor = Colors.green[600]!;
        foregroundColor = Colors.white;
        break;
      case ButtonType.danger:
        backgroundColor = Colors.red[600]!;
        foregroundColor = Colors.white;
        break;
      case ButtonType.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = Colors.blue[600]!;
        break;
    }

    switch (size) {
      case ButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        borderRadius = 6;
        break;
      case ButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
        borderRadius = 8;
        break;
      case ButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
        borderRadius = 10;
        break;
    }

    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: size == ButtonSize.small ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (type == ButtonType.outline) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          side: BorderSide(color: foregroundColor),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: buttonChild,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 2,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: buttonChild,
    );
  }

  // Professional Input Field
  static Widget createInputField({
    required String label,
    String? hint,
    TextEditingController? controller,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Professional Loading Indicator
  static Widget createLoadingIndicator({
    String? message,
    double size = 40,
    Color? color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Colors.blue[600]!,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Professional Empty State
  static Widget createEmptyState({
    required String title,
    required String message,
    IconData? icon,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 300, // Minimum yükseklik
        ),
        child: IntrinsicHeight(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24), // Daha küçük padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 56, // Daha küçük icon
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16, // Daha küçük font
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13, // Daha küçük font
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (buttonText != null && onButtonPressed != null) ...[
                    const SizedBox(height: 20),
                    createButton(
                      text: buttonText,
                      onPressed: onButtonPressed,
                      type: ButtonType.primary,
                      size: ButtonSize.small, // Daha küçük buton
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

  // Professional Status Badge
  static Widget createStatusBadge({
    required String text,
    StatusType type = StatusType.info,
    bool isSmall = false,
  }) {
    Color backgroundColor;
    Color textColor;

    switch (type) {
      case StatusType.success:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case StatusType.warning:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case StatusType.error:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case StatusType.info:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // Professional Divider
  static Widget createDivider({
    String? text,
    double thickness = 1,
    Color? color,
    EdgeInsetsGeometry? margin,
  }) {
    if (text != null) {
      return Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Divider(
                thickness: thickness,
                color: color ?? Colors.grey[300],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                thickness: thickness,
                color: color ?? Colors.grey[300],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        thickness: thickness,
        color: color ?? Colors.grey[300],
      ),
    );
  }

  // Professional Section Header
  static Widget createSectionHeader({
    required String title,
    String? subtitle,
    Widget? action,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}

enum ButtonType { primary, secondary, success, danger, outline }
enum ButtonSize { small, medium, large }
enum StatusType { success, warning, error, info }
