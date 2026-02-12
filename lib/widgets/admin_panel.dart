import 'package:flutter/material.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    this.padding = const EdgeInsets.all(18),
    this.expandChild = false,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final EdgeInsets padding;
  final Widget child;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final Color outline = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.08);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outline),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null || subtitle != null || actions.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (title != null)
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions.isNotEmpty)
                  Wrap(spacing: 10, runSpacing: 8, children: actions),
              ],
            ),
          if (title != null || subtitle != null || actions.isNotEmpty)
            const SizedBox(height: 14),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
