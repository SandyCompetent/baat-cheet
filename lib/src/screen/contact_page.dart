import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/auth/auth_service.dart';
import 'package:chatbud/src/core/app_state.dart';
import 'package:chatbud/src/core/avatar_helper.dart';
import 'package:chatbud/src/services/chat_service.dart';
import 'package:chatbud/src/widgets/legal_dialog.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  void _showEditNameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: AppState.instance.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                await AppState.instance.updateDisplayName(newName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppState.instance.isLoggedIn
                            ? 'Display name updated to "$newName".'
                            : 'Display name temporarily set to "$newName" (Guest mode).',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto_rounded),
              title: const Text('System Default'),
              trailing: AppState.instance.themeMode == ThemeMode.system
                  ? Icon(Icons.check_rounded, color: context.accent)
                  : null,
              onTap: () {
                AppState.instance.setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Light Slate'),
              trailing: AppState.instance.themeMode == ThemeMode.light
                  ? Icon(Icons.check_rounded, color: context.accent)
                  : null,
              onTap: () {
                AppState.instance.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Slate (OLED)'),
              trailing: AppState.instance.themeMode == ThemeMode.dark
                  ? Icon(Icons.check_rounded, color: context.accent)
                  : null,
              onTap: () {
                AppState.instance.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Feedback'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'What can we improve in ChatBud?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                final currentUid =
                    AuthService.currentUser?.uid ?? 'anonymous';
                await ChatService.instance.reportContent(
                  reportedUserId: 'system',
                  messageId: 'feedback_${DateTime.now().millisecondsSinceEpoch}',
                  reason: 'User Feedback',
                  messageText: text,
                  reporterId: currentUid,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you! Your feedback has been received and saved.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your chats and preferences are securely saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.statusDanger,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
              await AppState.instance.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signed out successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Mandatory App Store & Google Play requirement: Account Deletion
  void _confirmAccountDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: context.statusDanger),
            const SizedBox(width: 8),
            const Text('Delete Account'),
          ],
        ),
        content: const Text(
          'This action is irreversible. All your messages, profile information, and account data will be permanently purged from ChatBud servers.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.statusDanger,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await AuthService.deleteAccount();
              if (res.success) {
                await AppState.instance.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account permanently deleted.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.errorMessage ?? 'Deletion failed.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Permanently Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;

        return Scaffold(
          backgroundColor: context.bgCanvas,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  color: context.bgSurface,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 24,
                    bottom: 28,
                    left: 24,
                    right: 24,
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showEditNameDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.accent,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: getAvatarColor(
                              state.displayName.isNotEmpty && state.displayName != 'Guest User'
                                  ? state.displayName
                                  : state.email,
                            ),
                            child: Text(
                              getInitials(state.displayName, state.email),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        state.displayName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.email,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: state.isLoggedIn
                              ? context.statusOnline.withValues(alpha: 0.12)
                              : context.accentSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: state.isLoggedIn
                                    ? context.statusOnline
                                    : context.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.isLoggedIn
                                  ? 'Verified Member'
                                  : 'Guest Mode',
                              style: TextStyle(
                                color: state.isLoggedIn
                                    ? context.statusOnline
                                    : context.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (!state.isLoggedIn) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.accentSubtle,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: context.accent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: context.accent, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Unlock All Features',
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sign in to sync your messages and custom personas.',
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  minimumSize: const Size(64, 34),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pushNamed(loginRoute);
                                },
                                child: const Text('Sign In',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _SettingsSection(
                        items: [
                          _SettingsItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Display Name',
                            trailingText: state.displayName,
                            onTap: () => _showEditNameDialog(context),
                          ),
                          _SettingsItem(
                            icon: Icons.palette_outlined,
                            label: 'Theme Appearance',
                            trailingText: switch (state.themeMode) {
                              ThemeMode.light => 'Light',
                              ThemeMode.dark => 'Dark',
                              ThemeMode.system => 'System',
                            },
                            onTap: () => _showThemeDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SettingsSection(
                        items: [
                          _SettingsItem(
                            icon: Icons.description_outlined,
                            label: 'Terms of Service & EULA',
                            onTap: () => LegalDocs.showTerms(context),
                          ),
                          _SettingsItem(
                            icon: Icons.privacy_tip_outlined,
                            label: 'Privacy Policy',
                            onTap: () => LegalDocs.showPrivacy(context),
                          ),
                          _SettingsItem(
                            icon: Icons.feedback_outlined,
                            label: 'Send Feedback',
                            onTap: () => _showFeedbackDialog(context),
                          ),
                        ],
                      ),
                      if (state.isLoggedIn) ...[
                        const SizedBox(height: 12),
                        _SettingsSection(
                          items: [
                            _SettingsItem(
                              icon: Icons.logout_rounded,
                              label: 'Sign Out',
                              onTap: () => _confirmSignOut(context),
                            ),
                            _SettingsItem(
                              icon: Icons.delete_forever_rounded,
                              label: 'Delete Account',
                              isDestructive: true,
                              onTap: () => _confirmAccountDeletion(context),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 84,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final List<_SettingsItem> items;

  const _SettingsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 52,
                  color: context.borderSubtle,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.trailingText,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor =
        isDestructive ? context.statusDanger : context.textPrimary;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDestructive
                    ? context.statusDanger.withValues(alpha: 0.12)
                    : context.accentSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? context.statusDanger : context.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: itemColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: context.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
