import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'privacy_safety_screen.dart';
import 'legal_screen.dart';
import 'widgets/about_dialog.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('settings_title')),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(
            context,
            AppLocalizations.of(context).translate('settings_general'),
          ),
          _buildListTile(
            context,
            icon: Icons.brightness_6_outlined,
            title: Text(
              AppLocalizations.of(context).translate('system_appearance'),
            ),
            subtitle: _getThemeModeName(context),
            onTap: () => _showThemePicker(context),
          ),
          _buildListTile(
            context,
            icon: Icons.accessibility_new_outlined,
            title: Text(
              AppLocalizations.of(context).translate('accessibility'),
            ),
            subtitle: AppLocalizations.of(context).translate('coming_soon'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    ).translate('accessibility_coming_soon'),
                  ),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.language_outlined,
            title: Row(
              children: [
                Text(AppLocalizations.of(context).translate('language')),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple, width: 0.5),
                  ),
                  child: const Text(
                    'BETA',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: _getLanguageName(context),
            onTap: () => _showLanguagePicker(context),
          ),
          const Divider(),
          _buildSectionHeader(
            context,
            AppLocalizations.of(context).translate('settings_support'),
          ),
          _buildListTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: Text(
              AppLocalizations.of(context).translate('privacy_safety'),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySafetyScreen(),
                ),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.gavel_outlined,
            title: Text(AppLocalizations.of(context).translate('legal')),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LegalScreen()),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.info_outline,
            title: Text(AppLocalizations.of(context).translate('about')),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const CustomAboutDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required Widget title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: title,
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  String _getThemeModeName(BuildContext context) {
    final mode = context.watch<SettingsProvider>().themeMode;
    switch (mode) {
      case ThemeMode.system:
        return AppLocalizations.of(context).translate('system_default');
      case ThemeMode.light:
        return AppLocalizations.of(context).translate('day_mode');
      case ThemeMode.dark:
        return AppLocalizations.of(context).translate('night_mode');
    }
  }

  String _getLanguageName(BuildContext context) {
    final locale = context.watch<SettingsProvider>().locale;
    switch (locale.languageCode) {
      case 'bn':
        return AppLocalizations.of(context).translate('bangla');
      case 'es':
        return AppLocalizations.of(context).translate('spanish');
      case 'fr':
        return AppLocalizations.of(context).translate('french');
      case 'en':
      default:
        return AppLocalizations.of(context).translate('english');
    }
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).translate('choose_appearance'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildRadioTile(
                  context,
                  title: AppLocalizations.of(
                    context,
                  ).translate('system_default'),
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (val) => settings.setThemeMode(val!),
                ),
                _buildRadioTile(
                  context,
                  title: AppLocalizations.of(context).translate('day_mode'),
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (val) => settings.setThemeMode(val!),
                ),
                _buildRadioTile(
                  context,
                  title: AppLocalizations.of(context).translate('night_mode'),
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (val) => settings.setThemeMode(val!),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).translate('choose_language'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildLanguageRadioTile(
                  context,
                  title: AppLocalizations.of(context).translate('english'),
                  value: 'en',
                  groupValue: settings.locale.languageCode,
                  onChanged: (val) => settings.setLocale(Locale(val!)),
                ),
                _buildLanguageRadioTile(
                  context,
                  title: AppLocalizations.of(context).translate('bangla'),
                  value: 'bn',
                  groupValue: settings.locale.languageCode,
                  onChanged: (val) => settings.setLocale(Locale(val!)),
                ),
                _buildLanguageRadioTile(
                  context,
                  title: AppLocalizations.of(context).translate('spanish'),
                  value: 'es',
                  groupValue: settings.locale.languageCode,
                  onChanged: (val) => settings.setLocale(Locale(val!)),
                ),
                _buildLanguageRadioTile(
                  context,
                  title: AppLocalizations.of(context).translate('french'),
                  value: 'fr',
                  groupValue: settings.locale.languageCode,
                  onChanged: (val) => settings.setLocale(Locale(val!)),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRadioTile<T>(
    BuildContext context, {
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return RadioListTile<T>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: (val) {
        onChanged(val);
        Navigator.pop(context);
      },
      activeColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildLanguageRadioTile(
    BuildContext context, {
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: (val) {
        onChanged(val);
        Navigator.pop(context);
      },
      activeColor: Theme.of(context).primaryColor,
    );
  }
}
