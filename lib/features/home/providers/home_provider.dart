import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:straycare_demo/features/create_post/repositories/post_repository.dart';
import 'package:straycare_demo/features/profile/repositories/user_repository.dart';
import 'package:straycare_demo/services/auth_service.dart';
import '../../../shared/enums.dart';

class HomeProvider extends ChangeNotifier {
  final PostRepository _postRepository = PostRepository();
  final UserRepository _userRepository = UserRepository();
  final AuthService _authService = AuthService();

  List<DocumentSnapshot> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  static const int _limit = 10;
  String? _error;
  int _selectedCategoryIndex = 0;

  // Location state
  String _currentAddress = "Dhaka, Bangladesh";
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isLocationEnabled = false;

  // Saved posts state
  List<String> _savedPostIds = [];
  StreamSubscription? _savedPostsSubscription;

  List<DocumentSnapshot> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  int get selectedCategoryIndex => _selectedCategoryIndex;
  String get currentAddress => _currentAddress;
  bool get isLoadingLocation => _isLoadingLocation;
  List<String> get savedPostIds => _savedPostIds;

  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  HomeProvider() {
    _loadInitialPosts();
    _getCurrentLocation();
    _subscribeToSavedPosts();
    _monitorLocationService();
  }

  @override
  void dispose() {
    _savedPostsSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }

  void _monitorLocationService() {
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      status,
    ) {
      if (status == ServiceStatus.disabled && _selectedCategoryIndex == 1) {
        // Revert to Explore if location is turned off while on Near Me
        _selectedCategoryIndex = 0;
        _isLocationEnabled = false;
        refreshPosts();
        notifyListeners();
      }
    });
  }

  Future<void> checkLocationStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && _selectedCategoryIndex == 1) {
      _selectedCategoryIndex = 0;
      _isLocationEnabled = false;
      refreshPosts();
      notifyListeners();
    }
  }

  void _subscribeToSavedPosts() {
    final user = _authService.currentUser;
    if (user != null) {
      _savedPostsSubscription = _userRepository
          .getSavedPostIdsStream(user.uid)
          .listen((snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data() as Map<String, dynamic>;
              _savedPostIds = List<String>.from(data['savedPostIds'] ?? []);
              notifyListeners();
            }
          });
    }
  }

  Future<bool> setCategoryIndex(int index) async {
    if (_selectedCategoryIndex == index) return true;

    // Optimistically switch to give visual feedback ("resist" effect)
    int previousIndex = _selectedCategoryIndex;
    _selectedCategoryIndex = index;
    notifyListeners();

    // Enforce location for "Near Me" (index 1)
    if (index == 1) {
      if (!_isLocationEnabled) {
        // Try to get location again
        await _getCurrentLocation();
        if (!_isLocationEnabled) {
          // Still disabled, revert back
          _selectedCategoryIndex = previousIndex;
          notifyListeners();
          return false;
        }
      }
    }

    // If we're here, either it's not index 1, or location is enabled.
    // Just refresh posts.
    refreshPosts();
    return true;
  }

  Future<void> toggleLike(String postId) async {
    try {
      await _postRepository.toggleLike(postId);
      // No need to notifyListeners() as we rely on PostCard's local state + eventual refresh
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  Future<void> toggleSave(String postId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      if (_savedPostIds.contains(postId)) {
        await _userRepository.unsavePost(user.uid, postId);
        // _savedPostIds update is handled by the stream listener
      } else {
        await _userRepository.savePost(user.uid, postId);
        // _savedPostIds update is handled by the stream listener
      }
    } catch (e) {
      print("Error toggling save: $e");
    }
  }

  // Alias for HomeScreen
  Future<void> fetchPosts() => refreshPosts();
  Future<void> fetchMorePosts() => loadMorePosts();

  Future<void> _loadInitialPosts() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _postRepository.getPosts(limit: _limit);
      var fetchedPosts = snapshot.docs;

      if (_selectedCategoryIndex == 1) {
        if (_isLocationEnabled && _currentAddress != "Location Disabled") {
          final city = _currentAddress.split(',').first.trim();
          if (city.isNotEmpty) {
            fetchedPosts = fetchedPosts.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final location = data['location']?.toString() ?? '';
              return location.contains(city);
            }).toList();
          }
        } else {
          // Should not happen due to setCategoryIndex check, but safe guard
          fetchedPosts = [];
        }
      }

      _posts = fetchedPosts;

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _limit;
    } catch (e) {
      _error = e.toString();
      print("Error loading posts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _postRepository.getPosts(
        limit: _limit,
        lastDocument: _lastDocument,
      );

      var newPosts = snapshot.docs;

      if (_selectedCategoryIndex == 1) {
        if (_isLocationEnabled && _currentAddress != "Location Disabled") {
          final city = _currentAddress.split(',').first.trim();
          if (city.isNotEmpty) {
            newPosts = newPosts.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final location = data['location']?.toString() ?? '';
              return location.contains(city);
            }).toList();
          }
        } else {
          newPosts = [];
        }
      }

      if (newPosts.isNotEmpty) {
        _posts.addAll(newPosts);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _limit;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString();
      print("Error loading more posts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPosts() async {
    _lastDocument = null;
    _hasMore = true;
    _posts = [];
    await _loadInitialPosts();
  }

  Future<void> _getCurrentLocation() async {
    _isLoadingLocation = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentAddress = "Location Disabled";
        _isLocationEnabled = false;
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _currentAddress = "Permission Denied";
          _isLocationEnabled = false;
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _currentAddress = "Permission Denied Forever";
        _isLocationEnabled = false;
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = "${place.locality}, ${place.country}";
        _isLocationEnabled = true;
      }
    } catch (e) {
      print("Error getting location: $e");
      _currentAddress = "Dhaka, Bangladesh"; // Fallback
      _isLocationEnabled =
          false; // Assume failed means not enabled for filtering
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }
}
