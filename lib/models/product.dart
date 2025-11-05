// ============================================================================
// PRODUCT MODEL
// ============================================================================
// This file defines the Product data structure for the ecommerce app.
//
// This model represents a product as returned by the DummyJSON API.
// Understanding this structure is crucial for displaying products in your UI.
// ============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

// Part directives for code generation
// Remember to run: flutter pub run build_runner build --delete-conflicting-outputs
part 'product.freezed.dart';
part 'product.g.dart';

// ============================================================================
// PRODUCT CLASS
// ============================================================================

/// Represents a product in the ecommerce system
///
/// API Response example from DummyJSON:
/// ```json
/// {
///   "id": 1,
///   "title": "iPhone 15 Pro",
///   "description": "The latest iPhone with A17 Pro chip",
///   "category": "smartphones",
///   "price": 1099.99,
///   "discountPercentage": 10.5,
///   "rating": 4.5,
///   "stock": 50,
///   "tags": ["smartphones", "apple", "mobile"],
///   "brand": "Apple",
///   "sku": "IPHONE15PRO",
///   "weight": 7,
///   "dimensions": {
///     "width": 71.6,
///     "height": 146.7,
///     "depth": 8.25
///   },
///   "warrantyInformation": "1 year manufacturer warranty",
///   "shippingInformation": "Ships in 1-2 business days",
///   "availabilityStatus": "In Stock",
///   "reviews": [...],
///   "returnPolicy": "30 days return policy",
///   "minimumOrderQuantity": 1,
///   "meta": {...},
///   "images": [
///     "https://cdn.dummyjson.com/products/images/smartphones/iPhone-15-Pro/1.png"
///   ],
///   "thumbnail": "https://cdn.dummyjson.com/products/images/smartphones/iPhone-15-Pro/thumbnail.png"
/// }
/// ```
@freezed
class Product with _$Product {
  const factory Product({
    // ==========================================================================
    // CORE PRODUCT INFORMATION
    // ==========================================================================

    /// Unique product identifier
    /// This is set by the database and should never change
    /// Example: 1, 2, 3, ...
    required int id,

    /// Product name/title
    /// This is what users see first
    /// Example: "iPhone 15 Pro", "MacBook Pro 16-inch"
    required String title,

    /// Detailed product description
    /// Explains features, specifications, benefits
    /// Example: "The latest iPhone with A17 Pro chip, titanium design..."
    required String description,

    /// Product category
    /// Used for filtering and organization
    /// Example: "smartphones", "laptops", "beauty", "furniture"
    required String category,

    /// Product price in USD
    /// This is the current selling price
    /// Example: 1099.99, 549.00
    required double price,

    // ==========================================================================
    // PRICING & DISCOUNTS
    // ==========================================================================

    /// Discount percentage (if any)
    /// Used to show "X% off" badges
    /// Example: 10.5 means 10.5% discount
    ///
    /// CALCULATION:
    /// Original Price = price / (1 - discountPercentage / 100)
    /// Discount Amount = price * (discountPercentage / 100)
    double? discountPercentage,

    // ==========================================================================
    // RATINGS & REVIEWS
    // ==========================================================================

    /// Average rating (0-5 stars)
    /// Used to show star ratings in UI
    /// Example: 4.5 = ⭐⭐⭐⭐½
    double? rating,

    /// Total number of reviews
    /// Shows how many people rated this product
    /// Not directly in API response, but could be calculated from reviews array
    int? reviewCount,

    // ==========================================================================
    // INVENTORY & AVAILABILITY
    // ==========================================================================

    /// Current stock quantity
    /// Number of items available for purchase
    /// Example: 50 = 50 units in stock
    ///
    /// UI LOGIC:
    /// - stock == 0: Show "Out of Stock"
    /// - stock < 10: Show "Only X left!"
    /// - stock >= 10: Show "In Stock"
    required int stock,

    /// Product availability status
    /// Human-readable stock status
    /// Example: "In Stock", "Out of Stock", "Limited Stock"
    String? availabilityStatus,

    /// Minimum quantity that must be ordered
    /// Some products can't be bought individually
    /// Example: 1 = can buy single unit, 12 = must buy dozen
    int? minimumOrderQuantity,

    // ==========================================================================
    // PRODUCT DETAILS
    // ==========================================================================

    /// Product brand/manufacturer
    /// Example: "Apple", "Samsung", "Nike"
    String? brand,

    /// Stock Keeping Unit - unique product code
    /// Used for inventory management
    /// Example: "IPHONE15PRO", "MACBOOK16-2023"
    String? sku,

    /// Product weight in kilograms
    /// Important for shipping cost calculations
    /// Example: 7 = 7kg
    double? weight,

    /// Product dimensions
    /// Nested object with width, height, depth
    /// See ProductDimensions model below
    ProductDimensions? dimensions,

    /// Product tags for search and filtering
    /// Example: ["smartphones", "apple", "5g", "premium"]
    List<String>? tags,

    // ==========================================================================
    // WARRANTY & SHIPPING
    // ==========================================================================

    /// Warranty information
    /// Example: "1 year manufacturer warranty", "Limited lifetime warranty"
    String? warrantyInformation,

    /// Shipping details
    /// Example: "Ships in 1-2 business days", "Free shipping"
    String? shippingInformation,

    /// Return policy details
    /// Example: "30 days return policy", "Final sale - no returns"
    String? returnPolicy,

    // ==========================================================================
    // IMAGES
    // ==========================================================================

    /// Product thumbnail image URL
    /// Small image for list views (usually 200x200)
    /// Example: "https://cdn.dummyjson.com/products/images/.../thumbnail.png"
    String? thumbnail,

    /// Array of full-size product image URLs
    /// Multiple images for product gallery
    /// Example: ["url1.png", "url2.png", "url3.png"]
    @Default([]) List<String> images,

    // ==========================================================================
    // REVIEWS
    // ==========================================================================

    /// Array of product reviews
    /// See ProductReview model below
    /// Contains rating, comment, reviewer name, date
    @Default([]) List<ProductReview> reviews,

    // ==========================================================================
    // METADATA (OPTIONAL)
    // ==========================================================================

    /// Additional metadata (varies by product)
    /// Could include creation date, last updated, barcode, etc.
    /// Usually not displayed to users
    Map<String, dynamic>? meta,
  }) = _Product;

