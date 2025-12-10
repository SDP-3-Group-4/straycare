import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final Color baseColor;

  const VerifiedBadge({Key? key, this.size = 16, this.baseColor = Colors.blue})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Icon(Icons.verified, color: baseColor, size: size),
    );
  }
}
