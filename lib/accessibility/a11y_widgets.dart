import 'package:flutter/material.dart';
import 'a11y_constants.dart';

class AccessibleIconButton extends StatelessWidget {
  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size,
    this.color,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      enabled: onPressed != null,
      child: ConstrainedBox(
        constraints: touchTargetConstraints,
        child: IconButton(
          icon: icon,
          tooltip: tooltip,
          onPressed: onPressed,
          iconSize: size ?? 24,
          color: color,
          constraints: touchTargetConstraints,
        ),
      ),
    );
  }
}

class AccessibleFab extends StatelessWidget {
  const AccessibleFab({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: FloatingActionButton(
        heroTag: null,
        tooltip: tooltip,
        onPressed: onPressed,
        child: icon,
      ),
    );
  }
}

class AccessibleTextField extends StatelessWidget {
  const AccessibleTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.autofocus = false,
    this.errorText,
    this.focusNode,
    this.suffixIcon,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final bool autofocus;
  final String? errorText;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null || validator != null;

    return Semantics(
      label: label,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            label: label,
            child: Text(label,
                style: Theme.of(context).textTheme.labelLarge),
          ),
          AnimatedContainer(
            duration: Duration.zero,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              maxLines: maxLines,
              autofocus: autofocus,
              decoration: InputDecoration(
                labelText: label,
                hintText: hintText,
                errorText: errorText,
                suffixIcon: suffixIcon,
                prefixIcon: prefixIcon,
              ),
            ),
          ),
          if (hasError && errorText != null)
            Semantics(
              liveRegion: true,
              child: Text(
                errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SemanticsHeading extends StatelessWidget {
  const SemanticsHeading({
    super.key,
    required this.child,
    this.label,
  });

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: label,
      child: child,
    );
  }
}

class SemanticsScreenTitle extends StatelessWidget {
  const SemanticsScreenTitle({
    super.key,
    required this.label,
    this.child,
  });

  final String label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class AccessibleDialog extends StatelessWidget {
  const AccessibleDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.onClose,
  });

  final String title;
  final Widget content;
  final List<Widget>? actions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      container: true,
      child: AlertDialog(
        title: Semantics(
          header: true,
          label: title,
          child: Text(title),
        ),
        content: FocusTraversalGroup(child: content),
        actions: actions,
      ),
    );
  }
}

class SemanticsIcon extends StatelessWidget {
  const SemanticsIcon({
    super.key,
    required this.icon,
    required this.label,
    this.size,
    this.color,
  });

  final IconData icon;
  final String label;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Icon(icon, size: size, color: color),
    );
  }
}