  /// Creates a Product from JSON
  ///
  /// EXAMPLE:
  /// ```dart
  /// final json = {'id': 1, 'title': 'iPhone', 'price': 999.0, ...};
  /// final product = Product.fromJson(json);
  /// ```
  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

// ============================================================================
// PRODUCT DIMENSIONS MODEL
// ============================================================================

/// Represents physical dimensions of a product
///
/// Used for shipping calculations and product details display
///
/// API Response example:
/// ```json
/// {
///   "width": 71.6,
///   "height": 146.7,
///   "depth": 8.25
/// }
/// ```
@freezed
class ProductDimensions with _$ProductDimensions {
  const factory ProductDimensions({
    /// Width in centimeters
    /// Example: 71.6 cm
    required double width,

    /// Height in centimeters
    /// Example: 146.7 cm
    required double height,

    /// Depth/thickness in centimeters
    /// Example: 8.25 cm
    required double depth,
  }) = _ProductDimensions;

  /// Creates ProductDimensions from JSON
  factory ProductDimensions.fromJson(Map<String, dynamic> json) =>
      _$ProductDimensionsFromJson(json);
}

// ============================================================================
// PRODUCT REVIEW MODEL
// ============================================================================

/// Represents a user review for a product
///
/// Used to display customer feedback and ratings
///
/// API Response example:
/// ```json
/// {
///   "rating": 5,
///   "comment": "Excellent product! Highly recommended.",
///   "date": "2024-01-15T08:30:00.000Z",
///   "reviewerName": "John Doe",
///   "reviewerEmail": "john.doe@example.com"
/// }
/// ```
@freezed
class ProductReview with _$ProductReview {
  const factory ProductReview({
    /// Review rating (0-5 stars)
    /// Example: 5 = ⭐⭐⭐⭐⭐
    required int rating,

    /// Review text/comment
    /// Customer's feedback about the product
    /// Example: "Excellent product! Highly recommended."
    required String comment,

    /// Date the review was submitted
    /// ISO 8601 format string
    /// Example: "2024-01-15T08:30:00.000Z"
    required String date,

    /// Name of the reviewer
    /// Example: "John Doe"
    required String reviewerName,

    /// Email of the reviewer
    /// Usually not displayed publicly
    /// Example: "john.doe@example.com"
    required String reviewerEmail,
  }) = _ProductReview;

