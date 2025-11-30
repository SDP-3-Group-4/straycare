import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class PrivacySafetyScreen extends StatelessWidget {
  const PrivacySafetyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('privacy_safety')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('privacy_policy'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).translate('privacy_content'),
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
