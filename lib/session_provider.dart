import 'package:flutter/material.dart';

class SessionProvider extends InheritedWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout;

  const SessionProvider({
    super.key,
    required this.userData,
    required this.onLogout,
    required super.child,
  });

  static SessionProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SessionProvider>()!;
  }

  @override
  bool updateShouldNotify(SessionProvider old) =>
      userData != old.userData;
}