  /// Creates ProductReview from JSON
  factory ProductReview.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewFromJson(json);
}

// ============================================================================
// PRODUCT LIST RESPONSE MODEL
// ============================================================================

/// Represents a paginated list of products from the API
///
/// The API doesn't just return an array - it returns metadata too!
/// This helps with pagination (loading more products as you scroll)
///
/// API Response example:
/// ```json
/// {
///   "products": [...],
///   "total": 194,
///   "skip": 0,
///   "limit": 10
/// }
/// ```
@freezed
class ProductListResponse with _$ProductListResponse {
  const factory ProductListResponse({
    /// Array of products
    /// This is the actual data you'll display
    required List<Product> products,

    /// Total number of products available
    /// Used to show "Showing 10 of 194 products"
    /// Also helps calculate total pages
    required int total,

    /// Number of products skipped (pagination offset)
    /// Example: skip=10 means start from the 11th product
    required int skip,

    /// Number of products returned in this request
    /// Example: limit=10 means return 10 products
    required int limit,
  }) = _ProductListResponse;

  /// Creates ProductListResponse from JSON
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// final json = {
  ///   'products': [
  ///     {'id': 1, 'title': 'iPhone', ...},
  ///     {'id': 2, 'title': 'iPad', ...},
  ///   ],
  ///   'total': 194,
  ///   'skip': 0,
  ///   'limit': 10,
  /// };
  /// final response = ProductListResponse.fromJson(json);
  /// print('Loaded ${response.products.length} of ${response.total} products');
  /// ```
  factory ProductListResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductListResponseFromJson(json);
}

// ============================================================================
// 📚 LEARNING NOTES
// ============================================================================
//
// KEY CONCEPTS:
//
// 1. NESTED MODELS:
//    Product contains other models (ProductDimensions, ProductReview)
//    This is common in APIs with complex data structures
//
//    Example:
//    ```dart
//    final product = Product(
//      id: 1,
//      title: 'iPhone',
//      dimensions: ProductDimensions(
//        width: 71.6,
//        height: 146.7,
//        depth: 8.25,
//      ),
//    );
//
//    // Access nested data
//    print(product.dimensions?.width); // 71.6
//    ```
//
// 2. LISTS IN MODELS:
//    Some fields are arrays (List<String>, List<ProductReview>)
//
//    @Default([]) provides an empty list if JSON doesn't include the field
//    This prevents null errors when iterating
//
//    Example:
//    ```dart
//    // Safe even if images is null in JSON
//    for (var image in product.images) {
//      print(image);
//    }
//    ```
//
// 3. NULLABLE vs REQUIRED:
//    - required fields: MUST be in JSON (will error if missing)
//    - nullable fields: Optional in JSON (will be null if missing)
//
//    Guidelines:
//    - Core data (id, title, price): required
//    - Optional details (brand, dimensions): nullable
//
// 4. DOUBLE vs INT:
//    - double: Numbers with decimals (price: 1099.99)
//    - int: Whole numbers (stock: 50)
//
//    Be careful! JSON might send "10" (int) when you expect 10.0 (double)
//    json_serializable handles this automatically
//
// 5. PAGINATION:
//    APIs don't return all products at once (too slow!)
//    Instead, they return chunks (pages)
//
//    Request: /products?limit=10&skip=0
//    Response: First 10 products
//
//    Request: /products?limit=10&skip=10
//    Response: Next 10 products (11-20)
//
//    FORMULA:
//    Page 1: skip=0, limit=10 (products 1-10)
//    Page 2: skip=10, limit=10 (products 11-20)
//    Page 3: skip=20, limit=10 (products 21-30)
//    skip = (page - 1) * limit
//
// 6. CALCULATED FIELDS:
//    Some data isn't in the API but can be calculated:
//
//    ```dart
//    extension ProductExtension on Product {
//      // Calculate original price before discount
//      double get originalPrice {
//        if (discountPercentage == null || discountPercentage == 0) {
//          return price;
//        }
//        return price / (1 - discountPercentage! / 100);
//      }
//
//      // Calculate savings amount
//      double get savings {
//        return originalPrice - price;
//      }
//
//      // Check if product is in stock
//      bool get isInStock {
//        return stock > 0;
//      }
//
//      // Check if stock is low
//      bool get isLowStock {
//        return stock > 0 && stock < 10;
//      }
//
//      // Check if product is on sale
//      bool get isOnSale {
//        return discountPercentage != null && discountPercentage! > 0;
//      }
//
//      // Get formatted price
//      String get formattedPrice {
//        return '\$${price.toStringAsFixed(2)}';
//      }
//
//      // Get average rating as stars
//      String get ratingStars {
//        if (rating == null) return '☆☆☆☆☆';
//        final fullStars = rating!.floor();
//        final hasHalfStar = (rating! - fullStars) >= 0.5;
//        return '⭐' * fullStars +
//               (hasHalfStar ? '½' : '') +
//               '☆' * (5 - fullStars - (hasHalfStar ? 1 : 0));
//      }
//    }
//    ```
//
// ============================================================================
// 🎯 UI USAGE EXAMPLES
// ============================================================================
//
// DISPLAY PRODUCT CARD:
// ```dart
// Widget buildProductCard(Product product) {
//   return Card(
//     child: Column(
//       children: [
//         // Product image
//         Image.network(product.thumbnail ?? ''),
//
//         // Product title
//         Text(product.title),
//
//         // Price and discount
//         Row(
//           children: [
//             Text('\$${product.price}'),
//             if (product.discountPercentage != null)
//               Text('${product.discountPercentage}% OFF'),
//           ],
//         ),
//
//         // Rating
//         Row(
//           children: [
//             Icon(Icons.star, color: Colors.amber),
//             Text('${product.rating ?? 0}'),
//           ],
//         ),
//
//         // Stock status
//         Text(
//           product.stock > 0 ? 'In Stock' : 'Out of Stock',
//           style: TextStyle(
//             color: product.stock > 0 ? Colors.green : Colors.red,
//           ),
//         ),
//       ],
//     ),
//   );
// }
// ```
//
// FILTER PRODUCTS BY CATEGORY:
// ```dart
// final smartphones = products.where((p) => p.category == 'smartphones').toList();
// ```
//
// SORT PRODUCTS BY PRICE:
// ```dart
// final sortedByPrice = [...products]..sort((a, b) => a.price.compareTo(b.price));
// ```
//
// SEARCH PRODUCTS:
// ```dart
// final searchResults = products.where((p) =>
//   p.title.toLowerCase().contains(query.toLowerCase()) ||
//   p.description.toLowerCase().contains(query.toLowerCase())
// ).toList();
// ```
//
// ============================================================================
// 🎯 YOUR TASK
// ============================================================================
//
// After running build_runner, you'll use this Product model to:
// 1. Display product lists in the home screen
// 2. Show product details
// 3. Implement search and filtering
// 4. Add products to cart
//
// CHALLENGE: Implement a product search feature using the search endpoint!
//
// ============================================================================
