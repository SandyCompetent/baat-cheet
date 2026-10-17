import 'package:flutter/material.dart';
import '../../theme_data.dart';

/// In-app legal documentation satisfying Apple & Google Play UGC & privacy requirements.
class LegalDocs {
  static const String appName = 'ChatBud';

  static const String termsOfService = '''
# End User License Agreement (EULA) & Terms of Service

Last Updated: October 2026

By accessing or using $appName, you agree to be bound by these Terms of Service. If you disagree with any part of the terms, you may not access the service.

## 1. Zero Tolerance for Objectionable Content
$appName enforces a zero-tolerance policy for objectionable content and abusive users. You agree NOT to post, transmit, or share any content that:
- Is unlawful, harassing, defamatory, abusive, threatening, harmful, vulgar, obscene, or racially/ethnically hateful.
- Promotes violence, illegal acts, discrimination, or self-harm.
- Infringes upon intellectual property rights, trademarks, or copyrights.
- Constitutes spam, unsolicited advertising, phishing, or malware.

## 2. User Moderation, Reporting & Blocking
- Users have the ability to immediately block any user whose conduct is deemed unwelcome.
- Users can report objectionable messages directly through the in-app reporting mechanism (long-press on any message -> "Report Content").
- Our moderation team reviews all reported content within 24 hours. Content violating our terms will be removed promptly, and offending accounts will be suspended or permanently banned.

## 3. Account Deletion
You may delete your account and associated personal data at any time via Profile -> Settings -> Delete Account. Once confirmed, your profile and credentials are permanently purged.

## 4. Limitation of Liability
$appName is provided "as is" without warranty of any kind. Under no circumstances shall the operators be liable for indirect, incidental, or consequential damages.
''';

  static const String privacyPolicy = '''
# Privacy Policy

Last Updated: October 2026

Your privacy is paramount. This Privacy Policy explains how $appName collects, uses, and protects your information.

## 1. Information We Collect
- **Account Information**: When registering via Firebase Authentication, we collect your email address and chosen display name.
- **Messages & Content**: Messages sent in conversations and group channels are stored securely in Cloud Firestore to enable synchronization across your devices.
- **Diagnostics**: Anonymous performance and crash analytics to maintain application stability.

## 2. Information We Do NOT Collect
- We do not access your device microphone, camera, photos, or physical location.
- We do not sell your personal data or message contents to third parties.

## 3. Data Storage & Security
All authentication and database interactions are transmitted over TLS/SSL encryption and stored on Google Cloud / Firebase infrastructure with strict security rules.

## 4. Your Rights & Data Deletion
Under GDPR and CCPA guidelines, you have the right to access, rectify, or delete your personal data. You can exercise complete account deletion at any time in the app settings.

## 5. Contact Us
For privacy inquiries or urgent moderation requests, contact: support@chatbud.app
''';

  static void showTerms(BuildContext context) {
    _showLegalSheet(context, 'Terms of Service & EULA', termsOfService);
  }

  static void showPrivacy(BuildContext context) {
    _showLegalSheet(context, 'Privacy Policy', privacyPolicy);
  }

  static void _showLegalSheet(
    BuildContext context,
    String title,
    String content,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: context.borderSubtle)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: context.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: context.borderSubtle),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      SelectableText(
                        content,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
