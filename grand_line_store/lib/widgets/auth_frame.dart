import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'voyage_art.dart';

class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final form = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: child,
        ),
      );
      if (constraints.maxWidth < 850) return form;
      return Row(
        children: [
          Expanded(
            child: Container(
              color: AppTheme.ink,
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GRAND LINE\nTRADING COMPANY',
                    style: TextStyle(
                      color: AppTheme.paper,
                      fontSize: 14,
                      height: 1.6,
                      letterSpacing: 3,
                    ),
                  ),
                  const Expanded(child: VoyageArt()),
                  Text(
                    'For a life\nof adventure.',
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(color: AppTheme.paper),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'A collection for the dreamers, the collectors,\nand the crew that never stops sailing.',
                    style: TextStyle(color: Color(0xFFCED5CC), height: 1.7),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: form),
        ],
      );
    },
  );
}
