import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return const Center(child: Text('No profile available'));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null
                ? Text(
                    _initials(user.displayName ?? user.email ?? ''),
                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user.displayName?.isNotEmpty == true ? user.displayName! : 'Unnamed user',
            style: theme.textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            user.email ?? 'No email',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 24),
        _InfoTile(
          icon: Icons.phone,
          title: 'Phone number',
          value: user.phoneNumber ?? 'Not provided',
        ),
        _InfoTile(
          icon: Icons.badge_outlined,
          title: 'UID',
          value: user.uid,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _confirmSignOut(context),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }

  static String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : (parts.first.length > 1 ? parts.first[1] : '');
    final initials = (first + second).trim();
    return initials.isEmpty ? trimmed[0].toUpperCase() : initials.toUpperCase();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text('You will need to sign in again to resume tracking.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ) ??
        false;
    if (shouldSignOut) {
      await context.read<AuthService>().signOut();
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value.isEmpty ? 'Not provided' : value),
    );
  }
}
