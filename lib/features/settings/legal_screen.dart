import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('legal')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('terms_conditions'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).translate('terms_content'),
              style: const TextStyle(height: 1.5),
            ),
            const Divider(height: 32),
            Text(
              AppLocalizations.of(context).translate('licenses'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).translate('licenses_content'),
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
