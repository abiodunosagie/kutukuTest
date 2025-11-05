# 🎯 YOUR API INTEGRATION EXERCISES

Congratulations! You now have a complete, working example of API integration in Flutter. Now it's time to practice and solidify your learning by completing these exercises.

---

## 📋 TABLE OF CONTENTS

1. [Exercise 1: Implement Signup](#exercise-1-implement-signup)
2. [Exercise 2: Implement Product Search](#exercise-2-implement-product-search)
3. [Exercise 3: Add Product Details Screen](#exercise-3-add-product-details-screen)
4. [Exercise 4: Implement Category Filter](#exercise-4-implement-category-filter)
5. [Exercise 5: Add Shopping Cart](#exercise-5-add-shopping-cart)
6. [Bonus Challenges](#bonus-challenges)
7. [Testing Guide](#testing-guide)
8. [Solution Checklist](#solution-checklist)

---

## BEFORE YOU START

### 1. Run code generation for models:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Study these files first:
- ✅ `API_INTEGRATION_TUTORIAL.md` - The complete guide
- ✅ `lib/views/auth/login_screen_with_api.dart` - Complete login example
- ✅ `lib/providers/auth_provider.dart` - State management example
- ✅ `lib/services/auth_service.dart` - API service example

### 3. Test credentials for DummyJSON:
- **Username**: `emilys`
- **Password**: `emilyspass`

### 4. API Documentation:
https://dummyjson.com/docs

---

## EXERCISE 1: IMPLEMENT SIGNUP

### 🎯 Goal
Complete the signup functionality following the same pattern as login.

### 📝 What You Need to Do

#### Step 1: Complete the `signup` method in `AuthService`
**File**: `lib/services/auth_service.dart`

**Location**: Around line 200 (look for the TODO comment)

**What to implement**:
```dart
Future<User> signup({
  required String username,
  required String email,
  required String password,
  String? firstName,
  String? lastName,
}) async {
  // TODO: Implement signup following login pattern

  // HINTS:
  // 1. Use _apiClient.post()
  // 2. Endpoint: ApiConstants.register ('/users/add')
  // 3. Body should include: username, email, password, firstName, lastName
  // 4. Set includeAuth: false (not logged in yet!)
  // 5. DummyJSON doesn't return a token for signup, so don't save one
  // 6. Convert response to User with User.fromJson()
  // 7. Return the User object
}
```

**Expected API call**:
```
POST https://dummyjson.com/users/add
Body: {
  "username": "johndoe",
  "email": "john@example.com",
  "password": "john123",
  "firstName": "John",
  "lastName": "Doe"
}
```

#### Step 2: Add `signup` method to `AuthNotifier`
**File**: `lib/providers/auth_provider.dart`

**Where**: After the `login` method

**What to implement**:
```dart
Future<void> signup({
  required String username,
  required String email,
  required String password,
  String? firstName,
  String? lastName,
}) async {
  // TODO: Implement signup following login pattern

  // HINTS:
  // 1. Set state to loading
  // 2. Try to call _authService.signup(...)
  // 3. On success: Set state to data(user)
  // 4. On error: Set state to error(...)
  // 5. Use try-catch!
}
```

#### Step 3: Update Signup Screen
**File**: `lib/views/auth/signup.dart`

**What to do**:
1. Change `StatefulWidget` to `ConsumerStatefulWidget`
2. Change `State` to `ConsumerState`
3. Watch authStateProvider with `ref.watch`
4. Listen for side effects with `ref.listen`
5. Call signup on button press with `ref.read`
6. Show loading indicator when `authState.isLoading`
7. Navigate to login on success

**Template**:
```dart
// In the submit method
ref.read(authStateProvider.notifier).signup(
  username: _usernameController.text,
  email: _emailController.text,
  password: _passwordController.text,
  firstName: _firstNameController.text,
  lastName: _lastNameController.text,
);

// In build method
final authState = ref.watch(authStateProvider);

ref.listen<AsyncValue>(authStateProvider, (previous, next) {
  next.when(
    data: (user) {
      if (user != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created! Please login.')),
        );
        // Navigate to login
        context.goNamed(AppRouter.login);
      }
    },
    error: (error, stack) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $error')),
      );
    },
    loading: () {},
  );
});
```

### ✅ Success Criteria
- [ ] User can create account with valid data
- [ ] Loading indicator shows during signup
- [ ] Success message shows after signup
- [ ] Navigates to login screen on success
- [ ] Error message shows on failure
- [ ] Form validation works correctly

### 🧪 Test Cases
```dart
// Test 1: Successful signup
Username: "testuser"
Email: "test@example.com"
Password: "test123"
Expected: Success, navigate to login

// Test 2: Empty fields
Username: ""
Email: ""
Password: ""
Expected: Validation errors shown

// Test 3: Invalid email
Email: "notanemail"
Expected: "Enter a valid email" error

// Test 4: Short password
Password: "123"
Expected: "Password must be at least 8 characters" error
```

---

## EXERCISE 2: IMPLEMENT PRODUCT SEARCH

### 🎯 Goal
Implement product search functionality.

### 📝 What You Need to Do

#### Step 1: Complete `searchProducts` in `ProductService`
**File**: `lib/services/product_service.dart`

**Location**: Around line 250 (look for the TODO comment)

**What to implement**:
```dart
Future<ProductListResponse> searchProducts(
  String query, {
  int limit = ApiConstants.defaultLimit,
  int skip = ApiConstants.defaultSkip,
}) async {
  // TODO: Implement search following getAllProducts pattern

  // HINTS:
  // 1. Use _apiClient.get()
  // 2. Endpoint: ApiConstants.productSearch ('/products/search')
  // 3. Query parameters: 'q' (the search term), 'limit', 'skip'
  // 4. Convert response to ProductListResponse.fromJson()
  // 5. Return the result
}
```

**Expected API call**:
```
GET https://dummyjson.com/products/search?q=phone&limit=10&skip=0
```

#### Step 2: Add Search Provider
**File**: `lib/providers/product_provider.dart`

**Where**: After the existing providers

**What to add**:
```dart
// Search query state provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search results provider
final searchResultsProvider = FutureProvider<ProductListResponse>((ref) async {
  final productService = ref.watch(productServiceProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    // Return empty results if no query
    return const ProductListResponse(
      products: [],
      total: 0,
      skip: 0,
      limit: 0,
    );
  }

  return await productService.searchProducts(query);
});
```

#### Step 3: Create Search Screen
**File**: Create `lib/views/search_screen.dart`

**What to implement**:
```dart
class SearchScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products...',
          ),
          onChanged: (value) {
            // Update search query
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
      ),
      body: searchResults.when(
        loading: () => CircularProgressIndicator(),
        data: (response) {
          if (response.products.isEmpty) {
            return Center(child: Text('No products found'));
          }

          return ListView.builder(
            itemCount: response.products.length,
            itemBuilder: (context, index) {
              final product = response.products[index];
              return ListTile(
                leading: Image.network(product.thumbnail ?? ''),
                title: Text(product.title),
                subtitle: Text('\$${product.price}'),
              );
            },
          );
        },
        error: (error, stack) => Text('Error: $error'),
      ),
    );
  }
}
```

### ✅ Success Criteria
- [ ] User can type search query
- [ ] Results update as user types
- [ ] Loading indicator shows during search
- [ ] Products are displayed correctly
- [ ] No results message shows when appropriate
- [ ] Clicking product navigates to details

### 🧪 Test Cases
```dart
// Test 1: Search for phones
Query: "phone"
Expected: Shows all phone products

// Test 2: Search for non-existent product
Query: "xyz123"
Expected: "No products found" message

// Test 3: Empty search
Query: ""
Expected: Empty state or all products

// Test 4: Special characters
Query: "laptop 15\""
Expected: Handles special characters correctly
```

---

## EXERCISE 3: ADD PRODUCT DETAILS SCREEN

### 🎯 Goal
Create a product details screen that fetches and displays a single product.

### 📝 What You Need to Do

#### Step 1: Create Product Details Screen
**File**: Create `lib/views/product_details_screen.dart`

**What to implement**:
```dart
class ProductDetailsScreen extends ConsumerWidget {
  final int productId;

  const ProductDetailsScreen({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the productProvider (already created in product_provider.dart)
    final productState = ref.watch(productProvider(productId));

    return Scaffold(
      appBar: AppBar(title: Text('Product Details')),
      body: productState.when(
        loading: () => Center(child: CircularProgressIndicator()),
        data: (product) {
          // TODO: Build product details UI
          return SingleChildScrollView(
            child: Column(
              children: [
                // Product images carousel
                // Product title
                // Product price
                // Discount badge (if any)
                // Rating stars
                // Stock status
                // Description
                // Add to cart button
                // Product reviews
              ],
            ),
          );
        },
        error: (error, stack) => Center(
          child: Text('Error loading product: $error'),
        ),
      ),
    );
  }
}
```

#### Step 2: Add Route
**File**: `lib/router/app_router.dart`

**Add route**:
```dart
GoRoute(
  path: '/product/:id',
  name: 'productDetails',
  builder: (context, state) {
    final id = int.parse(state.pathParameters['id']!);
    return ProductDetailsScreen(productId: id);
  },
),
```

#### Step 3: Navigate from Product List
**When user taps a product**:
```dart
onTap: () {
  context.goNamed('productDetails', pathParameters: {
    'id': product.id.toString(),
  });
}
```

### ✅ Success Criteria
- [ ] Product details load correctly
- [ ] All product information displayed
- [ ] Images display correctly
- [ ] Rating shown with stars
- [ ] Stock status displayed
- [ ] Loading and error states handled

### 🧪 Test Cases
```dart
// Test 1: Valid product ID
ID: 1
Expected: Product details shown

// Test 2: Invalid product ID
ID: 999999
Expected: Error message shown

// Test 3: Navigation
Expected: Back button works, can navigate back to list
```

---

## EXERCISE 4: IMPLEMENT CATEGORY FILTER

### 🎯 Goal
Allow users to filter products by category.

### 📝 What You Need to Do

#### Step 1: Fetch and Display Categories
**File**: Update your home screen or create a categories widget

**Use the categoriesProvider**:
```dart
final categoriesState = ref.watch(categoriesProvider);

categoriesState.when(
  loading: () => CircularProgressIndicator(),
  data: (categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return CategoryChip(
            category: category,
            isSelected: selectedCategory == category,
            onTap: () {
              // Update selected category
              setState(() => selectedCategory = category);
            },
          );
        }).toList(),
      ),
    );
  },
  error: (error, stack) => Text('Error loading categories'),
);
```

#### Step 2: Show Products for Selected Category
**Use productsByCategoryProvider**:
```dart
final selectedCategory = ref.watch(selectedCategoryProvider);

if (selectedCategory == null) {
  // Show all products
  final productsState = ref.watch(productListProvider);
  // ... display products
} else {
  // Show products in category
  final productsState = ref.watch(
    productsByCategoryProvider(selectedCategory),
  );
  // ... display products
}
```

#### Step 3: Add "All Categories" Option
**Allow users to clear filter**:
```dart
CategoryChip(
  category: 'All',
  isSelected: selectedCategory == null,
  onTap: () {
    setState(() => selectedCategory = null);
  },
)
```

### ✅ Success Criteria
- [ ] Categories load and display
- [ ] Can select a category
- [ ] Products filter by category
- [ ] Can clear filter (show all)
- [ ] Visual indication of selected category

---

## EXERCISE 5: ADD SHOPPING CART

### 🎯 Goal
Implement shopping cart functionality.

### 📝 What You Need to Do

This is a more advanced exercise! You'll need to:

#### Step 1: Create Cart Model
**File**: Create `lib/models/cart.dart`

```dart
@freezed
class Cart with _$Cart {
  const factory Cart({
    required int id,
    required List<CartProduct> products,
    required double total,
    required int totalProducts,
    required int totalQuantity,
  }) = _Cart;

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
}

@freezed
class CartProduct with _$CartProduct {
  const factory CartProduct({
    required int id,
    required String title,
    required double price,
    required int quantity,
    required double total,
    String? thumbnail,
  }) = _CartProduct;

  factory CartProduct.fromJson(Map<String, dynamic> json) =>
      _$CartProductFromJson(json);
}
```

#### Step 2: Create Cart Service
**File**: Create `lib/services/cart_service.dart`

```dart
class CartService {
  final ApiClient _apiClient;

  CartService(this._apiClient);

  Future<Cart> getUserCart(int userId) async {
    // TODO: Implement
    // GET /carts/user/{userId}
  }

  Future<Cart> addToCart({
    required int userId,
    required List<Map<String, dynamic>> products,
  }) async {
    // TODO: Implement
    // POST /carts/add
    // Body: { "userId": 1, "products": [{"id": 1, "quantity": 1}] }
  }
}
```

#### Step 3: Create Cart Provider
**File**: Create `lib/providers/cart_provider.dart`

```dart
final cartServiceProvider = Provider<CartService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CartService(apiClient);
});

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<Cart?>>((ref) {
  final cartService = ref.watch(cartServiceProvider);
  return CartNotifier(cartService);
});

class CartNotifier extends StateNotifier<AsyncValue<Cart?>> {
  final CartService _cartService;

  CartNotifier(this._cartService) : super(const AsyncValue.data(null));

  Future<void> loadCart(int userId) async {
    // TODO: Implement
  }

  Future<void> addProduct(int userId, int productId, int quantity) async {
    // TODO: Implement
  }
}
```

#### Step 4: Add "Add to Cart" Button
**In ProductDetailsScreen**:
```dart
ElevatedButton(
  onPressed: () {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref.read(cartProvider.notifier).addProduct(
        user.id,
        product.id,
        1,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to cart!')),
      );
    } else {
      // Navigate to login
      context.goNamed(AppRouter.login);
    }
  },
  child: Text('Add to Cart'),
)
```

#### Step 5: Create Cart Screen
**File**: Create `lib/views/cart_screen.dart`

Display cart items, quantities, and total.

### ✅ Success Criteria
- [ ] Can add products to cart
- [ ] Cart persists across screens
- [ ] Can view cart contents
- [ ] Can update quantities
- [ ] Total price calculated correctly
- [ ] Must be logged in to use cart

---

## BONUS CHALLENGES

### 🚀 Challenge 1: Pull to Refresh
Add pull-to-refresh functionality to product list.

**Hint**:
```dart
RefreshIndicator(
  onRefresh: () async {
    await ref.read(productListProvider.notifier).refresh();
  },
  child: ProductList(),
)
```

### 🚀 Challenge 2: Infinite Scroll
Implement infinite scrolling for products.

**Hint**: Already implemented in ProductNotifier! Just use `loadMore()` when user scrolls to bottom.

### 🚀 Challenge 3: Favorites/Wishlist
Allow users to save favorite products locally.

**Hint**: Use shared_preferences or local storage.

### 🚀 Challenge 4: Sorting
Add sort options (price low-high, rating, name).

**Hint**: Sort the product list in the provider.

### 🚀 Challenge 5: Offline Mode
Cache products for offline viewing.

**Hint**: Use sqflite or hive for local database.

---

## TESTING GUIDE

### How to Test Your Implementation

#### 1. Testing Login
```bash
# Terminal window 1: Run app
flutter run

# Try these credentials:
Username: emilys
Password: emilyspass

# Expected: Login successful, navigate to home
```

#### 2. Testing API Calls
Add print statements in services:
```dart
print('API Request: ${response.request}');
print('API Response: ${response.body}');
```

#### 3. Testing Error Handling
```dart
// Test with wrong credentials
Username: wronguser
Password: wrongpass

// Expected: Error snackbar shown

// Test with no internet
// Turn off WiFi and mobile data
// Expected: "No internet connection" error
```

#### 4. Testing State Management
Add print statements in providers:
```dart
print('State changed: $state');
```

---

## SOLUTION CHECKLIST

Before you consider an exercise complete, check:

- [ ] Code compiles without errors
- [ ] No warnings in console
- [ ] Loading states shown correctly
- [ ] Error states handled gracefully
- [ ] Success states navigate/update correctly
- [ ] All form fields validated
- [ ] Comments added explaining complex logic
- [ ] Code follows existing patterns
- [ ] Tested with valid data
- [ ] Tested with invalid data
- [ ] Tested with no internet
- [ ] User experience is smooth

---

## DEBUGGING TIPS

### Common Issues

#### Issue: "No ProviderScope found"
**Solution**: Make sure `main.dart` wraps `App` with `ProviderScope`.

#### Issue: "Cannot use 'ref' outside Consumer"
**Solution**: Change `StatefulWidget` to `ConsumerStatefulWidget`.

#### Issue: API returns 404
**Solution**: Check endpoint URL is correct. Print the full URL.

#### Issue: JSON parsing error
**Solution**: Run `flutter pub run build_runner build --delete-conflicting-outputs`.

#### Issue: State doesn't update
**Solution**: Make sure you're using `state = newValue` not `state.value = newValue`.

#### Issue: Widget rebuilds infinitely
**Solution**: Use `ref.read` in callbacks, `ref.watch` only in build.

---

## NEED HELP?

### Resources

1. **Tutorial Document**: `API_INTEGRATION_TUTORIAL.md`
2. **Login Example**: `lib/views/auth/login_screen_with_api.dart`
3. **Riverpod Docs**: https://riverpod.dev
4. **DummyJSON Docs**: https://dummyjson.com/docs
5. **Flutter Docs**: https://flutter.dev/docs

### Where to Look

**For API questions**: Check `lib/services/`
**For state questions**: Check `lib/providers/`
**For UI questions**: Check `lib/views/auth/login_screen_with_api.dart`
**For model questions**: Check `lib/models/`

---

## FINAL WORDS

Remember:
- **Learn by doing** - Type the code yourself, don't just copy-paste
- **Experiment** - Try different approaches, break things, fix them
- **Read error messages** - They usually tell you exactly what's wrong
- **Take breaks** - If stuck, step away and come back fresh
- **Ask for help** - It's okay to not know everything!

You've got this! 🚀

Good luck with your exercises! 💪
