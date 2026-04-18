import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    super.key,
    this.child,
    this.body,
    this.actions = const <Widget>[],
    this.floatingActionButton,
  }) : assert(
         child != null || body != null,
         'Either child or body must be provided.',
       );

  final String title;
  final Widget? child;
  final Widget? body;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child ?? body!,
            ),
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
