/// Singleton state for the Book Shop — cart, purchases, filters.
/// Uses a simple listener pattern matching the existing BookRepository style.

import 'models/mock_book_shop_data.dart';
import '../../../../core/data/book_repository.dart';

typedef _VoidCb = void Function();

class BookShopState {
  // ── Singleton ─────────────────────────────────────────────
  BookShopState._();
  static final BookShopState instance = BookShopState._();

  // ── State ─────────────────────────────────────────────────
  final List<ShopBook> _cartItems = [];
  final Set<String> _purchasedBookIds = {};

  // ── Getters ───────────────────────────────────────────────
  List<ShopBook> get cartItems => List.unmodifiable(_cartItems);
  int get cartCount => _cartItems.length;
  bool get isCartEmpty => _cartItems.isEmpty;
  Set<String> get purchasedBookIds => Set.unmodifiable(_purchasedBookIds);

  double get cartSubtotal =>
      _cartItems.fold(0.0, (sum, b) => sum + b.effectivePrice);

  double get cartTotal => cartSubtotal; // No tax for mock

  // ── Cart operations ───────────────────────────────────────
  bool isInCart(String bookId) => _cartItems.any((b) => b.id == bookId);

  bool isPurchased(String bookId) => _purchasedBookIds.contains(bookId);

  void addToCart(ShopBook book) {
    if (isInCart(book.id) || isPurchased(book.id)) return;
    _cartItems.add(book);
    _notifyListeners();
  }

  void removeFromCart(String bookId) {
    _cartItems.removeWhere((b) => b.id == bookId);
    _notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _notifyListeners();
  }

  /// Purchase a single book (Buy Now)
  void purchaseBook(ShopBook book) {
    _purchasedBookIds.add(book.id);
    _cartItems.removeWhere((b) => b.id == book.id);
    BookRepository.addPurchasedBook(book);
    _notifyListeners();
  }

  /// Checkout all cart items
  void checkout() {
    for (final book in _cartItems) {
      _purchasedBookIds.add(book.id);
      BookRepository.addPurchasedBook(book);
    }
    _cartItems.clear();
    _notifyListeners();
  }

  // ── Listeners (same pattern as BookRepository) ────────────
  static final List<_VoidCb> _listeners = [];

  static void addListener(_VoidCb listener) => _listeners.add(listener);
  static void removeListener(_VoidCb listener) => _listeners.remove(listener);

  void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }
}
