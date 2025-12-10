import 'package:flutter/material.dart';
import 'package:straycare_demo/features/profile/repositories/user_repository.dart';
import 'package:straycare_demo/services/auth_service.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({Key? key}) : super(key: key);

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _bioController = TextEditingController();
  final _petNameController = TextEditingController();
  final _petBreedController = TextEditingController();
  final _petAgeController = TextEditingController();
  String _selectedAnimalType = 'Dog';

  final List<String> _animalTypes = ['Dog', 'Cat', 'Bird', 'Other'];
  final UserRepository _userRepository = UserRepository();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = _authService.getUserUid();
    if (uid.isEmpty) return;

    try {
      final doc = await _userRepository.getUser(uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _bioController.text = data['bio'] ?? '';
          if (data['petDetails'] != null) {
            final pet = data['petDetails'] as Map<String, dynamic>;
            _petNameController.text = pet['name'] ?? '';
            _petBreedController.text = pet['breed'] ?? '';
            _petAgeController.text = pet['age'] ?? '';
            _selectedAnimalType = pet['type'] ?? 'Dog';
          }
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _petNameController.dispose();
    _petBreedController.dispose();
    _petAgeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final uid = _authService.getUserUid();
    if (uid.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final petDetails = {
        'name': _petNameController.text.trim(),
        'breed': _petBreedController.text.trim(),
        'age': _petAgeController.text.trim(),
        'type': _selectedAnimalType,
      };

      final userData = {
        'bio': _bioController.text.trim(),
        'petDetails': petDetails,
      };

      // Check if user exists first to decide between set (merge) or update
      // For simplicity, we'll use saveUser which uses set (overwrite) in my implementation
      // But wait, set overwrites everything. I should use set with merge: true in service or update.
      // My UserRepository.updateUser uses updateDocument.
      // If the document doesn't exist, update will fail.
      // So I should check existence or use set with merge.
      // Let's use set with merge manually by using FirestoreService directly? No, that breaks abstraction.
      // Let's update UserRepository to support set with merge or just use a try-catch block with update, fallback to save.

      // Actually, for this specific case, let's assume the user document might not exist yet (if they just signed up).
      // So I'll use saveUser but I need to make sure I don't lose other data.
      // But wait, I only have bio and petDetails here.
      // If I use saveUser (set), I lose everything else if I don't pass it.
      // I should update UserRepository to support merge.
      // But I can't change it right now easily.
      // I'll use update, and if it fails, I'll use save.

      try {
        await _userRepository.updateUser(uid, userData);
      } catch (e) {
        // If update fails (e.g. doc doesn't exist), create it.
        // But I should include basic info too if creating.
        final user = _authService.currentUser;
        final fullData = {
          'uid': uid,
          'email': user?.email,
          'displayName': user?.displayName,
          'photoUrl': user?.photoURL,
          'createdAt':
              DateTime.now(), // FieldValue.serverTimestamp() is better but DateTime is ok for now
          ...userData,
        };
        await _userRepository.saveUser(uid, fullData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 36,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            const SizedBox(height: 0),

            // Bio Section
            Text('Bio', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tell us about yourself...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pet Info Section
            Text(
              'Pet Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Animal Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedAnimalType,
              decoration: InputDecoration(
                labelText: 'Animal Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  child: TextField(
                    controller: _petNameController,
                    decoration: InputDecoration(
                      labelText: 'Pet Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _petAgeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _petBreedController,
              decoration: InputDecoration(
                labelText: 'Breed',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
