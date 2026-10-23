import 'package:chatbud/route_generator.dart';
import 'package:chatbud/src/auth/auth_service.dart';
import 'package:chatbud/src/core/app_state.dart';
import 'package:chatbud/src/core/avatar_helper.dart';
import 'package:chatbud/src/services/chat_service.dart';
import 'package:chatbud/src/services/gemini_service.dart';
import 'package:chatbud/src/services/public_api_rag_service.dart';
import 'package:chatbud/src/widgets/legal_dialog.dart';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _publicApiKeyCtrl;
  bool _obscureApiKey = true;
  bool _obscurePublicApiKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl = TextEditingController(text: GeminiService.instance.apiKey);
    _publicApiKeyCtrl =
        TextEditingController(text: PublicApiRagService.instance.apiKey);
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _publicApiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $urlString')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $urlString')),
        );
      }
    }
  }

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
                final currentUid = AuthService.currentUser?.uid ?? 'anonymous';
                await ChatService.instance.reportContent(
                  reportedUserId: 'system',
                  messageId:
                      'feedback_${DateTime.now().millisecondsSinceEpoch}',
                  reason: 'User Feedback',
                  messageText: text,
                  reporterId: currentUid,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Thank you! Your feedback has been received and saved.'),
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
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
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

  Widget _buildAiConfigCard(BuildContext context, GeminiService gemini) {
    final models = gemini.availableModels;
    final selectedModel = models.contains(gemini.currentModel)
        ? gemini.currentModel
        : models.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.accentSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: context.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Configuration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gemini.hasCustomApiKey
                      ? context.accentSubtle
                      : context.statusOnline.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  gemini.hasCustomApiKey
                      ? 'Custom Key (BYOK)'
                      : 'Live Default (Firebase AI)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: gemini.hasCustomApiKey
                        ? context.accent
                        : context.statusOnline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ChatBud works live out-of-the-box. Optionally enter your own Gemini API key to use custom quotas and fetch all available Gemini models.',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: _obscureApiKey,
            style: TextStyle(color: context.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Gemini API Key',
              hintText: 'AIzaSy... (Leave empty for live default)',
              prefixIcon: Icon(Icons.key_rounded, color: context.accent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: _obscureApiKey ? 'Show API Key' : 'Hide API Key',
                    icon: Icon(
                      _obscureApiKey
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: context.textMuted,
                    ),
                    onPressed: () {
                      setState(() => _obscureApiKey = !_obscureApiKey);
                    },
                  ),
                  if (gemini.hasCustomApiKey)
                    IconButton(
                      tooltip: 'Clear API Key (Revert to Default)',
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: context.textMuted,
                      ),
                      onPressed: () {
                        _apiKeyCtrl.clear();
                        gemini.setApiKey('');
                      },
                    ),
                ],
              ),
            ),
            onChanged: (val) => gemini.setApiKey(val),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: gemini.isLoadingModels
                  ? null
                  : () => gemini.fetchAvailableModels(),
              icon: gemini.isLoadingModels
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.cloud_download_outlined, size: 18),
              label: const Text('Fetch Available Models'),
            ),
          ),
          if (gemini.modelError != null) ...[
            const SizedBox(height: 8),
            Text(
              gemini.modelError!,
              style: TextStyle(
                color: context.statusDanger,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Select Model',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedModel,
            isExpanded: true,
            dropdownColor: context.bgSurface,
            style: TextStyle(color: context.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.smart_toy_outlined, color: context.accent),
            ),
            items: models.map((model) {
              return DropdownMenuItem<String>(
                value: model,
                child: Text(model, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                gemini.setModel(val);
              }
            },
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.hub_rounded, color: context.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Public APIs / APILayer Key (Grounded RAG)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PublicApiRagService.instance.hasCustomApiKey
                      ? context.accentSubtle
                      : context.statusOnline.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  PublicApiRagService.instance.hasCustomApiKey
                      ? 'APILayer Key Active'
                      : 'Zero-Auth Active',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: PublicApiRagService.instance.hasCustomApiKey
                        ? context.accent
                        : context.statusOnline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Grounded RAG agents work out-of-the-box with zero-auth public APIs (OpenAlex, OSV, EndOfLife, Open-Meteo). Paste your APILayer key here to authenticate APILayer endpoints.',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _publicApiKeyCtrl,
            obscureText: _obscurePublicApiKey,
            style: TextStyle(color: context.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'APILayer / Public API Key',
              hintText: 'Enter APILayer key (optional)...',
              prefixIcon: Icon(Icons.vpn_key_outlined, color: context.accent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: _obscurePublicApiKey
                        ? 'Show APILayer Key'
                        : 'Hide APILayer Key',
                    icon: Icon(
                      _obscurePublicApiKey
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: context.textMuted,
                    ),
                    onPressed: () {
                      setState(
                          () => _obscurePublicApiKey = !_obscurePublicApiKey);
                    },
                  ),
                  if (PublicApiRagService.instance.hasCustomApiKey)
                    IconButton(
                      tooltip: 'Clear APILayer Key',
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: context.textMuted,
                      ),
                      onPressed: () {
                        _publicApiKeyCtrl.clear();
                        PublicApiRagService.instance.setApiKey('');
                      },
                    ),
                ],
              ),
            ),
            onChanged: (val) => PublicApiRagService.instance.setApiKey(val),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutAndDownloadsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About & Downloads',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.accentSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_pin_rounded,
                color: context.accent,
                size: 22,
              ),
            ),
            title: Text(
              'Developed by Sandeep Malviya',
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              'Software Engineer & AI Enthusiast',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _launchExternalUrl(
                  'https://www.linkedin.com/in/sandy-competent/',
                ),
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('LinkedIn'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _launchExternalUrl(
                  'https://github.com/SandyCompetent',
                ),
                icon: const Icon(Icons.code_rounded, size: 18),
                label: const Text('GitHub'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.accentSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.accent.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.android_rounded, size: 36, color: context.accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download Android APK',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Get the latest mobile version directly to your device.',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _launchExternalUrl(
                    'https://github.com/SandyCompetent/chatbud/releases/latest/download/app-debug.apk',
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('APK'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppState.instance,
        GeminiService.instance,
        PublicApiRagService.instance,
      ]),
      builder: (context, _) {
        final state = AppState.instance;
        final gemini = GeminiService.instance;

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
                              state.displayName.isNotEmpty &&
                                      state.displayName != 'Guest User'
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
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
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
                      const SizedBox(height: 12),
                      _buildAiConfigCard(context, gemini),
                      const SizedBox(height: 12),
                      _buildAboutAndDownloadsCard(context),
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
