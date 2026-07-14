import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SkipLink extends StatefulWidget {
  const SkipLink({
    super.key,
    required this.label,
    required this.targetFocusNode,
  });

  final String label;
  final FocusNode targetFocusNode;

  @override
  State<SkipLink> createState() => _SkipLinkState();
}

class _SkipLinkState extends State<SkipLink> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.targetFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () {
            widget.targetFocusNode.requestFocus();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text(widget.label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )),
          ),
        ),
      ),
    );
  }
}

class ModalFocusTrap extends StatefulWidget {
  const ModalFocusTrap({
    super.key,
    required this.child,
    this.onClose,
  });

  final Widget child;
  final VoidCallback? onClose;

  @override
  State<ModalFocusTrap> createState() => _ModalFocusTrapState();
}

class _ModalFocusTrapState extends State<ModalFocusTrap> {
  final _focusScopeNode = FocusScopeNode();

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          widget.onClose?.call();
          Navigator.of(context).maybePop();
        },
      },
      child: FocusScope(
        node: _focusScopeNode,
        child: FocusTraversalGroup(
          child: widget.child,
        ),
      ),
    );
  }
}

class AccessibleNavObserver extends NavigatorObserver {
  String? _lastRouteName;

  @override
  void didPush(Route route, Route? previousRoute) {
    _announceRoute(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute != null) {
      _announceRoute(previousRoute);
    }
  }

  void _announceRoute(Route route) {
    final name = route.settings.name;
    if (name != null && name != _lastRouteName) {
      _lastRouteName = name;
    }
  }
}
