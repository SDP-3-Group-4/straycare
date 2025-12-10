import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:straycare_demo/features/marketplace/repositories/marketplace_repository.dart';

class MarketplaceProvider extends ChangeNotifier {
  final MarketplaceRepository _marketplaceRepository = MarketplaceRepository();

  List<DocumentSnapshot> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  static const int _limit = 10;
  String _selectedCategory = 'All';

  List<DocumentSnapshot> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get selectedCategory => _selectedCategory;

  MarketplaceProvider() {
    _loadInitialItems();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    refreshItems();
  }

  Future<void> _loadInitialItems() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Note: Repository needs update to support category filtering with pagination if we want strict server-side filtering
      // For now, we fetch all and filter client side or just fetch all sorted by date
      // If category is specific, we should use a specific query.
      // Let's assume getItems supports basic pagination for now.

      final snapshot = await _marketplaceRepository.getItems(limit: _limit);
      _items = snapshot.docs;
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _limit;
    } catch (e) {
      print("Error loading items: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreItems() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _marketplaceRepository.getItems(
        limit: _limit,
        lastDocument: _lastDocument,
      );

      if (snapshot.docs.isNotEmpty) {
        _items.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _limit;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print("Error loading more items: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshItems() async {
    _lastDocument = null;
    _hasMore = true;
    _items = [];
    await _loadInitialItems();
  }
}
