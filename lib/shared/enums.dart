import 'package:flutter/material.dart';

// Enum for different post categories
enum PostCategory { adoption, fun, rescue, fundraise }

// Extension to provide details for each PostCategory
extension PostCategoryDetails on PostCategory {
  String get name {
    switch (this) {
      case PostCategory.adoption:
        return 'Adoption';
      case PostCategory.fun:
        return 'Fun';
      case PostCategory.rescue:
        return 'Rescue';
      case PostCategory.fundraise:
        return 'Fundraise';
    }
  }

  IconData get icon {
    switch (this) {
      case PostCategory.adoption:
        return Icons.pets;
      case PostCategory.fun:
        return Icons.celebration;
      case PostCategory.rescue:
        return Icons.emergency; // Changed from draft for clarity
      case PostCategory.fundraise:
        return Icons.volunteer_activism;
    }
  }

  Color get color {
    switch (this) {
      case PostCategory.adoption:
        return Colors.green.shade700;
      case PostCategory.fun:
        return Colors.blue.shade700;
      case PostCategory.rescue:
        return Colors.red.shade700; // Keep rescue red for emphasis
      case PostCategory.fundraise:
        return Colors.purple.shade700;
    }
  }
}
