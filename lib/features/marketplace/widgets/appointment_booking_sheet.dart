import 'package:flutter/material.dart';
import '../models/marketplace_category.dart';

class AppointmentBookingSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onBook;
  final MarketplaceCategory category;

  const AppointmentBookingSheet({
    Key? key,
    required this.onBook,
    required this.category,
  }) : super(key: key);

  @override
  State<AppointmentBookingSheet> createState() =>
      _AppointmentBookingSheetState();
}

class _AppointmentBookingSheetState extends State<AppointmentBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _petNameController = TextEditingController();
  final _petBreedController = TextEditingController();
  final _petAgeController = TextEditingController();
  final _petWeightController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedAnimalType = 'Dog';
  String _appointmentType = 'Physical';
  final List<String> _animalTypes = ['Dog', 'Cat', 'Bird', 'Other'];
  bool _showDateError = false;
  bool _showTimeError = false;

  @override
  void dispose() {
    _petNameController.dispose();
    _petBreedController.dispose();
    _petAgeController.dispose();
    _petWeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _showDateError = false;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _showTimeError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVet = widget.category == MarketplaceCategory.healthcare;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Book Appointment',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Appointment Type (Only for Vet)
              if (isVet) ...[
                DropdownButtonFormField<String>(
                  value: _appointmentType,
                  decoration: InputDecoration(
                    labelText: 'Appointment Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: ['Physical', 'Virtual'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _appointmentType = value);
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Date & Time Selection
              Text(
                'Date & Time',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _showDateError
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: _showDateError
                                      ? Colors.red
                                      : theme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedDate == null
                                        ? 'Select Date'
                                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: _showDateError ? Colors.red : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showDateError)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Text(
                              'Required',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => _selectTime(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _showTimeError
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: _showTimeError
                                      ? Colors.red
                                      : theme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedTime == null
                                        ? 'Select Time'
                                        : _selectedTime!.format(context),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: _showTimeError ? Colors.red : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showTimeError)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Text(
                              'Required',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Pet Information
              Text(
                'Pet Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedAnimalType,
                decoration: InputDecoration(
                  labelText: 'Animal Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: _animalTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedAnimalType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _petNameController,
                      decoration: InputDecoration(
                        labelText: 'Pet Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _petAgeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Req';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _petBreedController,
                      decoration: InputDecoration(
                        labelText: 'Breed',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _petWeightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notes
              Text(
                'Additional Notes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any specific concerns or requests...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showDateError = _selectedDate == null;
                      _showTimeError = _selectedTime == null;
                    });

                    if (_formKey.currentState!.validate() &&
                        !_showDateError &&
                        !_showTimeError) {
                      final bookingData = {
                        'date': _selectedDate,
                        'time': _selectedTime?.format(context),
                        'appointmentType': isVet
                            ? _appointmentType
                            : 'Physical',
                        'petType': _selectedAnimalType,
                        'petName': _petNameController.text,
                        'petAge': _petAgeController.text,
                        'petBreed': _petBreedController.text,
                        'petWeight': _petWeightController.text,
                        'notes': _notesController.text,
                      };
                      print('DEBUG: Closing sheet');
                      Navigator.pop(context);
                      print('DEBUG: Calling onBook');
                      widget.onBook(bookingData);
                      print('DEBUG: onBook called');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Confirm Booking',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
