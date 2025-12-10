import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class DonationProgress extends StatelessWidget {
  final double raised;
  final double goal;
  final int donors;
  final VoidCallback? onDonate;

  const DonationProgress({
    Key? key,
    required this.raised,
    required this.goal,
    this.onDonate,
    this.donors = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = (goal <= 0) ? 0.0 : (raised / goal).clamp(0.0, 1.0);
    final percentLabel = (percent * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '৳${raised.toStringAsFixed(2)} ${AppLocalizations.of(context).translate('raised')}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppLocalizations.of(context).translate('goal')}: ৳${goal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (onDonate != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: onDonate,
                child: Text(AppLocalizations.of(context).translate('donate')),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            return Stack(
              children: [
                // Background: Grey bar + Grey Text
                Container(
                  height: 26,
                  width: maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      '$percentLabel%',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Foreground: Primary bar + White Text (Clipped)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: percent == 0
                        ? 0.0001
                        : percent, // Avoid 0 width issues
                    child: Container(
                      width: maxWidth,
                      height: 26,
                      color: Theme.of(context).primaryColor,
                      child: Center(
                        child: Text(
                          '$percentLabel%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.flag, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text('৳${raised.toStringAsFixed(0)} / ৳${goal.toStringAsFixed(0)}'),
            const Spacer(),
            Icon(Icons.people, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text('$donors ${AppLocalizations.of(context).translate('donors')}'),
          ],
        ),
      ],
    );
  }
}
